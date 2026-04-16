import test from 'node:test';
import assert from 'node:assert/strict';
import { mkdtempSync, mkdirSync, writeFileSync, rmSync } from 'node:fs';
import { join } from 'node:path';
import { tmpdir } from 'node:os';

import { collectSubSkills } from '../lib/skill-index.mjs';

test('collectSubSkills skips disabled entries and preserves install.ref', () => {
  const rootDir = mkdtempSync(join(tmpdir(), 'skill-index-'));

  try {
    mkdirSync(join(rootDir, 'scientific-skills', 'demo-one'), { recursive: true });
    writeFileSync(
      join(rootDir, 'scientific-skills', 'demo-one', 'SKILL.md'),
      ['---', 'name: demo-one', 'description: Demo one', 'license: MIT', 'tags: [demo]', '---'].join('\n'),
      'utf8',
    );

    mkdirSync(join(rootDir, 'scientific-skills', 'skip-me'), { recursive: true });
    writeFileSync(
      join(rootDir, 'scientific-skills', 'skip-me', 'SKILL.md'),
      ['---', 'name: skip-me', 'description: Skip me', 'license: MIT', '---'].join('\n'),
      'utf8',
    );

    const subSkills = collectSubSkills({
      rootDir,
      includeRootSkill: false,
      prefix: 'sa',
      relativeRoot: 'scientific-skills',
      parentSkill: {
        install: {
          method: 'sparse-checkout',
          url: 'https://github.com/K-Dense-AI/scientific-agent-skills.git',
          ref: 'main',
        },
        post_install: ['clean_ads'],
      },
      classification: {
        'sa.demo-one': { category: 'research', subdiscipline: 'life-sci' },
        'sa.skip-me': { category: 'research', disabled: true },
      },
    });

    assert.equal(subSkills.length, 1);
    assert.equal(subSkills[0].id, 'sa.demo-one');
    assert.equal(subSkills[0].install.ref, 'main');
    assert.equal(subSkills[0].sparse_path, 'scientific-skills/demo-one');
  } finally {
    rmSync(rootDir, { recursive: true, force: true });
  }
});
