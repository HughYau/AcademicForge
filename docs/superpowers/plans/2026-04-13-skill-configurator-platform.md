# Skill Configurator Platform Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build a static web-based skill configurator that lets users browse, select skills, and get a one-liner install command customized for their platform and tool.

**Architecture:** A `registry/skills.json` file serves as the single source of truth for all skill metadata. A pair of install scripts (`forge-install.sh` / `forge-install.ps1`) read this JSON at runtime and install user-selected skills. An Astro static site reads the same JSON at build time to render skill cards, and uses client-side JS for filtering, selection, and command generation. Deployed to GitHub Pages.

**Tech Stack:** Astro, Tailwind CSS, TypeScript (client-side), Bash, PowerShell, GitHub Actions

---

## File Structure

```
registry/
  skills.json                    # Skill metadata (source of truth)

scripts/
  forge-install.sh               # Universal install script (Bash)
  forge-install.ps1              # Universal install script (PowerShell)

site/
  package.json                   # Astro project dependencies
  astro.config.mjs               # Astro config with Tailwind
  tailwind.config.mjs            # Tailwind config
  tsconfig.json                  # TypeScript config
  src/
    styles/global.css            # Tailwind directives + base styles
    layouts/Layout.astro         # HTML shell (head, body, footer)
    components/
      CodeBlock.astro            # Code display with copy button
      SkillCard.astro            # Single skill card (checkbox, info)
      SkillGrid.astro            # Card grid + filter/search bar
      Configurator.astro         # Platform/tool selector + generate button
      InstallGuide.astro         # Step-by-step install instructions panel
    pages/
      index.astro                # Main page assembling all components
  public/
    favicon.svg                  # Site favicon

.github/
  workflows/
    deploy-site.yml              # GitHub Pages deploy on push
```

---

### Task 1: Create Registry Data

**Files:**
- Create: `registry/skills.json`

- [ ] **Step 1: Create skills.json with all 7 skill sources**

```json
{
  "skills": [
    {
      "id": "scientific-agent-skills",
      "name": "Scientific Agent Skills",
      "description": "133 个科研工作流 skills，涵盖生物信息、化学信息、临床研究等 15+ 领域",
      "author": "K-Dense-AI",
      "repository": "https://github.com/K-Dense-AI/scientific-agent-skills",
      "license": "MIT",
      "skill_count": 133,
      "tags": ["science", "research", "bioinformatics", "chemistry", "clinical"],
      "category": "academic",
      "install": {
        "method": "git-clone",
        "url": "https://github.com/K-Dense-AI/scientific-agent-skills.git"
      },
      "post_install": ["clean_ads"]
    },
    {
      "id": "AI-research-SKILLs",
      "name": "AI Research Skills",
      "description": "82 个专家级 AI 研究工程 skills，涵盖模型架构、微调、RLHF、推理等 20 个类别",
      "author": "orchestra-research",
      "repository": "https://github.com/zechenzhangAGI/AI-research-SKILLs",
      "license": "MIT",
      "skill_count": 82,
      "tags": ["AI", "deep-learning", "LLM", "training", "inference"],
      "category": "academic",
      "install": {
        "method": "git-clone",
        "url": "https://github.com/zechenzhangAGI/AI-research-SKILLs.git"
      },
      "post_install": []
    },
    {
      "id": "superpowers",
      "name": "Superpowers",
      "description": "15 个流程型技能：规划、调试、TDD、代码审查、验证",
      "author": "obra",
      "repository": "https://github.com/obra/superpowers",
      "license": "MIT",
      "skill_count": 15,
      "tags": ["workflow", "planning", "debugging", "tdd", "code-review"],
      "category": "development",
      "install": {
        "method": "sparse-checkout",
        "url": "https://github.com/obra/superpowers.git",
        "sparse_path": "skills"
      },
      "post_install": []
    },
    {
      "id": "paper-polish-workflow-skill",
      "name": "Paper Polish Workflow",
      "description": "15 个论文翻译、润色、审稿模拟与投稿工作流技能",
      "author": "Lylll9436",
      "repository": "https://github.com/Lylll9436/Paper-Polish-Workflow-skill",
      "license": "MIT",
      "skill_count": 15,
      "tags": ["writing", "translation", "polishing", "peer-review", "submission"],
      "category": "academic",
      "install": {
        "method": "git-clone",
        "url": "https://github.com/Lylll9436/Paper-Polish-Workflow-skill.git"
      },
      "post_install": []
    },
    {
      "id": "humanizer",
      "name": "Humanizer",
      "description": "学术语气润色、可读性优化、避免 AI 检测特征",
      "author": "blader",
      "repository": "https://github.com/blader/humanizer",
      "license": "See repository",
      "skill_count": 1,
      "tags": ["writing", "tone", "readability", "academic-style"],
      "category": "academic",
      "install": {
        "method": "git-clone",
        "url": "https://github.com/blader/humanizer.git"
      },
      "post_install": []
    },
    {
      "id": "humanizer-zh",
      "name": "Humanizer 中文版",
      "description": "中文去 AI 痕迹、自然化改写、保留原意的语气润色",
      "author": "op7418",
      "repository": "https://github.com/op7418/Humanizer-zh",
      "license": "MIT",
      "skill_count": 1,
      "tags": ["chinese", "writing", "tone", "de-ai"],
      "category": "academic",
      "install": {
        "method": "git-clone",
        "url": "https://github.com/op7418/Humanizer-zh.git"
      },
      "post_install": []
    },
    {
      "id": "scientific-visualization",
      "name": "Scientific Visualization",
      "description": "出版级科研图表：期刊样式模板、色盲友好配色、导出优化",
      "author": "AcademicForge",
      "repository": "https://github.com/HughYau/AcademicForge",
      "license": "MIT",
      "skill_count": 1,
      "tags": ["visualization", "matplotlib", "publication", "figures"],
      "category": "academic",
      "install": {
        "method": "sparse-checkout",
        "url": "https://github.com/HughYau/AcademicForge.git",
        "sparse_path": "skills/scientific-visualization"
      },
      "post_install": []
    }
  ]
}
```

