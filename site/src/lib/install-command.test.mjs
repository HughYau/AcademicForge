import test from 'node:test';
import assert from 'node:assert/strict';

import {
  ACADEMIC_FORGE_BRANCH,
  SCRIPT_BASE,
  buildInstallCommand,
  buildVerifyCommand,
  getToolPath,
} from './install-command.mjs';

test('linux install command points at the site-first branch', () => {
  assert.equal(ACADEMIC_FORGE_BRANCH, 'site-first');
  assert.equal(
    SCRIPT_BASE,
    'https://raw.githubusercontent.com/HughYau/AcademicForge/refs/heads/site-first/scripts',
  );

  assert.equal(
    buildInstallCommand({
      platform: 'linux',
      tool: 'opencode',
      skillIds: ['superpowers', 'scientific-visualization'],
    }),
    [
      'curl -sSL https://raw.githubusercontent.com/HughYau/AcademicForge/refs/heads/site-first/scripts/forge-install.sh | bash -s -- ' + '\\',
      '  --tool opencode ' + '\\',
      '  --skills superpowers,scientific-visualization',
    ].join('\n'),
  );
});

test('windows install command points at the site-first branch', () => {
  assert.equal(
    buildInstallCommand({
      platform: 'windows',
      tool: 'claude',
      skillIds: ['superpowers'],
    }),
    [
      "$script = Join-Path $PWD 'forge-install.ps1'",
      "Invoke-WebRequest -Uri 'https://raw.githubusercontent.com/HughYau/AcademicForge/refs/heads/site-first/scripts/forge-install.ps1' -OutFile $script",
      "& $script -Tool claude -Skills 'superpowers'",
      'Remove-Item $script',
    ].join('\n'),
  );
});

test('verify commands stay aligned with the selected tool', () => {
  assert.equal(getToolPath({ platform: 'linux', tool: 'codex' }), '.codex/skills');
  assert.equal(buildVerifyCommand({ platform: 'linux', tool: 'codex' }), 'ls .codex/skills/');
  assert.equal(buildVerifyCommand({ platform: 'windows', tool: 'opencode' }), 'dir .opencode\\skills');
});
