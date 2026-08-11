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

test('Academic Humanizer leads the writing category despite its star count', () => {
  const categories = read('site/src/lib/categories.ts');
  assert.match(categories, /'academic-humanizer': 'writing'/);

  const registry = JSON.parse(read('registry/skills.json'));
  const pack = registry.skills.find((skill) => skill.id === 'academic-humanizer');
  assert.ok(pack, 'academic-humanizer is missing from the registry');
  assert.equal(pack.featured, true);

  // Every other writing pack outstars it, so the pin is what puts it first.
  const sorting = read('site/src/lib/registry.ts');
  assert.match(sorting, /Number\(right\.featured \?\? false\) - Number\(left\.featured \?\? false\)/);
});
