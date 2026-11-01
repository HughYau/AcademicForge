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
    'sa.pi-agent': { category: 'workflow', disabled: true },
    'sa.statistical-power': { category: 'research', subdiscipline: null },
    'sa.onekgpd': { category: 'research', subdiscipline: 'life-sci' },
    'sa.tamarind': { category: 'research', subdiscipline: 'life-sci' },
    'ns.nature-downloader': { category: 'research', subdiscipline: 'other' },
    'ns.nature-experiment-log': { category: 'workflow' },
    'ns.nature-literature-pipeline': { category: 'research', subdiscipline: 'other' },
    'ns.nature-proposal-writer': { category: 'writing' },
    'ns.nature-paper-to-patent': { category: 'writing' },
    // 2026-08-08 refresh: scientific-agent-skills 149 -> 160, nature-skills 15 -> 19.
    'sa.analytical-method-validation': { category: 'research', subdiscipline: 'chem-mat-phys' },
    'sa.deepspot-m': { category: 'research', subdiscipline: 'life-sci' },
    'sa.genomic-coordinates': { category: 'research', subdiscipline: 'life-sci' },
    'sa.genomic-intelligence': { category: 'research', subdiscipline: 'life-sci' },
    'sa.iso-standards-readiness': { category: 'research', subdiscipline: 'life-sci' },
    'sa.ontology-term-resolution': { category: 'research', subdiscipline: 'life-sci' },
    'sa.openpiv': { category: 'research', subdiscipline: 'chem-mat-phys' },
    'sa.paperclip': { category: 'research', subdiscipline: 'life-sci' },
    'sa.pathogen-variant-surveillance': { category: 'research', subdiscipline: 'life-sci' },
    'sa.pkpd-modeling': { category: 'research', subdiscipline: 'life-sci' },
    'sa.relsa-severity-assessment': { category: 'research', subdiscipline: 'life-sci' },
    'sa.uncertainty-and-units': { category: 'research', subdiscipline: null },
    'ns.nature-paper-card': { category: 'writing' },
    'ns.nature-ref-verifier': { category: 'research', subdiscipline: 'other' },
    'ns.nature-shared': { category: 'workflow' },
    'ns.nature-statistics': { category: 'writing' },
    // 2026-08-30 refresh: scientific-agent-skills 160 -> 163, nature-skills 19 -> 20.
    'sa.lab-hardware-cad': { category: 'research', subdiscipline: 'lab-automation' },
    'sa.ncats-arax': { category: 'research', subdiscipline: 'life-sci' },
    'sa.waypoint-bio': { category: 'research', subdiscipline: 'life-sci' },
    'ns.nature-image2ppt': { category: 'visualization' },
    // 2026-11-01 refresh: scientific-agent-skills 163 -> 177, nature-skills 20 -> 24.
    'sa.13c-metabolic-flux': { category: 'research', subdiscipline: 'life-sci' },
    'sa.alphagenome': { category: 'research', subdiscipline: 'life-sci' },
    'sa.cantera': { category: 'research', subdiscipline: 'chem-mat-phys' },
    'sa.cellprofiler': { category: 'research', subdiscipline: 'life-sci' },
    'sa.datalad': { category: 'research', subdiscipline: null },
    'sa.fictiv': { category: 'research', subdiscipline: 'lab-automation', disabled: true },
    'sa.flowkit': { category: 'research', subdiscipline: 'life-sci' },
    'sa.folklore-variant-evidence': { category: 'research', subdiscipline: 'life-sci' },
    'sa.mageck': { category: 'research', subdiscipline: 'life-sci' },
    'sa.marine-carbonate-chemistry': { category: 'research', subdiscipline: 'earth-geo' },
    'sa.nmrglue': { category: 'research', subdiscipline: 'chem-mat-phys' },
    'sa.nwb-conversion': { category: 'research', subdiscipline: 'life-sci' },
    'sa.primer-design': { category: 'research', subdiscipline: 'life-sci' },
    'sa.pybamm': { category: 'research', subdiscipline: 'chem-mat-phys' },
    'sa.pycalphad': { category: 'research', subdiscipline: 'chem-mat-phys' },
    'sa.qiime2-amplicon': { category: 'research', subdiscipline: 'life-sci' },
    'sa.relion': { category: 'research', subdiscipline: 'life-sci' },
    'sa.tellurium': { category: 'research', subdiscipline: 'life-sci' },
    'ns.nature-paper-trans': { category: 'writing' },
    'ns.nature-paper-xray': { category: 'writing' },
    'ns.nature-paper2word': { category: 'writing' },
    'ns.nature-social-science': { category: 'writing' },
  };

  for (const [id, expected] of Object.entries(expectedClassification)) {
    assert.deepEqual(classification[id], expected, `missing or incorrect classification for ${id}`);
    assert.ok(translations[id]?.trim(), `missing Chinese translation for ${id}`);
  }
});

