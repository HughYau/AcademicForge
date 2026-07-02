import test from 'node:test';
import assert from 'node:assert/strict';
import { readFileSync } from 'node:fs';
import { resolve } from 'node:path';

const repoRoot = resolve(import.meta.dirname, '../../..');
const read = (relativePath) => readFileSync(resolve(repoRoot, relativePath), 'utf8');

test('the spark-on-click effect is removed everywhere', () => {
  const effects = read('site/src/lib/forge-effects.mjs');
  assert.doesNotMatch(effects, /spawnSparks/);
  // The subtle command-update glow (pulseEmber) is a separate effect and stays.
  assert.match(effects, /export function pulseEmber/);

  for (const component of [
    'site/src/components/SkillGrid.astro',
    'site/src/components/SkillCard.astro',
    'site/src/components/CodeBlock.astro',
    'site/src/components/Configurator.astro',
  ]) {
    assert.doesNotMatch(read(component), /spawnSparks/, `${component} still references spawnSparks`);
  }

  const css = read('site/src/styles/global.css');
  assert.doesNotMatch(css, /forge-spark/);
});

test('compact skill cards lead with the summary, not license metadata', () => {
  const css = read('site/src/styles/global.css');
  // Three lines of summary — the intro gets the room the license used to take.
  assert.match(css, /skill-card__summary--compact\s*\{\s*-webkit-line-clamp:\s*3;/);

  const skillCard = read('site/src/components/SkillCard.astro');
  // No license clutter on the compact face; a few keyword tags still ride along.
  assert.doesNotMatch(skillCard, /licenseLabel/);
  assert.match(skillCard, /skill-card__facts/);
  assert.match(skillCard, /compactTags/);
});
