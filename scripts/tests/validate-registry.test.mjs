import test from 'node:test';
import assert from 'node:assert/strict';

import { validateRegistry } from '../validate-registry.mjs';

test('validateRegistry reports duplicate ids and invalid sparse installs', () => {
  const errors = validateRegistry({
    skills: [
      {
        id: 'duplicate',
        name: 'Duplicate A',
        summary: { en: 'A', zh: '甲' },
        author: 'a',
        repository: 'https://example.com/a',
        license: 'MIT',
        skill_count: 1,
        stars: 1,
        tags: [],
        install: { method: 'sparse-checkout', url: 'https://example.com/a.git' },
        post_install: [],
      },
      {
        id: 'duplicate',
        name: 'Duplicate B',
        summary: { en: 'B', zh: '乙' },
        author: 'b',
        repository: 'https://example.com/b',
        license: 'MIT',
        skill_count: 1,
        stars: 1,
        tags: [],
        install: { method: 'download', url: 'https://example.com/b.zip' },
        post_install: [],
      },
    ],
  }, { repoRoot: process.cwd() });

  assert.deepEqual(errors, [
    "Skill 'duplicate' uses sparse-checkout without install.sparse_path",
    "Duplicate skill id 'duplicate'",
    "Skill 'duplicate' uses unsupported install.method 'download'",
  ]);
});

test('validateRegistry reports untranslated Chinese summaries', () => {
  const errors = validateRegistry({
    skills: [
      {
        id: 'untranslated',
        name: 'Untranslated',
        summary: {
          en: 'Use this skill for literature review.',
          zh: 'Use this skill for literature review.',
        },
        author: 'a',
        repository: 'https://example.com/a',
        license: 'MIT',
        skill_count: 1,
        stars: 1,
        tags: [],
        install: { method: 'git-clone', url: 'https://example.com/a.git' },
        post_install: [],
      },
    ],
  }, { repoRoot: process.cwd() });

  assert.deepEqual(errors, [
    "Skill 'untranslated' has untranslated summary.zh",
  ]);
});
