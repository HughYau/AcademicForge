import test from 'node:test';
import assert from 'node:assert/strict';
import { spawnSync } from 'node:child_process';
import { mkdtempSync, mkdirSync, readFileSync, writeFileSync, rmSync } from 'node:fs';
import { join } from 'node:path';
import { tmpdir } from 'node:os';
import { fileURLToPath } from 'node:url';

import { collectSubSkills, parseFrontmatter } from '../lib/skill-index.mjs';
import { collections } from '../lib/skill-collections.mjs';

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
    mkdirSync(join(rootDir, 'skills', 'demo-one'), { recursive: true });
    writeFileSync(
      join(rootDir, 'skills', 'demo-one', 'SKILL.md'),
      ['---', 'name: demo-one', 'description: Demo one', 'license: MIT', 'tags: [demo]', '---'].join('\n'),
      'utf8',
    );

    mkdirSync(join(rootDir, 'skills', 'skip-me'), { recursive: true });
    writeFileSync(
      join(rootDir, 'skills', 'skip-me', 'SKILL.md'),
      ['---', 'name: skip-me', 'description: Skip me', 'license: MIT', '---'].join('\n'),
      'utf8',
    );

    const subSkills = collectSubSkills({
      rootDir,
      includeRootSkill: false,
      prefix: 'sa',
      relativeRoot: 'skills',
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
    assert.equal(subSkills[0].sparse_path, 'skills/demo-one');
  } finally {
    rmSync(rootDir, { recursive: true, force: true });
  }
});

test('scientific-agent-skills collection tracks the upstream skills directory', () => {
  const scientificAgentSkills = collections.find((collection) => collection.rootSkillId === 'scientific-agent-skills');

  assert.equal(scientificAgentSkills?.relativeRoot, 'skills');
  assert.equal(scientificAgentSkills?.clonePath, 'skills');
});

test('classifies and translates the current upstream additions', () => {
  const classification = JSON.parse(
    readFileSync(new URL('../skill-classification.json', import.meta.url), 'utf8'),
  );
  const translations = JSON.parse(
    readFileSync(new URL('../skill-translations.zh.json', import.meta.url), 'utf8'),
  );
  const expectedClassification = {
    'sa.arbor': { category: 'research', subdiscipline: null },
    'sa.experimental-design': { category: 'research', subdiscipline: null },
    'sa.pi-agent': { category: 'workflow' },
    'sa.statistical-power': { category: 'research', subdiscipline: null },
    'sa.onekgpd': { category: 'research', subdiscipline: 'life-sci' },
    'sa.tamarind': { category: 'research', subdiscipline: 'life-sci' },
    'ns.nature-downloader': { category: 'research', subdiscipline: 'other' },
    'ns.nature-experiment-log': { category: 'workflow' },
    'ns.nature-literature-pipeline': { category: 'research', subdiscipline: 'other' },
    'ns.nature-proposal-writer': { category: 'writing' },
    'ns.nature-paper-to-patent': { category: 'writing' },
  };

  for (const [id, expected] of Object.entries(expectedClassification)) {
    assert.deepEqual(classification[id], expected, `missing or incorrect classification for ${id}`);
    assert.ok(translations[id]?.trim(), `missing Chinese translation for ${id}`);
  }
});

test('claude-science is registered as a locally maintained collection', () => {
  const claudeScience = collections.find((collection) => collection.rootSkillId === 'claude-science');

  assert.ok(claudeScience, 'claude-science collection is registered');
  assert.equal(claudeScience.local, true);
  assert.equal(claudeScience.prefix, 'cs');
  assert.equal(claudeScience.relativeRoot, 'skills/claude-science');

  const classification = JSON.parse(
    readFileSync(new URL('../skill-classification.json', import.meta.url), 'utf8'),
  );
  const translations = JSON.parse(
    readFileSync(new URL('../skill-translations.zh.json', import.meta.url), 'utf8'),
  );
  const expectedClassification = {
    'cs.figure-style': { category: 'visualization' },
    'cs.alphafold2': { category: 'research', subdiscipline: 'life-sci' },
    'cs.pdf-explore': { category: 'research', subdiscipline: 'other' },
    'cs.literature-review': { category: 'writing' },
    'cs.skill-creator': { category: 'workflow' },
  };

  for (const [id, expected] of Object.entries(expectedClassification)) {
    assert.deepEqual(classification[id], expected, `missing or incorrect classification for ${id}`);
    assert.ok(translations[id]?.trim(), `missing Chinese translation for ${id}`);
  }
});