test('retired upstream skill ids are not resurrected', () => {
  const classification = JSON.parse(
    readFileSync(new URL('../skill-classification.json', import.meta.url), 'utf8'),
  );
  const translations = JSON.parse(
    readFileSync(new URL('../skill-translations.zh.json', import.meta.url), 'utf8'),
  );

  // Upstream K-Dense-AI/scientific-agent-skills replaced skills/iso-13485-certification
  // with the broader skills/iso-standards-readiness on or before 2026-08-08. Keeping the
  // old mapping makes `build-skill-index.mjs` fail with "Classification contains unknown ids".
  assert.equal(classification['sa.iso-13485-certification'], undefined);
  assert.equal(translations['sa.iso-13485-certification'], undefined);
  assert.ok(classification['sa.iso-standards-readiness'], 'replacement id is classified');

  // Upstream removed its vendored office-document skills (docx, pdf, pptx, xlsx) with no
  // replacement by 2026-10-26; they were retired in the 2026-11-01 refresh.
  for (const id of ['sa.docx', 'sa.pdf', 'sa.pptx', 'sa.xlsx']) {
    assert.equal(classification[id], undefined, `${id} was removed upstream`);
    assert.equal(translations[id], undefined, `${id} was removed upstream`);
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

test('agents.md only cites skill ids that exist in the registry', () => {
  const registry = JSON.parse(
    readFileSync(new URL('../../registry/skills.json', import.meta.url), 'utf8'),
  );
  const agentsGuide = readFileSync(new URL('../../site/public/agents.md', import.meta.url), 'utf8');
  const ids = new Set(registry.skills.flatMap((skill) => [skill.id, ...(skill.sub_skills ?? []).map((sub) => sub.id)]));
  const prefixes = new Set(collections.map((collection) => collection.prefix));

  // Agents copy example ids straight into install commands, so a stale one is a broken install.
  const cited = [...agentsGuide.matchAll(/`([a-z0-9]+)\.([a-z0-9][a-z0-9.-]*)`/g)]
    .filter(([, prefix]) => prefixes.has(prefix))
    .map(([, prefix, rest]) => `${prefix}.${rest}`);

  assert.ok(cited.length > 0, 'expected agents.md to cite at least one sub-skill id');
  for (const id of cited) {
    assert.ok(ids.has(id), `agents.md cites unknown skill id ${id}`);
  }
});

test('owner-removed packs and hidden sub-skills stay out of the catalog', () => {
  const registry = JSON.parse(
    readFileSync(new URL('../../registry/skills.json', import.meta.url), 'utf8'),
  );
  const classification = JSON.parse(
    readFileSync(new URL('../skill-classification.json', import.meta.url), 'utf8'),
  );
  const ids = new Set(registry.skills.flatMap((skill) => [skill.id, ...(skill.sub_skills ?? []).map((sub) => sub.id)]));

  // 2026-11-02 owner decision. Top-level packs: not academic / no license / superseded.
  for (const id of ['andrej-karpathy-skills', 'posterskill']) {
    assert.equal(ids.has(id), false, `${id} was removed by the owner`);
  }

  // Upstream sub-skills hidden as off-topic for an academic catalog (fictiv also places paid orders).
  for (const id of ['sa.fictiv', 'sa.usfiscaldata', 'sa.market-research-reports', 'sa.pi-agent']) {
    assert.equal(classification[id]?.disabled, true, `${id} should stay disabled`);
    assert.equal(ids.has(id), false, `${id} should not be published`);
  }
});

test('owner-approved anti-defensive-writing pack installs only its skills directory', () => {
  const registry = JSON.parse(
    readFileSync(new URL('../../registry/skills.json', import.meta.url), 'utf8'),
  );
  const pack = registry.skills.find((skill) => skill.id === 'anti-defensive-writing');

  // 2026-11-02 owner approval. Upstream root also holds Codex-plugin packaging and prompts.
  assert.ok(pack, 'anti-defensive-writing should be in the catalog');
  assert.deepEqual(pack.install, {
    method: 'sparse-checkout',
    url: 'https://github.com/Adkid-Zephyr/anti-defensive-writing-Skill.git',
    sparse_path: 'skills',
  });
  assert.equal(pack.license, 'MIT');
  assert.equal(pack.skill_count, 2);
});
