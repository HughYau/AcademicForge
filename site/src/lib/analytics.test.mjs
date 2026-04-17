import test from 'node:test';
import assert from 'node:assert/strict';
import { readFileSync } from 'node:fs';
import { resolve } from 'node:path';

const repoRoot = resolve(import.meta.dirname, '../../..');

const read = (relativePath) => readFileSync(resolve(repoRoot, relativePath), 'utf8');

test('Layout includes GA4 gtag snippet with provided measurement ID', () => {
  const layout = read('site/src/layouts/Layout.astro');

  assert.match(layout, /googletagmanager\.com\/gtag\/js\?id=\$\{googleAnalyticsId\}/);
  assert.match(layout, /gtag\('config', 'G-R67NC4FQJ1'\)/);
});
