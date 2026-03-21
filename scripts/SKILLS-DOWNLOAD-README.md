# Skills Download/Sync Guide

This guide explains what the `download-skills` scripts do in Academic Forge.

## What gets synced

The scripts sync all skill sources into your local `skills/` directory:

1. Git submodule-based skills:
   - `skills/claude-scientific-skills`
   - `skills/AI-research-SKILLs`
   - `skills/humanizer`
   - `skills/paper-polish-workflow-skill`
2. Skills-only synced source:
   - `skills/superpowers` (from `https://github.com/obra/superpowers/tree/main/skills`)
   - `skills/planning-with-files` (from `https://github.com/OthmanAdi/planning-with-files/tree/master/.opencode/skills/planning-with-files`)
3. Local bundled skills (tracked in this repository):
   - `skills/scientific-visualization`

## Commands

### Windows (PowerShell)

```powershell
.\scripts\download-skills.ps1
```

### Linux/macOS

```bash
bash scripts/download-skills.sh
```

## Notes

- `superpowers` is intentionally synced as **skills-only** (no plugin or other repository directories).
- `planning-with-files` is intentionally synced as a **single skill folder** from upstream `.opencode/skills/planning-with-files` (not as a submodule).
- `scientific-visualization` is a local first-party skill in this repository and is **not** pulled from an external upstream by sync scripts.
- Re-running the scripts is safe and refreshes skill content to latest upstream state.
- A post-sync blacklist is applied from `scripts/skill-blacklist.txt`.
- Current default blacklist removes:
  - `skills/claude-scientific-skills/scientific-skills/offer-k-dense-web`
