import test from 'node:test';
import assert from 'node:assert/strict';
import { readFileSync } from 'node:fs';
import { resolve } from 'node:path';

const repoRoot = resolve(import.meta.dirname, '../../..');
const read = (relativePath) => readFileSync(resolve(repoRoot, relativePath), 'utf8');

test('source packages replace the old bulk-select presets', () => {
  const grid = read('site/src/components/SkillGrid.astro');

  // The old "select a bundle of skills" presets are gone.
  assert.doesNotMatch(grid, /data-preset-skills/);
  assert.doesNotMatch(grid, /syncPresetStates|getPresetCheckboxes/);
  assert.doesNotMatch(grid, /论文写作入门包|流程纪律包|图表海报包/);

  // Four source packages are defined, one per upstream repository.
  assert.match(grid, /ORIGIN_PACKAGES/);
  for (const origin of ['sa', 'ns', 'air', 'cs']) {
    assert.match(grid, new RegExp(`origin:\\s*'${origin}'`));
  }
  assert.match(grid, /data-origin-filter=\{pkg\.origin\}/);
});

test('clicking a package filters the catalog by origin instead of checking boxes', () => {
  const grid = read('site/src/components/SkillGrid.astro');

  // A click toggles an activeOrigin filter that the card loop honours.
  assert.match(grid, /let activeOrigin = ''/);
  assert.match(grid, /activeOrigin = activeOrigin === origin \? '' : origin/);
  assert.match(grid, /const matchesOrigin = !activeOrigin \|\| card\.dataset\.origin === activeOrigin;/);

  // A package view spans every category, like text search.
  assert.match(grid, /const globalSearch = hasQuery \|\| activeOrigin !== '';/);
});

test('every skill card advertises its source origin for filtering', () => {
  const skillCard = read('site/src/components/SkillCard.astro');

  assert.match(skillCard, /data-origin=\{origin \|\| undefined\}/);
  // Parent skills map to an origin too, so a filter reveals the main skill.
  assert.match(skillCard, /'scientific-agent-skills': 'sa'/);
  assert.match(skillCard, /'AI-research-SKILLs': 'air'/);
  assert.match(skillCard, /'nature-skills': 'ns'/);
  assert.match(skillCard, /'claude-science': 'cs'/);
});