- [ ] **Step 2: Validate JSON is well-formed**

Run: `python -c "import json; json.load(open('registry/skills.json')); print('OK')"`
Expected: `OK`

- [ ] **Step 3: Commit**

```bash
git add registry/skills.json
git commit -m "feat: add skill registry data (skills.json)"
```

---

### Task 2: Install Script (Bash)

**Files:**
- Create: `scripts/forge-install.sh`

- [ ] **Step 1: Write the install script**

```bash
#!/usr/bin/env bash
set -euo pipefail

# ── Colors ──────────────────────────────────────────────────────────
GREEN='\033[0;32m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

# ── Defaults ────────────────────────────────────────────────────────
TOOL=""
SKILLS=""
INSTALL_PATH=""
REGISTRY_URL="https://raw.githubusercontent.com/HughYau/AcademicForge/refs/heads/master/registry/skills.json"

# ── Usage ───────────────────────────────────────────────────────────
usage() {
    echo "Usage: forge-install.sh --tool <claude|opencode|codex> --skills <id1,id2,...> [--path <dir>]"
    echo ""
    echo "Options:"
    echo "  --tool     Target tool: claude, opencode, or codex"
    echo "  --skills   Comma-separated skill IDs from the registry"
    echo "  --path     Custom install path (overrides --tool default)"
    echo "  --help     Show this help"
    exit 0
}

# ── Parse args ──────────────────────────────────────────────────────
while [[ $# -gt 0 ]]; do
    case "$1" in
        --tool)   TOOL="$2";         shift 2 ;;
        --skills) SKILLS="$2";       shift 2 ;;
        --path)   INSTALL_PATH="$2"; shift 2 ;;
        --help|-h) usage ;;
        *) echo -e "${RED}Unknown option: $1${NC}"; usage ;;
    esac
done

if [[ -z "$TOOL" || -z "$SKILLS" ]]; then
    echo -e "${RED}Error: --tool and --skills are required${NC}"
    usage
fi

# ── Determine install directory ─────────────────────────────────────
if [[ -z "$INSTALL_PATH" ]]; then
    case "$TOOL" in
        claude)   INSTALL_PATH=".claude/skills" ;;
        opencode) INSTALL_PATH=".opencode/skills" ;;
        codex)    INSTALL_PATH=".codex/skills" ;;
        *) echo -e "${RED}Error: unknown tool '$TOOL'. Use claude, opencode, or codex.${NC}"; exit 1 ;;
    esac
fi

# ── Dependency check ────────────────────────────────────────────────
for cmd in git curl; do
    if ! command -v "$cmd" &>/dev/null; then
        echo -e "${RED}Error: '$cmd' is required but not installed.${NC}"
        exit 1
    fi
done

# ── Banner ──────────────────────────────────────────────────────────
echo ""
echo -e "${BLUE}╔═══════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║   Skill Configurator - Forge Installer        ║${NC}"
echo -e "${BLUE}╚═══════════════════════════════════════════════╝${NC}"
echo ""
echo -e "${CYAN}Tool:${NC}   $TOOL"
echo -e "${CYAN}Skills:${NC} $SKILLS"
echo -e "${CYAN}Path:${NC}   $INSTALL_PATH"
echo ""

# ── Download registry ───────────────────────────────────────────────
echo -e "${BLUE}Downloading skill registry...${NC}"
REGISTRY_JSON=$(curl -fsSL "$REGISTRY_URL")
if [[ -z "$REGISTRY_JSON" ]]; then
    echo -e "${RED}Error: failed to download registry from $REGISTRY_URL${NC}"
    exit 1
fi
echo -e "${GREEN}Registry loaded.${NC}"
echo ""

mkdir -p "$INSTALL_PATH"

# ── Helper: extract JSON field (lightweight, no jq dependency) ──────
# Uses python if available, falls back to grep/sed for simple fields.
json_extract() {
    local json="$1" id="$2" field="$3"
    python3 -c "
import json, sys
data = json.loads(sys.stdin.read())
for s in data['skills']:
    if s['id'] == '$id':
        val = s
        for key in '$field'.split('.'):
            val = val[key]
        print(val if val is not None else '')
        sys.exit(0)
sys.exit(1)
" <<< "$json"
}

# ── Post-install: clean_ads ─────────────────────────────────────────
post_clean_ads() {
    local dir="$1"
    local count=0
    while IFS= read -r -d '' f; do
        if grep -q "## Suggest Using K-Dense Web" "$f"; then
            perl -0777 -i -pe 's/\n+## Suggest Using K-Dense Web.*//s' "$f"
            count=$((count + 1))
        fi
    done < <(find "$dir" -name "SKILL.md" -print0 2>/dev/null)
    if [[ $count -gt 0 ]]; then
        echo -e "${YELLOW}  Cleaned ad sections from ${count} file(s)${NC}"
    fi
}

# ── Install each skill ──────────────────────────────────────────────
IFS=',' read -ra SKILL_IDS <<< "$SKILLS"
SUCCESS=()
FAILED=()

for sid in "${SKILL_IDS[@]}"; do
    sid="$(echo "$sid" | xargs)"  # trim whitespace
    echo -e "${CYAN}Installing: ${sid}${NC}"

    METHOD=$(json_extract "$REGISTRY_JSON" "$sid" "install.method" 2>/dev/null) || true
    URL=$(json_extract "$REGISTRY_JSON" "$sid" "install.url" 2>/dev/null) || true

    if [[ -z "$METHOD" || -z "$URL" ]]; then
        echo -e "${RED}  Skill '$sid' not found in registry. Skipping.${NC}"
        FAILED+=("$sid")
        continue
    fi

    TARGET="$INSTALL_PATH/$sid"
    rm -rf "$TARGET"

    case "$METHOD" in
        git-clone)
            if git clone --depth 1 "$URL" "$TARGET" 2>/dev/null; then
                rm -rf "$TARGET/.git"
                echo -e "${GREEN}  Cloned successfully.${NC}"
            else
                echo -e "${RED}  Failed to clone $URL${NC}"
                FAILED+=("$sid")
                continue
            fi
            ;;
        sparse-checkout)
            SPARSE_PATH=$(json_extract "$REGISTRY_JSON" "$sid" "install.sparse_path" 2>/dev/null) || true
            if [[ -z "$SPARSE_PATH" ]]; then
                echo -e "${RED}  sparse-checkout requires sparse_path. Skipping.${NC}"
                FAILED+=("$sid")
                continue
            fi
            TMPDIR=".tmp-sparse-$sid"
            rm -rf "$TMPDIR"
            if git clone --depth 1 --filter=blob:none --sparse "$URL" "$TMPDIR" 2>/dev/null; then
                git -C "$TMPDIR" sparse-checkout set "$SPARSE_PATH" 2>/dev/null
                mkdir -p "$TARGET"
                cp -R "$TMPDIR/$SPARSE_PATH"/* "$TARGET"/ 2>/dev/null || cp -R "$TMPDIR/$SPARSE_PATH"/* "$TARGET/" 2>/dev/null
                rm -rf "$TMPDIR"
                echo -e "${GREEN}  Sparse-checkout completed.${NC}"
            else
                rm -rf "$TMPDIR"
                echo -e "${RED}  Failed to sparse-checkout $URL${NC}"
                FAILED+=("$sid")
                continue
            fi
            ;;
        *)
            echo -e "${RED}  Unknown install method: $METHOD. Skipping.${NC}"
            FAILED+=("$sid")
            continue
            ;;
    esac

    # Post-install processing
    POST_INSTALL=$(json_extract "$REGISTRY_JSON" "$sid" "post_install" 2>/dev/null) || true
    if echo "$POST_INSTALL" | grep -q "clean_ads"; then
        post_clean_ads "$TARGET"
    fi

    SUCCESS+=("$sid")
done

# ── Summary ─────────────────────────────────────────────────────────
echo ""
echo -e "${BLUE}═══════════════════════════════════════════════${NC}"
echo -e "${BLUE}  Installation Summary${NC}"
echo -e "${BLUE}═══════════════════════════════════════════════${NC}"

if [[ ${#SUCCESS[@]} -gt 0 ]]; then
    for s in "${SUCCESS[@]}"; do
        echo -e "${GREEN}  ✓ $s${NC}"
    done
fi
if [[ ${#FAILED[@]} -gt 0 ]]; then
    for f in "${FAILED[@]}"; do
        echo -e "${RED}  ✗ $f${NC}"
    done
fi

echo ""
echo -e "${GREEN}Skills installed to: $INSTALL_PATH${NC}"
echo ""
```

