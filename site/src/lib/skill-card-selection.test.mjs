import test from 'node:test';
import assert from 'node:assert/strict';
import { readFileSync } from 'node:fs';
import { resolve } from 'node:path';

const repoRoot = resolve(import.meta.dirname, '../../..');

const read = (relativePath) => readFileSync(resolve(repoRoot, relativePath), 'utf8');

test('SkillCard keeps the checkbox in-place instead of using sr-only', () => {
  const skillCard = read('site/src/components/SkillCard.astro');

  assert.doesNotMatch(skillCard, /class="skill-checkbox peer sr-only"/);
  assert.match(skillCard, /class="skill-card__selection relative inline-flex shrink-0 cursor-pointer items-center pt-0\.5"/);
  assert.match(skillCard, /class="skill-checkbox peer absolute inset-0 m-0 h-full w-full cursor-pointer opacity-0"/);
  assert.match(skillCard, /peer-focus-visible:border-\[#3898ec\] peer-focus-visible:shadow-\[0_0_0_1px_#3898ec\]/);
});
