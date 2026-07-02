<p align="center">
  <img src="./assets/academicforge-banner.svg" alt="Academic Forge Header Image" />
</p>


# 🎓 Academic Forge

<div align="center">

**A site-first skill catalog and installer for academic workflows**

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

<p align="center">
  <a href="https://hughyau.github.io/AcademicForge/">
    <img src="https://img.shields.io/badge/Experience-Academic%20Forge-blue?style=for-the-badge" alt="Experience Academic Forge">
  </a>
</p>

[简体中文](./README.md) | English

</div>

> Branch model
> - `site-first`: the project's main (default) branch, and the single source for GitHub Pages, `registry/skills.json`, and installer scripts.
> - the old submodule-based architecture (`master`) has been retired and is no longer maintained or updated weekly.

> ✨ **New: 32 built-in Claude Science skills (by Anthropic)**
> - covers protein structure & design, genomics, single-cell, publication figures, literature review, remote compute, and more
> - installable **without a Claude Science subscription**, usable **across agents** (Claude Code / OpenCode / Codex), and **works on Windows** (PowerShell installer)
> - shipped as a locally maintained collection under `skills/claude-science`, filed in the catalog under "Workflow & Process · Claude Science", with each sub-skill re-classified into research / writing / figures, etc.

## 🔨 What Academic Forge Is

Academic Forge is a **site-first catalog + installer**. Much like Minecraft Forge loads mods into the game, it forges scattered academic AI skills into one handy toolbox. 🎓

Instead of cloning a whole bundle into every project, just three steps:

1. 🖱️ browse and check the packs you need on the site
2. 📋 generate an install command in one click
3. ⚡ run it from your project root

Core rules:

- 🧩 the site, generated commands, and installers all read the same `registry/skills.json`
- 🌿 `site-first` is the only public line
- 📦 two things are maintained locally in this repository: `skills/scientific-visualization` and `skills/claude-science` (Anthropic's built-in Claude Science collection)

## 🚀 Quick Start

### 🖱️ Option 1: Use the configurator site

Open `https://hughyau.github.io/AcademicForge/`, check the skill packs you need, pick your platform (Claude Code / OpenCode / Codex), and generate the install command in one click.

<p align="center">
  <video src="https://github.com/user-attachments/assets/3b539896-6380-4ac4-9ae9-9b79ed7adaf3" controls width="960">
  </video>
</p>

### ⌨️ Option 2: Run the installer directly

macOS / Linux:

```bash
cd your-project
curl -sSL https://raw.githubusercontent.com/HughYau/AcademicForge/refs/heads/site-first/scripts/forge-install.sh | bash -s -- \
  --tool claude \
  --skills humanizer,superpowers
```

Windows PowerShell:

```powershell
cd your-project
$script = Join-Path $PWD 'forge-install.ps1'
Invoke-WebRequest -Uri 'https://raw.githubusercontent.com/HughYau/AcademicForge/refs/heads/site-first/scripts/forge-install.ps1' -OutFile $script
& $script -Tool claude -Skills 'humanizer,superpowers'
Remove-Item $script
```

Already-installed skills with the same name are skipped with a warning; add `--force` (`-Force` in PowerShell) to overwrite.

### 🤖 Option 3: Let your AI pick for you

Not sure what to pick? Hand this prompt to your AI agent (Claude Code / OpenCode / Codex):

> Fetch and read https://hughyau.github.io/AcademicForge/agents.md, then follow its instructions: ask about my research needs, pick matching academic skills from the AcademicForge catalog, and build the install command for me.

The "Not sure what to pick?" card on the site copies this prompt in one click (with your selected tool and platform baked in). Agent-readable catalog endpoints:

- Guide: `https://hughyau.github.io/AcademicForge/agents.md`
- Slim index: `https://hughyau.github.io/AcademicForge/index.slim.json`
- Full registry mirror: `https://hughyau.github.io/AcademicForge/skills.json`

Verify installation:

```bash
ls .claude/skills/
ls .opencode/skills/
ls .codex/skills/
```

## 📦 Local Content Kept in This Branch

The local skill content that remains checked in on `site-first` is:

- `skills/scientific-visualization` — a single local skill
- `skills/claude-science` — the **Claude Science** (Anthropic) built-in collection, 32 skills. The collection root is filed under "Workflow & Process" as *Claude Science* by *Anthropic*; each sub-skill is then re-classified into research / writing / figures, etc. Because it is hosted directly in this repo, it installs via sparse-checkout **without a Claude Science subscription**, and is **usable across agents including on Windows**.

  After editing that directory, rebuild just this collection's index (no network clone of the other collections):

  ```bash
  node scripts/build-skill-index.mjs --only claude-science
  node scripts/build-slim-index.mjs
  ```

All other packs are installed from the sources described in `registry/skills.json`.

## 🛠️ Maintaining `site-first`

Common local commands:

```bash
npm run site:install
npm run build
npm run preview
npm run validate:registry
npm run ci:validate
node scripts/build-skill-index.mjs --check
```

Local installer smoke tests:

```bash
"D:\Application\Git\bin\bash.exe" scripts/tests/forge-install-local-registry.sh
pwsh -File scripts/tests/forge-install-local-registry.ps1
```

## 🌐 GitHub Pages

- GitHub Pages deploys only from `site-first`
- set `Settings -> Pages -> Source` to `GitHub Actions`
- use `npm run preview` for branch-local preview before pushing

## 📚 Documentation

- [Quick Start](./QUICKSTART.md)
- [Attributions](./ATTRIBUTIONS.md)
- [site-first design spec](./docs/superpowers/specs/2026-04-16-site-first-light-catalog-repo-design.md)
- [site-first implementation plan](./docs/superpowers/plans/2026-04-16-site-first-branch-implementation.md)

## ⭐ Star History

<a href="https://www.star-history.com/?repos=HughYau%2FAcademicForge&type=date&legend=top-left">
 <picture>
   <source media="(prefers-color-scheme: dark)" srcset="https://api.star-history.com/image?repos=HughYau/AcademicForge&type=date&theme=dark&legend=top-left" />
   <source media="(prefers-color-scheme: light)" srcset="https://api.star-history.com/image?repos=HughYau/AcademicForge&type=date&legend=top-left" />
   <img alt="Star History Chart" src="https://api.star-history.com/image?repos=HughYau/AcademicForge&type=date&legend=top-left" />
 </picture>
</a>

---

## 📄 License

- repository structure, site, scripts, and local content are under [MIT](./LICENSE)
- third-party skills retain their original licenses and authorship