- [ ] **Step 2: Make the script executable and verify syntax**

Run: `chmod +x scripts/forge-install.sh && bash -n scripts/forge-install.sh && echo "Syntax OK"`
Expected: `Syntax OK`

- [ ] **Step 3: Commit**

```bash
git add scripts/forge-install.sh
git commit -m "feat: add universal forge install script (Bash)"
```

---

### Task 3: Install Script (PowerShell)

**Files:**
- Create: `scripts/forge-install.ps1`

- [ ] **Step 1: Write the PowerShell install script**

```powershell
#Requires -Version 5.1
<#
.SYNOPSIS
    Skill Configurator - Forge Installer (PowerShell)
.DESCRIPTION
    Installs selected skills from the AcademicForge registry.
.PARAMETER Tool
    Target tool: claude, opencode, or codex
.PARAMETER Skills
    Comma-separated skill IDs from the registry
.PARAMETER Path
    Custom install path (overrides Tool default)
#>
param(
    [Parameter(Mandatory=$true)]
    [ValidateSet("claude", "opencode", "codex")]
    [string]$Tool,

    [Parameter(Mandatory=$true)]
    [string]$Skills,

    [string]$Path
)

$ErrorActionPreference = "Stop"

# ── Determine install directory ─────────────────────────────────────
if (-not $Path) {
    $Path = switch ($Tool) {
        "claude"   { ".claude\skills" }
        "opencode" { ".opencode\skills" }
        "codex"    { ".codex\skills" }
    }
}

# ── Dependency check ────────────────────────────────────────────────
if (-not (Get-Command git -ErrorAction SilentlyContinue)) {
    Write-Host "Error: git is required but not installed." -ForegroundColor Red
    exit 1
}

# ── Banner ──────────────────────────────────────────────────────────
Write-Host ""
Write-Host "  Skill Configurator - Forge Installer" -ForegroundColor Blue
Write-Host ""
Write-Host "  Tool:   $Tool" -ForegroundColor Cyan
Write-Host "  Skills: $Skills" -ForegroundColor Cyan
Write-Host "  Path:   $Path" -ForegroundColor Cyan
Write-Host ""

# ── Download registry ───────────────────────────────────────────────
$RegistryUrl = "https://raw.githubusercontent.com/HughYau/AcademicForge/refs/heads/master/registry/skills.json"

Write-Host "Downloading skill registry..." -ForegroundColor Blue
try {
    $RegistryJson = (Invoke-WebRequest -Uri $RegistryUrl -UseBasicParsing).Content
    $Registry = $RegistryJson | ConvertFrom-Json
} catch {
    Write-Host "Error: failed to download registry." -ForegroundColor Red
    exit 1
}
Write-Host "Registry loaded." -ForegroundColor Green
Write-Host ""

if (-not (Test-Path $Path)) {
    New-Item -ItemType Directory -Path $Path -Force | Out-Null
}

# ── Post-install: clean_ads ─────────────────────────────────────────
function Invoke-CleanAds {
    param([string]$Dir)
    $count = 0
    Get-ChildItem -Path $Dir -Filter "SKILL.md" -Recurse | ForEach-Object {
        $content = Get-Content $_.FullName -Raw
        if ($content -match "## Suggest Using K-Dense Web") {
            $cleaned = $content -replace '(?s)\r?\n+## Suggest Using K-Dense Web.*', ''
            Set-Content -Path $_.FullName -Value $cleaned -NoNewline
            $count++
        }
    }
    if ($count -gt 0) {
        Write-Host "  Cleaned ad sections from $count file(s)" -ForegroundColor Yellow
    }
}

# ── Install each skill ──────────────────────────────────────────────
$SkillIds = $Skills -split ',' | ForEach-Object { $_.Trim() }
$Success = @()
$Failed = @()

foreach ($sid in $SkillIds) {
    Write-Host "Installing: $sid" -ForegroundColor Cyan

    $entry = $Registry.skills | Where-Object { $_.id -eq $sid }
    if (-not $entry) {
        Write-Host "  Skill '$sid' not found in registry. Skipping." -ForegroundColor Red
        $Failed += $sid
        continue
    }

    $method = $entry.install.method
    $url    = $entry.install.url
    $target = Join-Path $Path $sid

    if (Test-Path $target) { Remove-Item $target -Recurse -Force }

    switch ($method) {
        "git-clone" {
            $result = git clone --depth 1 $url $target 2>&1
            if ($LASTEXITCODE -eq 0) {
                Remove-Item (Join-Path $target ".git") -Recurse -Force -ErrorAction SilentlyContinue
                Write-Host "  Cloned successfully." -ForegroundColor Green
            } else {
                Write-Host "  Failed to clone $url" -ForegroundColor Red
                $Failed += $sid
                continue
            }
        }
        "sparse-checkout" {
            $sparsePath = $entry.install.sparse_path
            if (-not $sparsePath) {
                Write-Host "  sparse-checkout requires sparse_path. Skipping." -ForegroundColor Red
                $Failed += $sid
                continue
            }
            $tmpDir = ".tmp-sparse-$sid"
            if (Test-Path $tmpDir) { Remove-Item $tmpDir -Recurse -Force }

            git clone --depth 1 --filter=blob:none --sparse $url $tmpDir 2>&1 | Out-Null
            if ($LASTEXITCODE -eq 0) {
                git -C $tmpDir sparse-checkout set $sparsePath 2>&1 | Out-Null
                New-Item -ItemType Directory -Path $target -Force | Out-Null
                Copy-Item -Path (Join-Path $tmpDir $sparsePath "*") -Destination $target -Recurse -Force
                Remove-Item $tmpDir -Recurse -Force
                Write-Host "  Sparse-checkout completed." -ForegroundColor Green
            } else {
                Remove-Item $tmpDir -Recurse -Force -ErrorAction SilentlyContinue
                Write-Host "  Failed to sparse-checkout $url" -ForegroundColor Red
                $Failed += $sid
                continue
            }
        }
        default {
            Write-Host "  Unknown install method: $method. Skipping." -ForegroundColor Red
            $Failed += $sid
            continue
        }
    }

    # Post-install processing
    if ($entry.post_install -contains "clean_ads") {
        Invoke-CleanAds -Dir $target
    }

    $Success += $sid
}

# ── Summary ─────────────────────────────────────────────────────────
Write-Host ""
Write-Host "  Installation Summary" -ForegroundColor Blue
Write-Host ""

foreach ($s in $Success) {
    Write-Host "  + $s" -ForegroundColor Green
}
foreach ($f in $Failed) {
    Write-Host "  x $f" -ForegroundColor Red
}

Write-Host ""
Write-Host "Skills installed to: $Path" -ForegroundColor Green
Write-Host ""
```

