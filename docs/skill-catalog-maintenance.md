# AcademicForge Skill Catalog Maintenance

> Give this file to an agent whenever it is asked to refresh, repair, or extend the AcademicForge skill catalog. It contains the operating procedure and the project-specific context it needs; do not rely on an old conversation for catalog facts.

## Scope and source of truth

- The authoritative catalog is [`registry/skills.json`](../registry/skills.json). Never edit `site/public/skills.json` or `site/public/index.slim.json` by hand: they are generated copies.
- The public branch is `site-first`. Do not use the legacy `master` branch as a catalog source.
- `skill_count` means the number of upstream `SKILL.md` files that this pack intentionally exposes. Count actual files; never infer it from a README.
- The catalog currently contains 11 top-level packs. Three are expanded into individually selectable sub-skills; the remainder are installed as a complete pack.
- Star counts are a timestamped snapshot, not a permanent fact. Always refresh them in the same run that changes the catalog.

## Read this before editing

1. Check that the worktree is safe to change:

   ```powershell
   git status --short
   git branch --show-current
   ```

   Preserve unrelated user changes. The expected public branch is `site-first`.

2. Read the current entries and generated-file rules in `registry/skills.json`, `scripts/build-skill-index.mjs`, `scripts/lib/skill-collections.mjs`, and `scripts/validate-registry.mjs`.

3. Read the existing regression tests in `scripts/tests/`. Add a failing test before changing indexer behavior or correcting a known upstream-drift failure.

## Existing sources and their special handling

| ID | Upstream | Install/index rule |
| --- | --- | --- |
| `superpowers` | `obra/superpowers` | Sparse checkout of `skills/`. |
| `andrej-karpathy-skills` | `multica-ai/andrej-karpathy-skills` | Sparse checkout of `skills/`. |
| `scientific-agent-skills` | `K-Dense-AI/scientific-agent-skills` | Expanded collection: scan `skills/`, prefix child IDs with `sa.`. |
| `humanizer` / `humanizer-zh` | `blader/humanizer`, `op7418/Humanizer-zh` | Full pack clone. |
| `AI-research-SKILLs` | `Orchestra-Research/AI-Research-SKILLs` | Expanded collection: scan the repository root, prefix child IDs with `air.`. |
| `nature-skills` | `Yuan1z0825/nature-skills` | Expanded collection: scan `skills/`, prefix child IDs with `ns.`. |
| `qiushi-skill`, `scientific-visualization`, `posterskill`, `paper-polish-workflow-skill` | Current catalog sources | Keep their existing install methods. `scientific-visualization` is the only locally maintained skill. |

### Important upstream-path history

`K-Dense-AI/scientific-agent-skills` previously renamed its skill directory from `scientific-skills/` to `skills/`. A stale sparse path causes the installer error `Sparse path ... not found in repository`. Verify actual upstream paths before changing any `install.sparse_path`.

### Last reviewed but intentionally excluded

On 2026-06-20, `zLanqing/codex-claude-academic-skills` had three useful primary skills and an MIT license, but its full-pack clone failed under the normal Windows installer temporary path: vendored reference files exceeded the Windows filename limit and Git exited 128 after a partial checkout. Do not add it as a `git-clone` pack unless the installer supports safely selecting only the primary skill directories and that path is smoke-tested on Windows.

## Standard refresh procedure

Run these steps in order from the repository root.

1. Rebuild the three expanded collections from their upstream default branches:

   ```powershell
   node scripts/build-skill-index.mjs
   ```

   If this reports `Missing classification for <id> (<path>)`, do not disable the skill just to make the build pass. Read its upstream frontmatter, choose a real category in `scripts/skill-classification.json`, add a Chinese summary in `scripts/skill-translations.zh.json`, add a regression assertion, then rerun the command. Current categories are `research`, `writing`, `visualization`, and `workflow`; research skills may use an appropriate `subdiscipline` or explicit `null`.

2. Refresh GitHub stars for every top-level repository:

   ```powershell
   npm run refresh:stars
   ```

   This calls the public GitHub API. If unauthenticated rate limits cause a 403, set `GITHUB_TOKEN` only in the current shell/CI secret, rerun, and never put the token in the registry, docs, or commit.

3. Regenerate the public catalog artifacts after all registry changes:

   ```powershell
   node scripts/build-slim-index.mjs
   ```

   This writes `site/public/index.slim.json` and mirrors the registry to `site/public/skills.json`.

