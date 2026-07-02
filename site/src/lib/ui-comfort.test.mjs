import test from 'node:test';
import assert from 'node:assert/strict';
import { existsSync, readFileSync } from 'node:fs';
import { resolve } from 'node:path';

const repoRoot = resolve(import.meta.dirname, '../../..');

const read = (relativePath) => readFileSync(resolve(repoRoot, relativePath), 'utf8');

test('desktop layout scrolls naturally instead of locking the viewport', () => {
  const css = read('site/src/styles/global.css');
  assert.doesNotMatch(css, /body\s*\{\s*overflow:\s*hidden/);

  const index = read('site/src/pages/index.astro');
  assert.doesNotMatch(index, /lg:h-\[calc\(100svh-92px\)\]/);
  assert.doesNotMatch(index, /lg:overflow-hidden/);
  assert.match(index, /max-w-\[1440px\]/);

  const grid = read('site/src/components/SkillGrid.astro');
  assert.doesNotMatch(grid, /overflow-y-auto/);
});

test('configurator column sticks and scrolls within the viewport', () => {
  const configurator = read('site/src/components/Configurator.astro');
  assert.match(configurator, /lg:sticky/);
  assert.match(configurator, /lg:top-\[96px\]/);
  assert.match(configurator, /lg:max-h-\[calc\(100svh-108px\)\]/);
  assert.match(configurator, /lg:overflow-y-auto/);
  assert.doesNotMatch(configurator, /lg:h-full/);

  const index = read('site/src/pages/index.astro');
  assert.match(index, /lg:items-start/);
});

test('whole card toggles selection; details use a dedicated button', () => {
  const skillCard = read('site/src/components/SkillCard.astro');
  assert.doesNotMatch(skillCard, /data-detail-toggle/);

  const grid = read('site/src/components/SkillGrid.astro');
  assert.match(grid, /\.skill-card__detail-panel/);
  assert.match(grid, /checkbox\.checked = !checkbox\.checked;/);

  const css = read('site/src/styles/global.css');
  assert.doesNotMatch(css, /translateY\(-2px\)/);
  assert.match(css, /\.skill-card\s*\{[^}]*cursor:\s*pointer/s);
});

test('typography raised for readability', () => {
  const css = read('site/src/styles/global.css');
  assert.match(css, /html\s*\{\s*font-size:\s*15px/);
  assert.match(css, /repeat\(auto-fill,\s*minmax\(250px,\s*1fr\)\)/);
  assert.match(css, /\.lang-zh\s*\{\s*font-family:\s*var\(--af-font-sans\)/);

  const skillCard = read('site/src/components/SkillCard.astro');
  assert.doesNotMatch(skillCard, /text-\[0\.72rem\]/);
  assert.doesNotMatch(skillCard, /text-\[0\.82rem\]/);
});

test('library header slimmed with sticky toolbar and trailing legend', () => {
  const grid = read('site/src/components/SkillGrid.astro');
  assert.match(grid, /library-toolbar/);
  assert.ok(
    grid.indexOf('Scientific Agent Skills') > grid.indexOf('id="skill-grid-empty"'),
    'attribution legend must render after the grid',
  );
  assert.doesNotMatch(grid, /sorted by stars/);
  assert.doesNotMatch(grid, /\(repo\)/);

  const css = read('site/src/styles/global.css');
  assert.match(css, /\.library-toolbar\s*\{[^}]*position:\s*sticky/s);
});

test('flattened card container and single-border chrome', () => {
  const grid = read('site/src/components/SkillGrid.astro');
  assert.doesNotMatch(grid, /id="skill-grid" class="[^"]*bg-white/);

  const skillCard = read('site/src/components/SkillCard.astro');
  assert.doesNotMatch(skillCard, /skill-card rounded-\[18px\] border border-\[#e8e6dc\] bg-white shadow/);

  const css = read('site/src/styles/global.css');
  assert.match(css, /\.category-tab\[aria-pressed='true'\]\s*\{[^}]*background:\s*var\(--af-brand\)/s);
  assert.match(css, /\.skill-card\.is-expanded[^{]*\{[^}]*-webkit-line-clamp:\s*unset/s);
});

test('github star badge, page footer, and dead code removed', () => {
  const layout = read('site/src/layouts/Layout.astro');
  assert.match(layout, /img\.shields\.io\/github\/stars/);
  assert.match(layout, /<footer/);

  const css = read('site/src/styles/global.css');
  assert.doesNotMatch(css, /\.selection-chip/);
  assert.doesNotMatch(css, /\.selection-placeholder/);
  assert.doesNotMatch(css, /\.compact-clamp/);

  assert.ok(!existsSync(resolve(repoRoot, 'site/src/components/InstallGuide.astro')));

  const configurator = read('site/src/components/Configurator.astro');
  assert.doesNotMatch(configurator, /removeButton\.textContent = 'x';/);
});

test('mobile pill jumps to the configurator; header AI label hides on phones', () => {
  const configurator = read('site/src/components/Configurator.astro');
  assert.match(configurator, /id="mobile-command-jump"/);
  assert.match(configurator, /IntersectionObserver/);

  const layout = read('site/src/layouts/Layout.astro');
  assert.match(layout, /id="ai-prompt-copy-label" class="hidden truncate sm:inline"/);

  const css = read('site/src/styles/global.css');
  assert.match(css, /\.mobile-command-jump/);
});