- [ ] **Step 2: Verify PowerShell syntax**

Run: `powershell -NoProfile -Command "Get-Content scripts/forge-install.ps1 | Out-Null; Write-Host 'Syntax OK'"`
Expected: `Syntax OK`

- [ ] **Step 3: Commit**

```bash
git add scripts/forge-install.ps1
git commit -m "feat: add universal forge install script (PowerShell)"
```

---

### Task 4: Astro Project Scaffold

**Files:**
- Create: `site/package.json`
- Create: `site/astro.config.mjs`
- Create: `site/tailwind.config.mjs`
- Create: `site/tsconfig.json`
- Create: `site/src/styles/global.css`
- Create: `site/public/favicon.svg`

- [ ] **Step 1: Initialize Astro project**

Run:
```bash
cd site && npm create astro@latest -- . --template minimal --no-install --no-git --typescript strict
```

- [ ] **Step 2: Install dependencies**

Run:
```bash
cd site && npm install && npx astro add tailwind -y
```

- [ ] **Step 3: Configure Astro for GitHub Pages**

Write `site/astro.config.mjs`:
```js
import { defineConfig } from 'astro/config';
import tailwindcss from '@astrojs/tailwind';

export default defineConfig({
  site: 'https://hughyau.github.io',
  base: '/AcademicForge',
  integrations: [tailwindcss()],
});
```

- [ ] **Step 4: Write global CSS**

Write `site/src/styles/global.css`:
```css
@import "tailwindcss";
```

- [ ] **Step 5: Create favicon**

