# Site-First Branch Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Move the post-`a259d1f93c047c404c22111670fa7ae32727b1d4` work onto a dedicated `site-first` branch, retarget the public site and installers to that branch, and strip that branch down to a site-first catalog repo that keeps only `skills/scientific-visualization` locally.

**Architecture:** Treat `master` as the legacy compatibility line and `site-first` as the public website branch. Use `registry/skills.json` as the single runtime source of truth, add `install.ref` so repo-backed installs can pin to `site-first`, replace local-mirror index generation with temporary upstream clones, then remove mirror-era files from the `site-first` branch only.

**Tech Stack:** Astro 6, Tailwind CSS 4, Node.js 20 ESM scripts, Bash, PowerShell, GitHub Actions, GitHub Pages

---

## Preflight File Map

- `package.json`
  - Root orchestration scripts for build, preview, and CI validation on the `site-first` branch.
- `registry/skills.json`
  - Runtime catalog metadata for the site and installers. Will gain `install.ref` where branch pinning is required.
- `site/src/lib/registry.ts`
  - Type definitions for registry records consumed by the Astro site.
- `site/src/lib/install-command.mjs`
  - New shared helper for branch-aware command generation used by the browser UI and unit tests.
- `site/src/lib/install-command.test.mjs`
  - Node test for branch-aware site command generation.
- `site/src/components/Configurator.astro`
  - Browser-side command builder panel; remove duplicated raw URL construction here.
- `site/src/components/InstallGuide.astro`
  - Modal install walkthrough; also remove duplicated raw URL construction here.
- `scripts/forge-install.sh`
  - Bash installer; add `--registry` and `install.ref` support.
- `scripts/forge-install.ps1`
  - PowerShell installer; add `-Registry` and `install.ref` support.
- `scripts/tests/forge-install-local-registry.sh`
  - Bash smoke test that proves local registry paths and branch-pinned sparse installs work.
- `scripts/tests/forge-install-local-registry.ps1`
  - PowerShell smoke test that proves the same behavior on Windows.
- `scripts/lib/skill-index.mjs`
  - New helper module for scanning temporary upstream clones and generating sub-skill metadata.
- `scripts/build-skill-index.mjs`
  - Reworked to use temporary clones rather than checked-in mirrors.
- `scripts/skill-classification.json`
  - Existing category/subdiscipline map; extend it with `disabled: true` support for filtered skills.
- `scripts/validate-registry.mjs`
  - New registry schema validator.
- `scripts/tests/build-skill-index.test.mjs`
  - Node test for metadata-only index generation.
- `scripts/tests/validate-registry.test.mjs`
  - Node test for registry validation rules.
- `.github/workflows/deploy-site.yml`
  - GitHub Pages deployment workflow; retarget to `site-first`.
- `.github/workflows/validate.yml`
  - New validation workflow for registry, site, and installer checks.
- `.github/workflows/check-updates.yml`
  - Delete from the `site-first` branch.
- `README.md`, `README_en.md`, `QUICKSTART.md`, `forge.yaml`
  - Update to describe the `site-first` branch as the public line and `master` as the legacy line.
- `.gitmodules`
  - Remove from the `site-first` branch.
- `skills/scientific-agent-skills`, `skills/AI-research-SKILLs`, `skills/humanizer`, `skills/humanizer-zh`, `skills/paper-polish-workflow-skill`, `skills/superpowers`
  - Remove from the `site-first` branch.

## Preflight Branch Setup

- [ ] **Step 1: Create the `site-first` branch from the agreed commit**

```bash
git switch -c site-first a259d1f93c047c404c22111670fa7ae32727b1d4
```

- [ ] **Step 2: Push the branch and set upstream before branch-pinned installs rely on it**

```bash
git push -u origin site-first
```

- [ ] **Step 3: Verify the branch baseline**

Run: `git branch --show-current && git rev-parse HEAD && git status --short`
Expected:
- first line is `site-first`
- second line starts with `a259d1f` or a descendant commit once work begins
- status is empty before implementation starts

### Task 1: Branch-Aware Site Command Builder

**Files:**
- Create: `site/src/lib/install-command.mjs`
- Create: `site/src/lib/install-command.test.mjs`
- Modify: `site/src/lib/registry.ts`
- Modify: `site/src/components/Configurator.astro`
- Modify: `site/src/components/InstallGuide.astro`

- [ ] **Step 1: Write the failing site command test**

```js
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
      'curl -sSL https://raw.githubusercontent.com/HughYau/AcademicForge/refs/heads/site-first/scripts/forge-install.sh | bash -s -- \\\',
      '  --tool opencode \\\',
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
```

- [ ] **Step 2: Run the test to prove the helper does not exist yet**

Run: `node --test site/src/lib/install-command.test.mjs`
Expected: FAIL with `ERR_MODULE_NOT_FOUND` for `site/src/lib/install-command.mjs`

- [ ] **Step 3: Add the shared install command helper and registry type support**

`site/src/lib/install-command.mjs`