test('claude-science sub-skills resolve from the local skills directory', () => {
  const repoRoot = fileURLToPath(new URL('../../', import.meta.url));
  const classification = JSON.parse(
    readFileSync(new URL('../skill-classification.json', import.meta.url), 'utf8'),
  );
  const translations = JSON.parse(
    readFileSync(new URL('../skill-translations.zh.json', import.meta.url), 'utf8'),
  );

  const subSkills = collectSubSkills({
    rootDir: repoRoot,
    relativeRoot: 'skills/claude-science',
    includeRootSkill: false,
    prefix: 'cs',
    parentSkill: {
      install: {
        method: 'sparse-checkout',
        url: 'https://github.com/HughYau/AcademicForge.git',
        sparse_path: 'skills/claude-science',
      },
      post_install: [],
    },
    classification,
    translations,
  });

  assert.equal(subSkills.length, 32);

  const figureStyle = subSkills.find((skill) => skill.id === 'cs.figure-style');
  assert.ok(figureStyle, 'cs.figure-style is collected');
  assert.equal(figureStyle.category, 'visualization');
  assert.equal(figureStyle.sparse_path, 'skills/claude-science/figure-style');
  assert.equal(figureStyle.install.url, 'https://github.com/HughYau/AcademicForge.git');
  assert.equal(figureStyle.install.sparse_path, 'skills/claude-science/figure-style');
  assert.notEqual(figureStyle.summary.zh, figureStyle.summary.en);
});

test('registry excludes community packs that have not received user approval', () => {
  const registry = JSON.parse(
    readFileSync(new URL('../../registry/skills.json', import.meta.url), 'utf8'),
  );
  const unapprovedPacks = [
    'academic-research-skills',
    'deep-research-skills',
    'phd-skills',
    'voidful-academic-skills',
  ];

  for (const id of unapprovedPacks) {
    assert.equal(
      registry.skills.some((entry) => entry.id === id),
      false,
      `do not publish ${id} without explicit user approval`,
    );
  }

  assert.equal(
    registry.skills.some((entry) => entry.id === 'codex-claude-academic-skills'),
    false,
    'do not publish the Windows-path-length-incompatible full-pack clone',
  );
});

test('PowerShell installer exits nonzero when a pack fails to install', (t) => {
  const rootDir = mkdtempSync(join(tmpdir(), 'forge-installer-failure-'));

  try {
    const registryPath = join(rootDir, 'registry.json');
    const outputPath = join(rootDir, 'output');
    writeFileSync(
      registryPath,
      JSON.stringify({
        skills: [{
          id: 'bad-pack',
          name: 'Bad pack',
          summary: { en: 'test', zh: '测试' },
          author: 'test',
          repository: 'https://example.test/bad-pack',
          license: 'MIT',
          skill_count: 1,
          stars: 0,
          tags: [],
          install: { method: 'git-clone', url: join(rootDir, 'missing-source') },
          post_install: [],
        }],
      }),
      'utf8',
    );

    const result = spawnSync(
      'pwsh',
      [
        '-NoProfile',
        '-File',
        fileURLToPath(new URL('../forge-install.ps1', import.meta.url)),
        '-Tool',
        'codex',
        '-Skills',
        'bad-pack',
        '-Registry',
        registryPath,
        '-Path',
        outputPath,
      ],
      { encoding: 'utf8' },
    );

    if (result.error?.code === 'ENOENT') {
      t.skip('pwsh is not available in this environment');
      return;
    }

    assert.equal(result.status, 1, result.stdout || result.stderr);
    assert.match(result.stdout, /FAIL bad-pack/);
  } finally {
    rmSync(rootDir, { recursive: true, force: true });
  }
});