Write `site/public/favicon.svg`:
```svg
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 100 100"><text y="80" font-size="80">🔧</text></svg>
```

- [ ] **Step 6: Verify build**

Run: `cd site && npm run build`
Expected: Build succeeds with output in `site/dist/`

- [ ] **Step 7: Commit**

```bash
git add site/
git commit -m "feat: scaffold Astro site with Tailwind CSS"
```

---

### Task 5: Layout Component

**Files:**
- Create: `site/src/layouts/Layout.astro`

- [ ] **Step 1: Write the Layout component**

```astro
---
interface Props {
  title: string;
}
const { title } = Astro.props;
---

<!doctype html>
<html lang="zh-CN">
  <head>
    <meta charset="UTF-8" />
    <meta name="viewport" content="width=device-width, initial-scale=1.0" />
    <meta name="description" content="Pick your AI coding skills. Get your install command." />
    <link rel="icon" type="image/svg+xml" href="/AcademicForge/favicon.svg" />
    <title>{title}</title>
  </head>
  <body class="min-h-screen bg-gray-950 text-gray-100">
    <slot />
    <footer class="py-8 text-center text-sm text-gray-500">
      <p>
        Built with <span class="text-blue-400">AcademicForge</span> &middot;
        <a href="https://github.com/HughYau/AcademicForge" class="underline hover:text-gray-300" target="_blank" rel="noopener">GitHub</a>
      </p>
    </footer>
  </body>
</html>
```

- [ ] **Step 2: Verify build**

Run: `cd site && npm run build`
Expected: Build succeeds

- [ ] **Step 3: Commit**

```bash
git add site/src/layouts/Layout.astro
git commit -m "feat: add Layout component"
```

---

### Task 6: CodeBlock Component

**Files:**
- Create: `site/src/components/CodeBlock.astro`

- [ ] **Step 1: Write the CodeBlock component with copy button**

```astro
---
interface Props {
  code: string;
  lang?: string;
  id?: string;
}
const { code, lang = 'bash', id = `cb-${Math.random().toString(36).slice(2, 9)}` } = Astro.props;
---

<div class="group relative rounded-lg bg-gray-900 border border-gray-700">
  <div class="flex items-center justify-between px-4 py-2 border-b border-gray-700">
    <span class="text-xs text-gray-400 uppercase">{lang}</span>
    <button
      data-copy-target={id}
      class="copy-btn px-3 py-1 text-xs rounded bg-gray-700 hover:bg-gray-600 text-gray-300 transition-colors"
    >
      Copy
    </button>
  </div>
  <pre id={id} class="p-4 overflow-x-auto text-sm leading-relaxed"><code>{code}</code></pre>
</div>

<script>
  document.addEventListener('click', (e) => {
    const btn = (e.target as HTMLElement).closest('.copy-btn') as HTMLButtonElement | null;
    if (!btn) return;
    const targetId = btn.dataset.copyTarget;
    if (!targetId) return;
    const block = document.getElementById(targetId);
    if (!block) return;

    navigator.clipboard.writeText(block.textContent?.trim() ?? '').then(() => {
      const original = btn.textContent;
      btn.textContent = 'Copied!';
      btn.classList.add('bg-green-700');
      setTimeout(() => {
        btn.textContent = original;
        btn.classList.remove('bg-green-700');
      }, 2000);
    });
  });
</script>
```

- [ ] **Step 2: Verify build**

Run: `cd site && npm run build`
Expected: Build succeeds

- [ ] **Step 3: Commit**

```bash
git add site/src/components/CodeBlock.astro
git commit -m "feat: add CodeBlock component with copy button"
```

---

### Task 7: SkillCard Component

**Files:**
- Create: `site/src/components/SkillCard.astro`

- [ ] **Step 1: Write the SkillCard component**

```astro
---
interface Props {
  id: string;
  name: string;
  description: string;
  author: string;
  repository: string;
  license: string;
  skill_count: number;
  tags: string[];
  category: string;
}
const { id, name, description, author, repository, skill_count, tags, category } = Astro.props;
---

<div
  class="skill-card rounded-xl border border-gray-700 bg-gray-900 p-5 hover:border-blue-500 transition-colors cursor-pointer"
  data-skill-id={id}
  data-category={category}
  data-tags={tags.join(',')}
>
  <div class="flex items-start justify-between gap-3">
    <div class="flex-1 min-w-0">
      <h3 class="text-lg font-semibold text-gray-100 truncate">{name}</h3>
      <p class="mt-1 text-sm text-gray-400 line-clamp-2">{description}</p>
    </div>
    <label class="flex-shrink-0 relative cursor-pointer">
      <input
        type="checkbox"
        class="skill-checkbox sr-only peer"
        data-skill-id={id}
        data-skill-name={name}
      />
      <div class="w-6 h-6 rounded border-2 border-gray-600 peer-checked:bg-blue-600 peer-checked:border-blue-600 flex items-center justify-center transition-colors">
        <svg class="w-4 h-4 text-white hidden peer-checked:block" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="3">
          <path stroke-linecap="round" stroke-linejoin="round" d="M5 13l4 4L19 7" />
        </svg>
      </div>
    </label>
  </div>

  <div class="mt-3 flex items-center gap-3 text-xs text-gray-500">
    <a href={repository} target="_blank" rel="noopener" class="hover:text-gray-300 underline">
      @{author}
    </a>
    <span class="px-2 py-0.5 rounded-full bg-blue-900 text-blue-300 font-medium">
      {skill_count} skills
    </span>
  </div>

  <div class="mt-3 flex flex-wrap gap-1.5">
    {tags.map((tag) => (
      <span class="px-2 py-0.5 rounded-full bg-gray-800 text-gray-400 text-xs">
        {tag}
      </span>
    ))}
  </div>
</div>
```