```js
export const ACADEMIC_FORGE_BRANCH = 'site-first';
export const SCRIPT_BASE = `https://raw.githubusercontent.com/HughYau/AcademicForge/refs/heads/${ACADEMIC_FORGE_BRANCH}/scripts`;

export const TOOL_PATHS = {
  claude: { linux: '.claude/skills', windows: '.claude\\skills' },
  opencode: { linux: '.opencode/skills', windows: '.opencode\\skills' },
  codex: { linux: '.codex/skills', windows: '.codex\\skills' },
};

export function getToolPath({ platform = 'linux', tool = 'claude' }) {
  const toolPaths = TOOL_PATHS[tool] ?? TOOL_PATHS.claude;
  return platform === 'windows' ? toolPaths.windows : toolPaths.linux;
}

export function buildInstallCommand({ platform = 'linux', tool = 'claude', skillIds = [] }) {
  const skillList = skillIds.join(',');

  if (platform === 'windows') {
    return [
      "$script = Join-Path $PWD 'forge-install.ps1'",
      `Invoke-WebRequest -Uri '${SCRIPT_BASE}/forge-install.ps1' -OutFile $script`,
      `& $script -Tool ${tool} -Skills '${skillList}'`,
      'Remove-Item $script',
    ].join('\n');
  }

  return [
    `curl -sSL ${SCRIPT_BASE}/forge-install.sh | bash -s -- \\\`,
    `  --tool ${tool} \\\`,
    `  --skills ${skillList}`,
  ].join('\n');
}

export function buildVerifyCommand({ platform = 'linux', tool = 'claude' }) {
  const toolPath = getToolPath({ platform, tool });
  return platform === 'windows' ? `dir ${toolPath}` : `ls ${toolPath}/`;
}
```

`site/src/lib/registry.ts`

```ts
export interface InstallRecord {
  method: string;
  url: string;
  ref?: string;
  sparse_path?: string;
}
```

- [ ] **Step 4: Replace duplicated command construction in the two Astro components**

At the top of both browser scripts, import the shared helper:

```astro
<script>
  import {
    SCRIPT_BASE,
    TOOL_PATHS,
    buildInstallCommand,
    buildVerifyCommand,
    getToolPath,
  } from '../lib/install-command.mjs';
```

In `site/src/components/Configurator.astro`, replace the local command builder block with:

```js
    const installCommand = selected.length === 0
      ? (isWindows ? translations[locale].commandEmptyWindows : translations[locale].commandEmptyLinux)
      : buildInstallCommand({
          platform,
          tool,
          skillIds: selected.map((checkbox) => checkbox.dataset.skillId ?? '').filter(Boolean),
        });
    const verifyCommand = buildVerifyCommand({ platform, tool });
```

In `site/src/components/InstallGuide.astro`, replace the local command builder block with:

```js
    const installCommand = buildInstallCommand({
      platform,
      tool,
      skillIds: skills,
    });
    const verifyCommand = buildVerifyCommand({ platform, tool });
    const skillPath = getToolPath({ platform, tool });
```

- [ ] **Step 5: Re-run the unit test and the Astro build**

Run: `node --test site/src/lib/install-command.test.mjs && npm run build`
Expected:
- `3` tests pass in `install-command.test.mjs`
- `npm run build` succeeds and writes `site/dist`

- [ ] **Step 6: Commit the site command builder work**

```bash
git add site/src/lib/install-command.mjs site/src/lib/install-command.test.mjs site/src/lib/registry.ts site/src/components/Configurator.astro site/src/components/InstallGuide.astro
git commit -m "feat: retarget site install commands to the site-first branch"
```

### Task 2: Bash Installer Local Registry and Branch Pinning

**Files:**
- Create: `scripts/tests/forge-install-local-registry.sh`
- Modify: `scripts/forge-install.sh`

- [ ] **Step 1: Write the failing Bash smoke test**

`scripts/tests/forge-install-local-registry.sh`

```bash
#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
TMP_DIR="$(mktemp -d "${TMPDIR:-/tmp}/forge-install-test.XXXXXX")"
REGISTRY_FILE="$TMP_DIR/registry.json"
OUTPUT_DIR="$TMP_DIR/output"

cleanup() {
  rm -rf "$TMP_DIR"
}

trap cleanup EXIT

cat > "$REGISTRY_FILE" <<JSON
{
  "skills": [
    {
      "id": "scientific-visualization",
      "name": "Scientific Visualization",
      "summary": { "en": "local test", "zh": "local test" },
      "author": "AcademicForge",
      "repository": "https://github.com/HughYau/AcademicForge",
      "license": "MIT",
      "skill_count": 1,
      "stars": 0,
      "tags": ["visualization"],
      "install": {
        "method": "sparse-checkout",
        "url": "$REPO_ROOT",
        "ref": "site-first",
        "sparse_path": "skills/scientific-visualization"
      },
      "post_install": []
    }
  ]
}
JSON

bash "$REPO_ROOT/scripts/forge-install.sh" \
  --tool opencode \
  --skills scientific-visualization \
  --registry "$REGISTRY_FILE" \
  --path "$OUTPUT_DIR"

test -f "$OUTPUT_DIR/scientific-visualization/SKILL.md"
```

- [ ] **Step 2: Run the Bash smoke test to prove `--registry` is missing**

Run: `bash scripts/tests/forge-install-local-registry.sh`
Expected: FAIL with `Unknown option: --registry`

- [ ] **Step 3: Add `--registry` and `install.ref` to the Bash installer**

At the top of `scripts/forge-install.sh`, replace the registry configuration block with:

```bash
TOOL=""
SKILLS=""
INSTALL_PATH=""
REGISTRY_SOURCE="${FORGE_REGISTRY_URL:-https://raw.githubusercontent.com/HughYau/AcademicForge/refs/heads/site-first/registry/skills.json}"
REGISTRY_FILE=""
```

Add a `--registry` option to argument parsing:

```bash
    --registry)
      [[ $# -ge 2 ]] || {
        echo -e "${RED}Error: --registry requires a value${NC}"
        exit 1
      }
      REGISTRY_SOURCE="$2"
      shift 2
      ;;
```

Replace the registry download block with local-file support:

```bash
echo -e "${BLUE}Loading skill registry...${NC}"
case "$REGISTRY_SOURCE" in
  http://*|https://*)
    curl -fsSL "$REGISTRY_SOURCE" -o "$REGISTRY_FILE"
    ;;
  *)
    if [[ ! -f "$REGISTRY_SOURCE" ]]; then
      echo -e "${RED}Error: registry file '$REGISTRY_SOURCE' does not exist${NC}"
      exit 1
    fi
    cp "$REGISTRY_SOURCE" "$REGISTRY_FILE"
    ;;
esac
echo -e "${GREEN}Registry loaded.${NC}"
```

Inside the install loop, read `install.ref` and pass it to git:

```bash
  REF="$(json_extract "$sid" "install.ref" 2>/dev/null || true)"
```

```bash
      clone_args=(clone --depth 1)
      [[ -n "$REF" ]] && clone_args+=(--branch "$REF")
      clone_args+=("$URL" "$TARGET")
      if git "${clone_args[@]}" >/dev/null 2>&1; then
```

```bash
      clone_args=(clone --depth 1 --filter=blob:none --sparse)
      [[ -n "$REF" ]] && clone_args+=(--branch "$REF")
      clone_args+=("$URL" "$TMPDIR")
      if git "${clone_args[@]}" >/dev/null 2>&1; then
```

- [ ] **Step 4: Re-run the Bash smoke test**

Run: `bash scripts/tests/forge-install-local-registry.sh`
Expected:
- installer prints `Installing: scientific-visualization`
- summary shows `OK  scientific-visualization`
- the script exits `0`

- [ ] **Step 5: Commit the Bash installer changes**

```bash
git add scripts/forge-install.sh scripts/tests/forge-install-local-registry.sh
git commit -m "feat: add local registry support to the bash installer"
```

### Task 3: PowerShell Installer Local Registry and Branch Pinning

**Files:**
- Create: `scripts/tests/forge-install-local-registry.ps1`
- Modify: `scripts/forge-install.ps1`

- [ ] **Step 1: Write the failing PowerShell smoke test**

`scripts/tests/forge-install-local-registry.ps1`

```powershell
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$RepoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
$TempRoot = Join-Path ([System.IO.Path]::GetTempPath()) ('forge-install-test-' + [System.Guid]::NewGuid().ToString('N'))
$RegistryPath = Join-Path $TempRoot 'registry.json'
$OutputPath = Join-Path $TempRoot 'output'

New-Item -ItemType Directory -Path $TempRoot | Out-Null

try {
    @"
{
  ""skills"": [
    {
      ""id"": ""scientific-visualization"",
      ""name"": ""Scientific Visualization"",
      ""summary"": { ""en"": ""local test"", ""zh"": ""local test"" },
      ""author"": ""AcademicForge"",
      ""repository"": ""https://github.com/HughYau/AcademicForge"",
      ""license"": ""MIT"",
      ""skill_count"": 1,
      ""stars"": 0,
      ""tags"": [""visualization""],
      ""install"": {
        ""method"": ""sparse-checkout"",
        ""url"": "$RepoRoot",
        ""ref"": ""site-first"",
        ""sparse_path"": ""skills/scientific-visualization""
      },
      ""post_install"": []
    }
  ]
}
"@ | Set-Content -LiteralPath $RegistryPath -Encoding UTF8

    & (Join-Path $RepoRoot 'scripts\forge-install.ps1') `
        -Tool opencode `
        -Skills 'scientific-visualization' `
        -Registry $RegistryPath `
        -Path $OutputPath

    if (-not (Test-Path -LiteralPath (Join-Path $OutputPath 'scientific-visualization\SKILL.md'))) {
        throw 'scientific-visualization did not install into the output path'
    }
}
finally {
    if (Test-Path -LiteralPath $TempRoot) {
        Remove-Item -LiteralPath $TempRoot -Recurse -Force
    }
}
```

- [ ] **Step 2: Run the PowerShell smoke test to prove `-Registry` is missing**

Run: `pwsh -File scripts/tests/forge-install-local-registry.ps1`
Expected: FAIL with a parameter binding error because `-Registry` is not defined yet

- [ ] **Step 3: Add `-Registry` and `install.ref` to the PowerShell installer**

Update the parameter block in `scripts/forge-install.ps1`:

```powershell
param(
    [string]$Tool = "",
    [string]$Skills = "",
    [string]$Path = "",
    [string]$Registry = "",
    [switch]$Help
)
```

Replace the registry URL default with a branch-aware source variable:

```powershell
$RegistrySource = if ($Registry) {
    $Registry
} elseif ($env:FORGE_REGISTRY_URL) {
    $env:FORGE_REGISTRY_URL
} else {
    'https://raw.githubusercontent.com/HughYau/AcademicForge/refs/heads/site-first/registry/skills.json'
}
```

Replace the registry loading block with local-file support:

```powershell
Write-Host 'Loading skill registry...' -ForegroundColor Blue
if (Test-Path -LiteralPath $RegistrySource) {
    Copy-Item -LiteralPath $RegistrySource -Destination $registryFile -Force
} else {
    Invoke-WebRequest -Uri $RegistrySource -OutFile $registryFile
}
$registry = Get-Content -LiteralPath $registryFile -Raw -Encoding UTF8 | ConvertFrom-Json
Write-Host 'Registry loaded.' -ForegroundColor Green
```

Inside the install loop, capture and honor `install.ref`:

```powershell
$gitArgs = @('clone', '--depth', '1')
if ($skill.install.PSObject.Properties.Name -contains 'ref' -and $skill.install.ref) {
    $gitArgs += @('--branch', $skill.install.ref)
}
$gitArgs += @($skill.install.url, $target)
$exitCode = Invoke-GitQuiet @gitArgs
```

```powershell
$cloneArgs = @('clone', '--depth', '1', '--filter=blob:none', '--sparse')
if ($skill.install.PSObject.Properties.Name -contains 'ref' -and $skill.install.ref) {
    $cloneArgs += @('--branch', $skill.install.ref)
}
$cloneArgs += @($skill.install.url, $tmpDir)
$cloneExitCode = Invoke-GitQuiet @cloneArgs
```

- [ ] **Step 4: Re-run the PowerShell smoke test**

Run: `pwsh -File scripts/tests/forge-install-local-registry.ps1`
Expected:
- installer prints `Installing: scientific-visualization`
- summary shows `OK  scientific-visualization`
- the script exits `0`

- [ ] **Step 5: Commit the PowerShell installer changes**

```bash
git add scripts/forge-install.ps1 scripts/tests/forge-install-local-registry.ps1
git commit -m "feat: add local registry support to the powershell installer"
```

### Task 4: Metadata-Only Skill Index Generation

**Files:**
- Create: `scripts/lib/skill-index.mjs`
- Create: `scripts/tests/build-skill-index.test.mjs`
- Modify: `scripts/build-skill-index.mjs`
- Modify: `scripts/skill-classification.json`
- Delete: `scripts/skill-blacklist.txt`

- [ ] **Step 1: Write the failing metadata index test**

`scripts/tests/build-skill-index.test.mjs`

```js
import test from 'node:test';
import assert from 'node:assert/strict';
import { mkdtempSync, mkdirSync, writeFileSync, rmSync } from 'node:fs';
import { join } from 'node:path';
import { tmpdir } from 'node:os';

import { collectSubSkills } from '../lib/skill-index.mjs';

test('collectSubSkills skips disabled entries and preserves install.ref', () => {
  const rootDir = mkdtempSync(join(tmpdir(), 'skill-index-'));

  try {
    mkdirSync(join(rootDir, 'scientific-skills', 'demo-one'), { recursive: true });
    writeFileSync(
      join(rootDir, 'scientific-skills', 'demo-one', 'SKILL.md'),
      ['---', 'name: demo-one', 'description: Demo one', 'license: MIT', 'tags: [demo]', '---'].join('\n'),
      'utf8',
    );

    mkdirSync(join(rootDir, 'scientific-skills', 'skip-me'), { recursive: true });
    writeFileSync(
      join(rootDir, 'scientific-skills', 'skip-me', 'SKILL.md'),
      ['---', 'name: skip-me', 'description: Skip me', 'license: MIT', '---'].join('\n'),
      'utf8',
    );

    const subSkills = collectSubSkills({
      rootDir,
      includeRootSkill: false,
      prefix: 'sa',
      relativeRoot: 'scientific-skills',
      parentSkill: {
        install: {
          method: 'sparse-checkout',
          url: 'https://github.com/K-Dense-AI/scientific-agent-skills.git',
          ref: 'main',
        },
        post_install: ['clean_ads'],
      },
      classification: {
        'sa.demo-one': { category: 'research', subdiscipline: 'life-sci' },
        'sa.skip-me': { category: 'research', disabled: true },
      },
    });

    assert.equal(subSkills.length, 1);
    assert.equal(subSkills[0].id, 'sa.demo-one');
    assert.equal(subSkills[0].install.ref, 'main');
    assert.equal(subSkills[0].sparse_path, 'scientific-skills/demo-one');
  } finally {
    rmSync(rootDir, { recursive: true, force: true });
  }
});
```

- [ ] **Step 2: Run the test to prove the helper module does not exist yet**

Run: `node --test scripts/tests/build-skill-index.test.mjs`
Expected: FAIL with `ERR_MODULE_NOT_FOUND` for `scripts/lib/skill-index.mjs`

- [ ] **Step 3: Add the reusable metadata scan helper**

`scripts/lib/skill-index.mjs`

```js
import { execFileSync } from 'node:child_process';
import { mkdtempSync, readdirSync, readFileSync, rmSync } from 'node:fs';
import { tmpdir } from 'node:os';
import { basename, dirname, join, relative, resolve } from 'node:path';

const stripQuotes = (value) => value.replace(/^['"]|['"]$/g, '').trim();

const parseInlineArray = (value) => value.trim().slice(1, -1).split(',').map((item) => stripQuotes(item.trim())).filter(Boolean);

export const parseFrontmatter = (content, filePath) => {
  const match = content.match(/^---\r?\n([\s\S]*?)\r?\n---/);
  if (!match) {
    throw new Error(`Missing frontmatter in ${filePath}`);
  }

  const fields = {};
  match[1].split(/\r?\n/).forEach((line) => {
    if (!line || /^\s/.test(line) || !line.includes(':')) {
      return;
    }

    const index = line.indexOf(':');
    fields[line.slice(0, index).trim()] = line.slice(index + 1).trim();
  });

  return {
    name: fields.name ? stripQuotes(fields.name) : '',
    description: fields.description ? stripQuotes(fields.description) : '',
    license: fields.license ? stripQuotes(fields.license) : '',
    tags: fields.tags && fields.tags.startsWith('[') ? parseInlineArray(fields.tags) : [],
  };
};

const walkSkillFiles = (rootDir) => {
  const files = [];
  const walk = (dirPath) => {
    for (const entry of readdirSync(dirPath, { withFileTypes: true })) {
      if (entry.name === '.git') continue;
      const fullPath = resolve(dirPath, entry.name);
      if (entry.isDirectory()) {
        walk(fullPath);
      } else if (entry.isFile() && entry.name === 'SKILL.md') {
        files.push(fullPath);
      }
    }
  };
  walk(rootDir);
  return files.sort((left, right) => left.localeCompare(right));
};

export const collectSubSkills = ({ rootDir, includeRootSkill, prefix, relativeRoot, parentSkill, classification }) => {
  return walkSkillFiles(rootDir)
    .filter((filePath) => {
      const relativePath = relative(rootDir, filePath).replace(/\\/g, '/');
      const depth = relativePath.split('/').length;
      return includeRootSkill ? depth >= 2 : depth >= 3;
    })
    .flatMap((filePath) => {
      const frontmatter = parseFrontmatter(readFileSync(filePath, 'utf8'), filePath);
      const relativeDir = relative(rootDir, dirname(filePath)).replace(/\\/g, '/');
      const displayName = prefix === 'air' && /^\d/.test(basename(relativeDir))
        ? (frontmatter.name || basename(relativeDir).replace(/^\d+-?/, ''))
        : basename(relativeDir);
      const id = `${prefix}.${displayName}`;
      const classificationEntry = classification[id];

      if (!classificationEntry || classificationEntry.disabled === true) {
        return [];
      }

      return [{
        id,
        name: displayName,
        summary: { en: frontmatter.description, zh: frontmatter.description },
        sparse_path: `${relativeRoot}/${relativeDir}`,
        category: classificationEntry.category,
        ...(Object.prototype.hasOwnProperty.call(classificationEntry, 'subdiscipline') ? { subdiscipline: classificationEntry.subdiscipline } : {}),
        ...(frontmatter.tags.length > 0 ? { tags: frontmatter.tags } : {}),
        ...(frontmatter.license ? { license: frontmatter.license } : {}),
        install: {
          method: 'sparse-checkout',
          url: parentSkill.install.url,
          ...(parentSkill.install.ref ? { ref: parentSkill.install.ref } : {}),
          sparse_path: `${relativeRoot}/${relativeDir}`,
        },
        post_install: parentSkill.post_install ?? [],
      }];
    });
};

export const withSparseClone = ({ url, ref, sparsePath }, callback) => {
  const tempDir = mkdtempSync(join(tmpdir(), 'skill-source-'));

  try {
    const cloneArgs = ['clone', '--depth', '1', '--filter=blob:none', '--sparse'];
    if (ref) cloneArgs.push('--branch', ref);
    cloneArgs.push(url, tempDir);
    execFileSync('git', cloneArgs, { stdio: 'ignore' });
    execFileSync('git', ['-C', tempDir, 'sparse-checkout', 'set', sparsePath], { stdio: 'ignore' });
    return callback(tempDir);
  } finally {
    rmSync(tempDir, { recursive: true, force: true });
  }
};
```

- [ ] **Step 4: Rework the index builder to use temporary clones and retire the blacklist file**

Update `scripts/build-skill-index.mjs` to use the helper module:

```js
import { readFileSync, writeFileSync } from 'node:fs';
import { resolve } from 'node:path';

import { collectSubSkills, withSparseClone } from './lib/skill-index.mjs';

const repoRoot = resolve(import.meta.dirname, '..');
const registryPath = resolve(repoRoot, 'registry/skills.json');
const classificationPath = resolve(repoRoot, 'scripts/skill-classification.json');

const collections = [
  { rootSkillId: 'scientific-agent-skills', prefix: 'sa', sparseRoot: 'scientific-skills', includeRootSkill: false },
  { rootSkillId: 'AI-research-SKILLs', prefix: 'air', sparseRoot: '.', includeRootSkill: true },
];

const args = new Set(process.argv.slice(2));
const checkOnly = args.has('--check');
const classification = JSON.parse(readFileSync(classificationPath, 'utf8'));
const registry = JSON.parse(readFileSync(registryPath, 'utf8'));

for (const collection of collections) {
  const parentSkill = registry.skills.find((skill) => skill.id === collection.rootSkillId);
  if (!parentSkill) throw new Error(`Registry entry '${collection.rootSkillId}' not found.`);

  const sparsePath = collection.sparseRoot === '.' ? '.' : collection.sparseRoot;
  const subSkills = withSparseClone(
    {
      url: parentSkill.install.url,
      ref: parentSkill.install.ref,
      sparsePath,
    },
    (cloneRoot) => collectSubSkills({
      rootDir: sparsePath === '.' ? cloneRoot : resolve(cloneRoot, sparsePath),
      includeRootSkill: collection.includeRootSkill,
      prefix: collection.prefix,
      relativeRoot: collection.sparseRoot === '.' ? '' : collection.sparseRoot,
      parentSkill,
      classification,
    }),
  );

  parentSkill.skill_count = subSkills.length;
  parentSkill.is_collection = true;
  parentSkill.sub_skills = subSkills;
}

if (!checkOnly) {
  writeFileSync(registryPath, `${JSON.stringify(registry, null, 2)}\n`, 'utf8');
}
```

Add a disabled entry example in `scripts/skill-classification.json` using the existing object shape:

```json
"sa.parallel-web": { "category": "research", "disabled": true }
```

Delete the blacklist file from the `site-first` branch:

```bash
git rm scripts/skill-blacklist.txt
```

- [ ] **Step 5: Re-run the helper test and the index check mode**

Run: `node --test scripts/tests/build-skill-index.test.mjs && node scripts/build-skill-index.mjs --check`
Expected:
- the Node test passes
- the script prints collection counts without requiring checked-in mirror directories

- [ ] **Step 6: Commit the metadata-only index generator changes**

```bash
git add scripts/lib/skill-index.mjs scripts/tests/build-skill-index.test.mjs scripts/build-skill-index.mjs scripts/skill-classification.json
git commit -m "refactor: generate skill indexes from temporary upstream clones"
```

### Task 5: Registry Validation and Branch-Scoped CI

**Files:**
- Create: `scripts/validate-registry.mjs`
- Create: `scripts/tests/validate-registry.test.mjs`
- Create: `.github/workflows/validate.yml`
- Modify: `package.json`
- Modify: `.github/workflows/deploy-site.yml`
- Delete: `.github/workflows/check-updates.yml`

- [ ] **Step 1: Write the failing registry validation test**

`scripts/tests/validate-registry.test.mjs`

```js
import test from 'node:test';
import assert from 'node:assert/strict';

import { validateRegistry } from '../validate-registry.mjs';

test('validateRegistry reports duplicate ids and invalid sparse installs', () => {
  const errors = validateRegistry({
    skills: [
      {
        id: 'duplicate',
        name: 'Duplicate A',
        summary: { en: 'A', zh: 'A' },
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
        summary: { en: 'B', zh: 'B' },
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
    "Duplicate skill id 'duplicate'",
    "Skill 'duplicate' uses sparse-checkout without install.sparse_path",
    "Skill 'duplicate' uses unsupported install.method 'download'",
  ]);
});
```

- [ ] **Step 2: Run the validator test to prove the module does not exist yet**

Run: `node --test scripts/tests/validate-registry.test.mjs`
Expected: FAIL with `ERR_MODULE_NOT_FOUND` for `scripts/validate-registry.mjs`

- [ ] **Step 3: Implement registry validation and root validation scripts**

`scripts/validate-registry.mjs`

```js
import { existsSync, readFileSync } from 'node:fs';
import { resolve } from 'node:path';

export function validateRegistry(registry, { repoRoot }) {
  const errors = [];
  const seenIds = new Set();

  const visit = (record) => {
    if (seenIds.has(record.id)) {
      errors.push(`Duplicate skill id '${record.id}'`);
    }
    seenIds.add(record.id);

    const method = record.install?.method;
    if (!['git-clone', 'sparse-checkout'].includes(method)) {
      errors.push(`Skill '${record.id}' uses unsupported install.method '${method}'`);
    }
    if (method === 'sparse-checkout' && !record.install?.sparse_path) {
      errors.push(`Skill '${record.id}' uses sparse-checkout without install.sparse_path`);
    }
    if (record.id === 'scientific-visualization') {
      const localPath = resolve(repoRoot, 'skills/scientific-visualization');
      if (!existsSync(localPath)) {
        errors.push("Local pack 'scientific-visualization' is missing from skills/scientific-visualization");
      }
    }
  };

  for (const skill of registry.skills ?? []) {
    visit(skill);
    for (const subSkill of skill.sub_skills ?? []) {
      visit(subSkill);
    }
  }

  return errors;
}

if (process.argv[1] === new URL(import.meta.url).pathname) {
  const repoRoot = resolve(import.meta.dirname, '..');
  const registry = JSON.parse(readFileSync(resolve(repoRoot, 'registry/skills.json'), 'utf8'));
  const errors = validateRegistry(registry, { repoRoot });
  if (errors.length > 0) {
    errors.forEach((error) => console.error(error));
    process.exit(1);
  }
  console.log('Registry validation passed.');
}
```

Update `package.json` scripts:

```json
{
  "name": "academicforge",
  "private": true,
  "version": "0.1.0",
  "scripts": {
    "dev": "npm --prefix site run dev --",
    "build": "npm --prefix site run build --",
    "preview": "npm --prefix site run preview --",
    "site:install": "npm --prefix site install",
    "validate:registry": "node scripts/validate-registry.mjs",
    "test:site": "node --test site/src/lib/install-command.test.mjs",
    "test:scripts": "node --test scripts/tests/build-skill-index.test.mjs scripts/tests/validate-registry.test.mjs",
    "test": "npm run test:site && npm run test:scripts",
    "ci:validate": "npm run validate:registry && npm run test && npm run build"
  }
}
```

- [ ] **Step 4: Add branch-scoped validation CI and retarget Pages deployment**

`.github/workflows/validate.yml`

```yaml
name: Validate Site-First Branch

on:
  push:
    branches: [site-first]
    paths:
      - 'registry/**'
      - 'scripts/**'
      - 'site/**'
      - 'skills/scientific-visualization/**'
      - 'package.json'
  pull_request:
    branches: [site-first]
    paths:
      - 'registry/**'
      - 'scripts/**'
      - 'site/**'
      - 'skills/scientific-visualization/**'
      - 'package.json'

jobs:
  validate:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-node@v4
        with:
          node-version: 20
          cache: npm
          cache-dependency-path: site/package-lock.json
      - run: npm ci --prefix site
      - run: npm run ci:validate
      - run: bash scripts/tests/forge-install-local-registry.sh
```

Modify `.github/workflows/deploy-site.yml` trigger block:

```yaml
on:
  push:
    branches: [site-first]
    paths:
      - 'site/**'
      - 'registry/**'
  workflow_dispatch:
```

Remove the legacy mirror updater from this branch:

```bash
git rm .github/workflows/check-updates.yml
```

- [ ] **Step 5: Re-run local validation before committing**

Run: `npm run validate:registry && node --test scripts/tests/validate-registry.test.mjs && npm run ci:validate`
Expected:
- validator test passes
- registry validation prints `Registry validation passed.`
- full local validation ends with a successful Astro build

- [ ] **Step 6: Commit the validation and workflow changes**

```bash
git add package.json scripts/validate-registry.mjs scripts/tests/validate-registry.test.mjs .github/workflows/validate.yml .github/workflows/deploy-site.yml
git commit -m "ci: validate and deploy the site-first branch"
```

### Task 6: Remove Mirror-Era Files from the `site-first` Branch

**Files:**
- Delete: `.gitmodules`
- Delete: `scripts/install.sh`
- Delete: `scripts/install.ps1`
- Delete: `scripts/update.sh`
- Delete: `scripts/update.ps1`
- Delete: `scripts/download-skills.sh`
- Delete: `scripts/download-skills.ps1`
- Delete: `scripts/lib.sh`
- Delete: `scripts/lib.ps1`
- Delete: `scripts/uninstall.sh`
- Delete: `scripts/uninstall.ps1`
- Delete: `scripts/SKILLS-DOWNLOAD-README.md`
- Delete: `scripts/list-skills.sh`
- Delete: `scripts/list-skills.ps1`
- Delete: `scripts/verify.sh`
- Delete: `scripts/verify.ps1`
- Delete: `skills/scientific-agent-skills`
- Delete: `skills/AI-research-SKILLs`
- Delete: `skills/humanizer`
- Delete: `skills/humanizer-zh`
- Delete: `skills/paper-polish-workflow-skill`
- Delete: `skills/superpowers`

- [ ] **Step 1: Remove the branch-local mirror files**

```bash
git rm .gitmodules \
  scripts/install.sh scripts/install.ps1 \
  scripts/update.sh scripts/update.ps1 \
  scripts/download-skills.sh scripts/download-skills.ps1 \
  scripts/lib.sh scripts/lib.ps1 \
  scripts/uninstall.sh scripts/uninstall.ps1 \
  scripts/SKILLS-DOWNLOAD-README.md \
  scripts/list-skills.sh scripts/list-skills.ps1 \
  scripts/verify.sh scripts/verify.ps1
```

- [ ] **Step 2: Remove the checked-in upstream mirrors but keep `scientific-visualization`**

```bash
git rm -r skills/scientific-agent-skills skills/AI-research-SKILLs skills/humanizer skills/humanizer-zh skills/paper-polish-workflow-skill skills/superpowers
```

- [ ] **Step 3: Verify only the local pack remains under `skills/`**

Run: `python -c "from pathlib import Path; print([p.name for p in Path('skills').iterdir() if p.is_dir()])"`
Expected: `['scientific-visualization']`

- [ ] **Step 4: Re-run validation after the deletions**

Run: `npm run ci:validate`
Expected: PASS without relying on deleted mirror files

- [ ] **Step 5: Commit the branch cleanup**

```bash
git add -A
git commit -m "refactor: remove mirror-era files from the site-first branch"
```

### Task 7: Rewrite Docs and Forge Metadata for the Two-Line Model

**Files:**
- Modify: `README.md`
- Modify: `README_en.md`
- Modify: `QUICKSTART.md`
- Modify: `forge.yaml`
- Modify: `registry/skills.json`

- [ ] **Step 1: Update the local pack entry so installs pin to the `site-first` branch**

In `registry/skills.json`, change the `scientific-visualization` install block to:

```json
"install": {
  "method": "sparse-checkout",
  "url": "https://github.com/HughYau/AcademicForge.git",
  "ref": "site-first",
  "sparse_path": "skills/scientific-visualization"
}
```

- [ ] **Step 2: Rewrite the branch ownership text in the main README files**

At the top of both `README.md` and `README_en.md`, insert a branch notice block:

```md
> Branch model:
> - `master` keeps the legacy AcademicForge repository layout for backward compatibility.
> - `site-first` is the public website branch and the source for the GitHub Pages configurator, `registry/skills.json`, and the new installer flow.
```

Replace any `raw.githubusercontent.com/.../refs/heads/master/...` installer examples with the `site-first` branch:

```md
curl -sSL https://raw.githubusercontent.com/HughYau/AcademicForge/refs/heads/site-first/scripts/forge-install.sh | bash -s -- \
  --tool claude \
  --skills humanizer,superpowers
```

```powershell
$script = Join-Path $PWD 'forge-install.ps1'
Invoke-WebRequest -Uri 'https://raw.githubusercontent.com/HughYau/AcademicForge/refs/heads/site-first/scripts/forge-install.ps1' -OutFile $script
& $script -Tool claude -Skills 'humanizer,superpowers'
Remove-Item $script
```

- [ ] **Step 3: Remove legacy maintenance instructions from `QUICKSTART.md` and simplify `forge.yaml`**

In `QUICKSTART.md`, replace the old maintenance section with:

```md
## 6. Repository lines

- `site-first`: the public configurator branch and the source for the installer registry
- `master`: the legacy compatibility branch

If you are working on the public website, use the `site-first` branch and validate with:

- `npm run build`
- `npm run preview`
```

In `forge.yaml`, remove the mirror-era update semantics and keep only service metadata, for example:

```yaml
update:
  method: "site-first-catalog"
  commands:
    - "node scripts/build-skill-index.mjs"
    - "node scripts/validate-registry.mjs"
```

- [ ] **Step 4: Verify the docs no longer point the public flow at `master` or submodules**

Run: `rg "refs/heads/master|git submodule|download-skills|update\.sh|update\.ps1" README.md README_en.md QUICKSTART.md forge.yaml`
Expected:
- no public installer examples point to `master`
- no doc section on the `site-first` branch tells contributors to run the mirror-era scripts

- [ ] **Step 5: Run the full validation pass one last time**

Run: `npm run ci:validate && npm run preview`
Expected:
- validation passes
- the preview server starts successfully for manual checking before push

- [ ] **Step 6: Commit the docs and metadata rewrite**

```bash
git add README.md README_en.md QUICKSTART.md forge.yaml registry/skills.json
git commit -m "docs: document the site-first branch as the public line"
```

## Self-Review Checklist

- Spec coverage:
  - branch split from `a259d1f...`: covered in Preflight Branch Setup
  - site/installers stop pointing at `master`: covered in Tasks 1, 2, 3, and 7
  - `install.ref`: covered in Tasks 2, 3, and 7
  - metadata-only index generation: covered in Task 4
  - registry validation and CI split: covered in Task 5
  - mirror cleanup on `site-first`: covered in Task 6
  - local testing and GitHub Pages release flow: covered by Tasks 1 through 7 plus validation commands
- Placeholder scan:
  - no `TODO`, `TBD`, or “similar to above” instructions remain
- Type consistency:
  - `install.ref`, `--registry`, and `-Registry` are used consistently throughout the plan
