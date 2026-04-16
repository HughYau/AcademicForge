# 🎓 Academic Forge

<div align="center">

**A site-first skill catalog and installer for academic workflows**

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

</div>

> Branch model
> - `site-first`: the public website branch and the source for GitHub Pages, `registry/skills.json`, and installer scripts.
> - `master`: the legacy compatibility branch.

## What Academic Forge Is

Academic Forge is a **site-first catalog + installer**.

Instead of cloning a whole bundle into every project, you:

1. browse packs on the site
2. generate an install command
3. run it from your project root

Core rules:

- the site, generated commands, and installers all read the same `registry/skills.json`
- `site-first` is the public line
- only one skill is maintained locally in this repository: `skills/scientific-visualization`

## Quick Start

### Option 1: Use the configurator site

Open `https://hughyau.github.io/AcademicForge/`.

### Option 2: Run the installer directly

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

Verify installation:

```bash
ls .claude/skills/
ls .opencode/skills/
ls .codex/skills/
```

## Local Content Kept in This Branch

The only local skill content that remains checked in on `site-first` is:

- `skills/scientific-visualization`

All other packs are installed from the sources described in `registry/skills.json`.

## Maintaining `site-first`

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

## GitHub Pages

- GitHub Pages deploys only from `site-first`
- set `Settings -> Pages -> Source` to `GitHub Actions`
- use `npm run preview` for branch-local preview before pushing

## Documentation

- [Quick Start](./QUICKSTART.md)
- [Attributions](./ATTRIBUTIONS.md)
- [site-first design spec](./docs/superpowers/specs/2026-04-16-site-first-light-catalog-repo-design.md)
- [site-first implementation plan](./docs/superpowers/plans/2026-04-16-site-first-branch-implementation.md)

## License

- repository structure, site, scripts, and local content are under [MIT](./LICENSE)
- third-party skills retain their original licenses and authorship
