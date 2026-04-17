import test from 'node:test';
import assert from 'node:assert/strict';
import { readFileSync } from 'node:fs';
import { resolve } from 'node:path';

const repoRoot = resolve(import.meta.dirname, '../../..');

const read = (relativePath) => readFileSync(resolve(repoRoot, relativePath), 'utf8');

test('Configurator has valid zh label markup and user-facing install hint', () => {
  const configurator = read('site/src/components/Configurator.astro');

  assert.match(configurator, /<span class="lang-zh">高级<\/span>/);
  assert.doesNotMatch(configurator, /<span class="lang-zh"高级<\/span>/);
  assert.doesNotMatch(configurator, /Install command stays visible here\./);
});

test('InstallGuide uses real install script URL', () => {
  const guide = read('site/src/components/InstallGuide.astro');

  assert.doesNotMatch(guide, /example\.invalid/);
  assert.match(
    guide,
    /https:\/\/raw\.githubusercontent\.com\/HughYau\/AcademicForge\/refs\/heads\/site-first\/scripts\/forge-install\.sh/,
  );
});

test('Layout includes canonical and social metadata tags', () => {
  const layout = read('site/src/layouts/Layout.astro');

  assert.match(layout, /rel="canonical"/);
  assert.match(layout, /property="og:title"/);
  assert.match(layout, /property="og:description"/);
  assert.match(layout, /property="og:type"/);
  assert.match(layout, /property="og:url"/);
  assert.match(layout, /property="og:image"/);
  assert.match(layout, /name="twitter:card"/);
  assert.match(layout, /name="twitter:title"/);
  assert.match(layout, /name="twitter:description"/);
  assert.match(layout, /name="twitter:image"/);
});