4. Validate before handing off:

   ```powershell
   node scripts/build-skill-index.mjs --check
   npm run validate:registry
   npm test
   npm run build
   ```

   Use `npm run ci:validate` as the final integrated check after the explicit collection rebuild. If the work changes installer behavior or sources, also run the Bash and PowerShell smoke tests documented in `README.md`.

## Finding and vetting new research packs

### Mandatory owner-approval gate

Discovery and addition are separate actions. An agent may search, inspect, count, and present candidates, but it **must not** add, remove, or modify a community pack in `registry/skills.json`, `site/public/`, installer metadata, or tests until the repository owner explicitly confirms the exact candidate IDs to include. Present each candidate's repository, license state, measured `SKILL.md` count, star snapshot, installation result, overlap/risk assessment, and recommendation first. Treat silence, a general request to search, or a request to refresh existing entries as **not approved**. After explicit confirmation, make only the approved catalog changes and rerun the normal validation procedure.

Use the GitHub API or repository pages as primary sources. Search broadly, then inspect each promising source before adding it. Useful starting searches:

```powershell
$headers = @{ Accept = 'application/vnd.github+json'; 'User-Agent' = 'AcademicForge-catalog-review' }
Invoke-RestMethod -Headers $headers -Uri 'https://api.github.com/search/repositories?q=%22scientific%20agent%20skills%22%20OR%20%22research%20skills%22%20OR%20%22academic%20skills%22&sort=stars&order=desc&per_page=100'
```

For each candidate, inspect its metadata and the actual tree. This distinguishes a usable Agent Skills source from a link list, a mirror, or a repository whose advertised count is stale:

```powershell
$repo = 'OWNER/REPOSITORY'
$metadata = Invoke-RestMethod -Headers $headers -Uri "https://api.github.com/repos/$repo"
$tree = Invoke-RestMethod -Headers $headers -Uri "https://api.github.com/repos/$repo/git/trees/$($metadata.default_branch)?recursive=1"
$skillFiles = @($tree.tree | Where-Object { $_.path -match '(^|/)SKILL\.md$' })
$metadata | Select-Object full_name, stargazers_count, updated_at, archived, license
$skillFiles.path
```

Only include a candidate when all of these are true:

- It has real `SKILL.md` content relevant to research, publishing, reproducibility, analysis, or research workflows.
- It is not archived, its default branch and install path resolve, and its upstream source is attributable.
- Its scope adds practical coverage rather than merely mirroring an existing pack. For example, do not count vendored reference copies as primary skills.
- Its license state is recorded exactly. Prefer clear permissive licenses; a no-license repository may be linked only when its usefulness is strong and the catalog visibly says `No license declared`.
- The skill instructions do not require hidden credentials or unsafe execution merely to install. Read the frontmatter and any installation section before adding it.

When adding an accepted pack, add a top-level object to `registry/skills.json` with `id`, bilingual `name`/`summary`, `author`, `repository`, `license`, measured `skill_count`, current `stars`, tags, `install`, and `post_install`. Use `git-clone` for a full standalone pack. Promote a pack to an expanded collection only when every child can be classified, translated, and installed independently; otherwise retain it as a transparent pack-level choice.

After adding a pack, run `npm run refresh:stars` again so its saved star count is from the same refresh as every other entry.

## Known failure modes

| Symptom | Cause | Correct response |
| --- | --- | --- |
| `Missing classification for ...` | An upstream collection gained a skill. | Add classification, Chinese translation, a regression test, then rebuild. |
| `Classification contains unknown ids` | A local mapping refers to an upstream skill that was renamed or removed. | Verify the default-branch tree; update or mark the old mapping deliberately, never silently delete it. |
| `Sparse path ... not found` | The upstream directory layout changed. | Inspect the tree and correct the sparse path; rebuild and run an installer smoke test. |
| Star refresh fails with 403 | GitHub API rate limit. | Use a temporary environment token; do not persist it. |
| Public site shows old data | Generated artifacts were not rebuilt. | Run `node scripts/build-slim-index.mjs` and inspect `site/public/`. |

## Definition of done

- Every top-level source has a freshly queried star count, valid install metadata, and an accurate measured count.
- Every expanded collection builds with no missing classification or translation.
- New community packs have primary-source evidence, an explicit license state, and a clear reason they belong in an academic catalog.
- `registry/skills.json`, `site/public/skills.json`, and `site/public/index.slim.json` are in sync.
- The validation and test commands above pass, and the change summary states the date/source of the refresh.