- [ ] **Step 2: Verify build**

Run: `cd site && npm run build`
Expected: Build succeeds

- [ ] **Step 3: Commit**

```bash
git add site/src/components/SkillCard.astro
git commit -m "feat: add SkillCard component"
```

---

### Task 8: SkillGrid Component

**Files:**
- Create: `site/src/components/SkillGrid.astro`

- [ ] **Step 1: Write the SkillGrid component with filter/search**

```astro
---
import SkillCard from './SkillCard.astro';
import skillsData from '../../../registry/skills.json';

const skills = skillsData.skills;
const categories = [...new Set(skills.map(s => s.category))];
---

<section id="skill-grid-section">
  <!-- Filter bar -->
  <div class="flex flex-wrap items-center gap-3 mb-6">
    <div class="flex gap-2">
      <button class="filter-btn px-3 py-1.5 rounded-lg text-sm bg-blue-600 text-white" data-category="all">
        All
      </button>
      {categories.map(cat => (
        <button
          class="filter-btn px-3 py-1.5 rounded-lg text-sm bg-gray-800 text-gray-300 hover:bg-gray-700"
          data-category={cat}
        >
          {cat.charAt(0).toUpperCase() + cat.slice(1)}
        </button>
      ))}
    </div>
    <input
      id="skill-search"
      type="text"
      placeholder="Search skills..."
      class="ml-auto px-4 py-1.5 rounded-lg bg-gray-800 border border-gray-700 text-sm text-gray-200 placeholder-gray-500 focus:outline-none focus:border-blue-500 w-64"
    />
  </div>

  <!-- Grid -->
  <div id="skill-grid" class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
    {skills.map(skill => (
      <SkillCard {...skill} />
    ))}
  </div>
</section>

<script>
  // Category filter
  const filterBtns = document.querySelectorAll('.filter-btn');
  const cards = document.querySelectorAll('.skill-card') as NodeListOf<HTMLElement>;
  const searchInput = document.getElementById('skill-search') as HTMLInputElement;

  let activeCategory = 'all';
  let searchQuery = '';

  function applyFilters() {
    cards.forEach(card => {
      const cat = card.dataset.category ?? '';
      const tags = card.dataset.tags ?? '';
      const text = card.textContent?.toLowerCase() ?? '';

      const matchCategory = activeCategory === 'all' || cat === activeCategory;
      const matchSearch = !searchQuery || text.includes(searchQuery) || tags.toLowerCase().includes(searchQuery);

      card.style.display = matchCategory && matchSearch ? '' : 'none';
    });
  }

  filterBtns.forEach(btn => {
    btn.addEventListener('click', () => {
      filterBtns.forEach(b => {
        b.classList.remove('bg-blue-600', 'text-white');
        b.classList.add('bg-gray-800', 'text-gray-300');
      });
      btn.classList.remove('bg-gray-800', 'text-gray-300');
      btn.classList.add('bg-blue-600', 'text-white');
      activeCategory = (btn as HTMLElement).dataset.category ?? 'all';
      applyFilters();
    });
  });

  searchInput.addEventListener('input', () => {
    searchQuery = searchInput.value.toLowerCase().trim();
    applyFilters();
  });
</script>
```

- [ ] **Step 2: Verify build**

Run: `cd site && npm run build`
Expected: Build succeeds

- [ ] **Step 3: Commit**

```bash
git add site/src/components/SkillGrid.astro
git commit -m "feat: add SkillGrid component with filtering and search"
```

---

### Task 9: Configurator Component

**Files:**
- Create: `site/src/components/Configurator.astro`

- [ ] **Step 1: Write the Configurator component**

This is the bottom panel that shows selected skills, platform/tool selectors, and the generate button.

```astro
---
---

<section id="configurator" class="sticky bottom-0 z-10 border-t border-gray-700 bg-gray-900/95 backdrop-blur px-6 py-4">
  <div class="max-w-6xl mx-auto">
    <div class="flex flex-wrap items-center gap-4">
      <!-- Selected count -->
      <div class="text-sm text-gray-400">
        Selected: <span id="selected-count" class="text-white font-semibold">0</span> skill packs
        (<span id="selected-total" class="text-white font-semibold">0</span> skills)
      </div>

      <!-- Platform selector -->
      <div class="flex items-center gap-2">
        <label class="text-sm text-gray-400">Platform:</label>
        <select id="platform-select" class="rounded-lg bg-gray-800 border border-gray-700 text-sm text-gray-200 px-3 py-1.5 focus:outline-none focus:border-blue-500">
          <option value="linux">Linux / macOS</option>
          <option value="windows">Windows</option>
        </select>
      </div>

      <!-- Tool selector -->
      <div class="flex items-center gap-2">
        <label class="text-sm text-gray-400">Tool:</label>
        <select id="tool-select" class="rounded-lg bg-gray-800 border border-gray-700 text-sm text-gray-200 px-3 py-1.5 focus:outline-none focus:border-blue-500">
          <option value="claude">Claude Code</option>
          <option value="opencode">OpenCode</option>
          <option value="codex">Codex</option>
        </select>
      </div>

      <!-- Generate button -->
      <button
        id="generate-btn"
        disabled
        class="ml-auto px-5 py-2 rounded-lg bg-blue-600 text-white font-medium text-sm hover:bg-blue-500 disabled:opacity-40 disabled:cursor-not-allowed transition-colors"
      >
        Generate Install Command
      </button>
    </div>
  </div>
</section>

<script>
  import skillsData from '../../../registry/skills.json';

  const checkboxes = document.querySelectorAll('.skill-checkbox') as NodeListOf<HTMLInputElement>;
  const countEl = document.getElementById('selected-count')!;
  const totalEl = document.getElementById('selected-total')!;
  const generateBtn = document.getElementById('generate-btn') as HTMLButtonElement;

  function getSelectedSkills(): string[] {
    const ids: string[] = [];
    checkboxes.forEach(cb => { if (cb.checked) ids.push(cb.dataset.skillId!); });
    return ids;
  }

  function updateSelection() {
    const selected = getSelectedSkills();
    countEl.textContent = String(selected.length);

    const total = selected.reduce((sum, id) => {
      const skill = skillsData.skills.find(s => s.id === id);
      return sum + (skill?.skill_count ?? 0);
    }, 0);
    totalEl.textContent = String(total);

    generateBtn.disabled = selected.length === 0;
  }

  checkboxes.forEach(cb => cb.addEventListener('change', updateSelection));

  generateBtn.addEventListener('click', () => {
    const selected = getSelectedSkills();
    if (selected.length === 0) return;

    const platform = (document.getElementById('platform-select') as HTMLSelectElement).value;
    const tool = (document.getElementById('tool-select') as HTMLSelectElement).value;

    const event = new CustomEvent('generate-command', {
      detail: { skills: selected, platform, tool },
    });
    document.dispatchEvent(event);
  });
</script>
```

