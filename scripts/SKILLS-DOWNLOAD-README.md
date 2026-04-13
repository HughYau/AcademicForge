# Skills Download/Sync Guide

This guide explains what the `download-skills` scripts do in Academic Forge.

## What gets synced

The scripts sync all skill sources into your local `skills/` directory:

1. Git submodule-based skills:
   - `skills/scientific-agent-skills`
   - `skills/AI-research-SKILLs`
   - `skills/humanizer`
   - `skills/humanizer-zh`
   - `skills/paper-polish-workflow-skill`
2. Skills-only synced source:
   - `skills/superpowers` (from `https://github.com/obra/superpowers/tree/main/skills`)
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
- `scientific-visualization` is a local first-party skill in this repository and is **not** pulled from an external upstream by sync scripts.
- Re-running the scripts is safe and refreshes skill content to latest upstream state.
- A post-sync blacklist is applied from `scripts/skill-blacklist.txt`.
- The blacklist file is currently empty by default; add one relative path per line if a future upstream skill needs to be blocked.
