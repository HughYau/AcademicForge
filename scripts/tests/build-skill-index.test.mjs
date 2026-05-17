import test from 'node:test';
import assert from 'node:assert/strict';
import { mkdtempSync, mkdirSync, writeFileSync, rmSync } from 'node:fs';
import { join } from 'node:path';
import { tmpdir } from 'node:os';

import { collectSubSkills, parseFrontmatter } from '../lib/skill-index.mjs';

test('parseFrontmatter supports folded YAML descriptions', () => {
  const frontmatter = parseFrontmatter(
    [
      '---',
      'name: nature-citation',
      'description: >-',
      '  Add strict Nature/CNS citations to manuscript text.',
      '  Use when the user asks for supporting references.',
      'license: MIT',
      '---',
    ].join('\n'),
    'SKILL.md',
  );

  assert.equal(
    frontmatter.description,
    'Add strict Nature/CNS citations to manuscript text. Use when the user asks for supporting references.',
  );
});

test('collectSubSkills skips disabled entries without pinning install.ref', () => {
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
      translations: {
        'sa.demo-one': 'Demo one 的中文摘要',
      },
    });

    assert.equal(subSkills.length, 1);
    assert.equal(subSkills[0].id, 'sa.demo-one');
    assert.equal(subSkills[0].summary.zh, 'Demo one 的中文摘要');
    assert.equal(subSkills[0].install.ref, undefined);
    assert.equal(subSkills[0].sparse_path, 'scientific-skills/demo-one');
  } finally {
    rmSync(rootDir, { recursive: true, force: true });
  }
});