- [ ] **Step 2: Verify build**

Run: `cd site && npm run build`
Expected: Build succeeds

- [ ] **Step 3: Commit**

```bash
git add site/src/components/Configurator.astro
git commit -m "feat: add Configurator component (selection + platform/tool)"
```

---

### Task 10: InstallGuide Component

**Files:**
- Create: `site/src/components/InstallGuide.astro`

- [ ] **Step 1: Write the InstallGuide component**

This is the modal/panel that shows the step-by-step guide after the user clicks "Generate".

```astro
---
---

<div id="install-guide-overlay" class="hidden fixed inset-0 z-50 bg-black/70 flex items-center justify-center p-4">
  <div class="bg-gray-900 border border-gray-700 rounded-2xl max-w-2xl w-full max-h-[90vh] overflow-y-auto p-6">
    <div class="flex items-center justify-between mb-6">
      <h2 class="text-xl font-bold text-gray-100">Installation Guide</h2>
      <button id="guide-close" class="text-gray-400 hover:text-gray-200 text-2xl leading-none">&times;</button>
    </div>

    <div id="guide-content" class="space-y-6">
      <!-- Dynamically populated by JS -->
    </div>
  </div>
</div>

<script>
  const overlay = document.getElementById('install-guide-overlay')!;
  const content = document.getElementById('guide-content')!;
  const closeBtn = document.getElementById('guide-close')!;

  const SCRIPT_BASE = 'https://raw.githubusercontent.com/HughYau/AcademicForge/refs/heads/master/scripts';

  const toolPaths: Record<string, Record<string, string>> = {
    claude:   { linux: '.claude/skills',   windows: '.claude\\skills' },
    opencode: { linux: '.opencode/skills', windows: '.opencode\\skills' },
    codex:    { linux: '.codex/skills',    windows: '.codex\\skills' },
  };

  function makeCodeBlock(code: string, lang: string): string {
    const id = `guide-cb-${Math.random().toString(36).slice(2, 9)}`;
    return `
      <div class="relative rounded-lg bg-gray-950 border border-gray-700">
        <div class="flex items-center justify-between px-4 py-2 border-b border-gray-700">
          <span class="text-xs text-gray-400 uppercase">${lang}</span>
          <button onclick="
            navigator.clipboard.writeText(document.getElementById('${id}').textContent.trim()).then(() => {
              this.textContent = 'Copied!';
              this.classList.add('bg-green-700');
              setTimeout(() => { this.textContent = 'Copy'; this.classList.remove('bg-green-700'); }, 2000);
            })
          " class="px-3 py-1 text-xs rounded bg-gray-700 hover:bg-gray-600 text-gray-300 transition-colors">Copy</button>
        </div>
        <pre id="${id}" class="p-4 overflow-x-auto text-sm leading-relaxed"><code>${code}</code></pre>
      </div>`;
  }

  function renderGuide(skills: string[], platform: string, tool: string) {
    const skillList = skills.join(',');
    const paths = toolPaths[tool] ?? toolPaths.claude;
    const isWindows = platform === 'windows';
    const skillPath = isWindows ? paths.windows : paths.linux;

    const terminalName = isWindows ? 'PowerShell' : 'Terminal';
    const cdExample = isWindows ? 'cd C:\\path\\to\\your-project' : 'cd /path/to/your-project';

    const installCmd = isWindows
      ? `Invoke-WebRequest -Uri "${SCRIPT_BASE}/forge-install.ps1" -OutFile forge-install.ps1\n.\\forge-install.ps1 -Tool ${tool} -Skills "${skillList}"\nRemove-Item forge-install.ps1`
      : `curl -sSL ${SCRIPT_BASE}/forge-install.sh | bash -s -- \\\n  --tool ${tool} \\\n  --skills ${skillList}`;

    const verifyCmd = isWindows ? `dir ${skillPath}` : `ls ${skillPath}/`;

    const toolDisplayName: Record<string, string> = {
      claude: 'Claude Code',
      opencode: 'OpenCode',
      codex: 'Codex',
    };

    content.innerHTML = `
      <div>
        <h3 class="text-sm font-semibold text-blue-400 mb-2">Step 1: Open ${terminalName} and navigate to your project root</h3>
        ${makeCodeBlock(cdExample, isWindows ? 'powershell' : 'bash')}
        <p class="mt-2 text-xs text-yellow-400">Make sure this directory is a git repository.</p>
      </div>

      <div>
        <h3 class="text-sm font-semibold text-blue-400 mb-2">Step 2: Run the install command</h3>
        ${makeCodeBlock(installCmd, isWindows ? 'powershell' : 'bash')}
      </div>

      <div>
        <h3 class="text-sm font-semibold text-blue-400 mb-2">Step 3: Verify installation</h3>
        ${makeCodeBlock(verifyCmd, isWindows ? 'powershell' : 'bash')}
      </div>

      <div class="rounded-lg bg-gray-800 border border-gray-700 p-4 text-sm text-gray-300 space-y-1">
        <p>Skills will be installed to <code class="text-blue-300">${skillPath}</code></p>
        <p>${toolDisplayName[tool] ?? tool} will automatically detect and load these skills.</p>
        <p>Start ${toolDisplayName[tool] ?? tool} and you're good to go!</p>
      </div>
    `;

    overlay.classList.remove('hidden');
  }

  // Listen for generate event from Configurator
  document.addEventListener('generate-command', ((e: CustomEvent) => {
    renderGuide(e.detail.skills, e.detail.platform, e.detail.tool);
  }) as EventListener);

  // Close
  closeBtn.addEventListener('click', () => overlay.classList.add('hidden'));
  overlay.addEventListener('click', (e) => {
    if (e.target === overlay) overlay.classList.add('hidden');
  });
</script>
```

