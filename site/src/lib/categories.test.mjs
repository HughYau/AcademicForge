import test from 'node:test';
import assert from 'node:assert/strict';
import { readFileSync } from 'node:fs';
import { resolve } from 'node:path';

const repoRoot = resolve(import.meta.dirname, '../../..');

const read = (relativePath) => readFileSync(resolve(repoRoot, relativePath), 'utf8');

test('Nature Skills is categorized with writing-oriented packs', () => {
  const categories = read('site/src/lib/categories.ts');

  assert.match(categories, /'nature-skills': 'writing'/);
});