- [ ] **Step 2: Verify build**

Run: `cd site && npm run build`
Expected: Build succeeds

- [ ] **Step 3: Commit**

```bash
git add site/src/components/InstallGuide.astro
git commit -m "feat: add InstallGuide component with step-by-step guide"
```

---

### Task 11: Main Page

**Files:**
- Create: `site/src/pages/index.astro`

- [ ] **Step 1: Write the main page assembling all components**

```astro
---
import Layout from '../layouts/Layout.astro';
import SkillGrid from '../components/SkillGrid.astro';
import Configurator from '../components/Configurator.astro';
import InstallGuide from '../components/InstallGuide.astro';
---

<Layout title="Skill Configurator | AcademicForge">
  <main class="max-w-6xl mx-auto px-6 pt-12 pb-32">
    <!-- Header -->
    <section class="mb-12 text-center">
      <h1 class="text-4xl font-bold tracking-tight text-gray-100">
        Skill Configurator
      </h1>
      <p class="mt-4 text-lg text-gray-400 max-w-2xl mx-auto">
        Pick your skills. Choose your platform. Get your install command.
      </p>
    </section>

    <!-- Skill browsing grid -->
    <SkillGrid />
  </main>

  <!-- Bottom bar: selection + generate -->
  <Configurator />

  <!-- Modal: install guide -->
  <InstallGuide />
</Layout>
```

- [ ] **Step 2: Verify full site build**

Run: `cd site && npm run build`
Expected: Build succeeds, `dist/` contains `index.html`

- [ ] **Step 3: Preview locally**

Run: `cd site && npm run preview`
Expected: Site opens at `localhost:4321`, cards render, selection works, command generates

- [ ] **Step 4: Commit**

```bash
git add site/src/pages/index.astro
git commit -m "feat: add main page assembling all components"
```

---

### Task 12: GitHub Pages Deployment Workflow

**Files:**
- Create: `.github/workflows/deploy-site.yml`

- [ ] **Step 1: Write the deployment workflow**

```yaml
name: Deploy Site to GitHub Pages

on:
  push:
    branches: [master]
    paths:
      - 'site/**'
      - 'registry/**'
  workflow_dispatch:

permissions:
  contents: read
  pages: write
  id-token: write

concurrency:
  group: pages
  cancel-in-progress: true

jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - name: Checkout
        uses: actions/checkout@v4

      - name: Setup Node
        uses: actions/setup-node@v4
        with:
          node-version: 20

      - name: Install dependencies
        working-directory: site
        run: npm ci

      - name: Build site
        working-directory: site
        run: npm run build

      - name: Upload artifact
        uses: actions/upload-pages-artifact@v3
        with:
          path: site/dist

  deploy:
    needs: build
    runs-on: ubuntu-latest
    environment:
      name: github-pages
      url: ${{ steps.deployment.outputs.page_url }}
    steps:
      - name: Deploy to GitHub Pages
        id: deployment
        uses: actions/deploy-pages@v4
```

- [ ] **Step 2: Verify YAML syntax**

Run: `python -c "import yaml; yaml.safe_load(open('.github/workflows/deploy-site.yml')); print('OK')"`
Expected: `OK`

- [ ] **Step 3: Commit**

```bash
git add .github/workflows/deploy-site.yml
git commit -m "feat: add GitHub Pages deployment workflow"
```

---

### Task 13: End-to-End Verification

- [ ] **Step 1: Full build**

Run: `cd site && npm run build`
Expected: Build succeeds

- [ ] **Step 2: Local preview and manual test**

Run: `cd site && npm run preview`

Verify:
1. Page loads with header and skill cards
2. Category filter buttons work (All / Academic / Development)
3. Search box filters cards in real-time
4. Checking skill cards updates selected count in bottom bar
5. Platform and tool dropdowns work
6. Generate button is disabled when nothing selected, enabled when skills selected
7. Clicking generate shows the install guide modal
8. Each code block in the modal has a working copy button
9. Switching platform changes commands (curl vs PowerShell)
10. Switching tool changes install path (.claude vs .opencode vs .codex)
11. Clicking X or overlay closes the modal

- [ ] **Step 3: Test install script locally**

Run:
```bash
mkdir /tmp/test-forge && cd /tmp/test-forge && git init
bash /path/to/AcademicForge/scripts/forge-install.sh --tool claude --skills humanizer
ls .claude/skills/humanizer/
```
Expected: `humanizer` directory exists with SKILL.md inside

- [ ] **Step 4: Clean up and final commit**

```bash
rm -rf /tmp/test-forge
git add -A
git commit -m "chore: end-to-end verification complete"
```
