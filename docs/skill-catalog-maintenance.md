# AcademicForge Skill Catalog Maintenance

> Give this file to an agent whenever it is asked to refresh, repair, or extend the AcademicForge skill catalog. It contains the operating procedure and the project-specific context it needs; do not rely on an old conversation for catalog facts.
>
> Last verified against the repository on 2026-08-30.

## Scope and source of truth

- The authoritative catalog is [`registry/skills.json`](../registry/skills.json). Never edit `site/public/skills.json` or `site/public/index.slim.json` by hand: they are generated copies.
- The catalog lives on `site-first`, the project's main (default) branch. There is no separate legacy branch.
- `skill_count` means the number of `SKILL.md` files that this pack intentionally exposes. Count actual files; never infer it from a README. For an expanded collection the indexer overwrites this field with the number of sub-skills it actually collected, so do not hand-edit it there.
- The catalog currently contains **13 top-level packs**. **Four** are expanded into individually selectable sub-skills; the remaining nine are installed as a complete pack.
- Two packs are maintained inside this repository under [`skills/`](../skills) (`claude-science`, `scientific-visualization`). They install by sparse-checkout of AcademicForge itself, so their `stars` value is AcademicForge's own star count, not an upstream project's.
- Star counts are a timestamped snapshot, not a permanent fact. Always refresh them in the same run that changes the catalog.
- `is_collection` and `sub_skills` are written by `scripts/build-skill-index.mjs`. Treat them as generated fields inside an otherwise hand-maintained file.
- An optional `featured: true` flag pins a pack to the top of its category on the site. It is hand-set and deliberately rare — `academic-humanizer` is the only entry using it. The indexer and validator ignore it; the site's sorting reads it.

## Read this before editing

1. Check that the worktree is safe to change:

   ```powershell
   git status --short
   git branch --show-current
   ```

   Preserve unrelated user changes. The expected public branch is `site-first`.

2. Read the current entries and generated-file rules in `registry/skills.json`, `scripts/build-skill-index.mjs`, `scripts/lib/skill-collections.mjs`, `scripts/lib/skill-index.mjs`, and `scripts/validate-registry.mjs`.

3. Read the existing regression tests. There are two suites and `npm test` runs both:

   - `scripts/tests/build-skill-index.test.mjs` and `scripts/tests/validate-registry.test.mjs` (catalog and installer behavior)
   - `site/src/lib/*.test.mjs` (site-side filtering, install-command generation, card display)

   Add a failing test before changing indexer behavior or correcting a known upstream-drift failure.

## Existing sources and their special handling

| ID | Upstream | Install/index rule |
| --- | --- | --- |
| `superpowers` | `obra/superpowers` | Sparse checkout of `skills/`; installed as one pack (not expanded). |
| `andrej-karpathy-skills` | `multica-ai/andrej-karpathy-skills` | Sparse checkout of `skills/`; single skill. |
| `claude-science` | Local, `skills/claude-science/` | Expanded collection, `local: true`. Read from disk with no clone; child IDs prefixed `cs.`; each child installs by sparse-checkout of `HughYau/AcademicForge`. Credited to `anthropics` (Apache-2.0). |
| `scientific-agent-skills` | `K-Dense-AI/scientific-agent-skills` | Expanded collection: clone `skills/`, prefix child IDs with `sa.`. Top-level install is `git-clone` with the `clean_ads` post-install step. |
| `AI-research-SKILLs` | `Orchestra-Research/AI-Research-SKILLs` | Expanded collection: scan the repository root (`relativeRoot: ''`, `includeRootSkill: true`), prefix child IDs with `air.`. |
| `nature-skills` | `Yuan1z0825/nature-skills` | Expanded collection: clone `skills/`, prefix child IDs with `ns.`. |
| `scientific-visualization` | Local, `skills/scientific-visualization/` | Single locally maintained skill; sparse-checkout of `HughYau/AcademicForge`. |
| `humanizer` / `humanizer-zh` | `blader/humanizer`, `op7418/Humanizer-zh` | Full pack clone. |
| `academic-humanizer` | `AIScientists-Dev/academic-humanizer` | Full pack clone; single skill. Carries `featured: true` so the site pins it first under Writing & polishing. Its MIT `LICENSE` has an added attribution preamble, so the GitHub API reports `NOASSERTION` — see the license note in step 2. |
| `qiushi-skill`, `posterskill`, `paper-polish-workflow-skill` | `HughYau/qiushi-skill`, `ethanweber/posterskill`, `Lylll9436/Paper-Polish-Workflow-skill` | Full pack clone; keep their existing install methods. |

### Important upstream-path history

`K-Dense-AI/scientific-agent-skills` previously renamed its skill directory from `scientific-skills/` to `skills/`. A stale sparse path causes the installer error `Sparse path ... not found in repository`. Verify actual upstream paths before changing any `install.sparse_path` or a collection's `clonePath`.

The same upstream also renames individual skills. On or before 2026-08-08 it replaced `skills/iso-13485-certification` with the broader `skills/iso-standards-readiness` (ISO 13485 + 14971 + 17025 + 15189). The old id was retired from `scripts/skill-classification.json` and `scripts/skill-translations.zh.json`, and the `retired upstream skill ids are not resurrected` test in `scripts/tests/build-skill-index.test.mjs` records the decision. Expect more of these: a `Classification contains unknown ids` failure naming a single skill is usually a rename, so look for its replacement before deleting anything.

### Last reviewed but intentionally excluded

- On 2026-06-20, `zLanqing/codex-claude-academic-skills` had three useful primary skills and an MIT license, but its full-pack clone failed under the normal Windows installer temporary path: vendored reference files exceeded the Windows filename limit and Git exited 128 after a partial checkout. Do not add it as a `git-clone` pack unless the installer supports safely selecting only the primary skill directories and that path is smoke-tested on Windows.
- `academic-research-skills`, `deep-research-skills`, `phd-skills`, and `voidful-academic-skills` were surveyed but never approved by the owner.

All five exclusions are locked in by the `registry excludes community packs that have not received user approval` test in `scripts/tests/build-skill-index.test.mjs`. If the owner later approves one of them, update that test in the same change — do not delete the assertion to make a build pass.

## Standard refresh procedure

Run these steps in order from the repository root.

1. Rebuild the expanded collections. The default run clones every remote collection from its upstream default branch:

   ```powershell
   node scripts/build-skill-index.mjs
   ```

   Use `--only` to rebuild a subset — the practical way to work on the local collection with no network access:

   ```powershell
   node scripts/build-skill-index.mjs --only claude-science
   ```

   In `--only` mode, classification entries belonging to skipped collections are ignored rather than reported as unknown.

   If the build reports `Missing classification for <id> (<path>)`, do not disable the skill just to make it pass. Read its upstream frontmatter, choose a real category in `scripts/skill-classification.json`, add a Chinese summary in `scripts/skill-translations.zh.json`, add a regression assertion, then rerun. Categories are `research`, `writing`, `visualization`, and `workflow`. Research skills carry a `subdiscipline` — currently `life-sci`, `chem-mat-phys`, `earth-geo`, `lab-automation`, `multimodal`, `llm`, `other`, or an explicit `null`. Non-research categories usually omit the field.

   A classification entry supports `disabled: true`, which makes the indexer skip that skill silently. No entry uses it today; it is for genuinely unusable upstream skills, not a shortcut around classification work.

2. Refresh GitHub stars for every top-level repository:

   ```powershell
   npm run refresh:stars
   ```

   This calls the public GitHub API, rewrites `registry/skills.json` only when a count actually changed, and exits nonzero if any repository failed. If unauthenticated rate limits cause a 403, set `GITHUB_TOKEN` only in the current shell/CI secret, rerun, and never put the token in the registry, docs, or a commit.

   Nothing automates the other two per-source facts, so check both by hand in the same run:

   - **Measured count for the nine non-expanded packs.** `refresh:stars` does not touch `skill_count`, and the indexer only recomputes it for the four collections. Count `SKILL.md` files in the upstream tree (scoped to `install.sparse_path` when one is set) and compare. The 2026-08-08 refresh found `superpowers` at 15 → 14 and `paper-polish-workflow-skill` at 15 → 16; the 2026-08-30 refresh found all nine already correct.
   - **The leading number inside `summary.en` / `summary.zh`.** For collections the indexer rewrites it; for a non-expanded pack it is plain prose and will silently contradict `skill_count` unless you edit both.
   - **License state.** Re-read `license` from the GitHub API rather than trusting the stored value. The 2026-08-08 refresh found `nature-skills` recorded as MIT when upstream ships Apache-2.0, and `humanizer` recorded as `See repository` when upstream ships MIT. For the two local packs the stored value describes the *skill content* (Apache-2.0 for Anthropic's Claude Science, MIT for `scientific-visualization`), not AcademicForge's own repository license — the API's `NOASSERTION` for those is expected and not a defect.

     `NOASSERTION` from the API means "a `LICENSE` file exists but does not match a known template verbatim", which is not the same as unlicensed. `academic-humanizer` reports it because its otherwise-standard MIT text carries an added upstream-attribution paragraph; `MIT` is the correct recorded state there. Read the actual `LICENSE` before changing a recorded value on the strength of an API mismatch.

3. Regenerate the public catalog artifacts after all registry changes:

   ```powershell
   node scripts/build-slim-index.mjs
   ```

   This writes `site/public/index.slim.json` (top-level entries plus every sub-skill, each tagged with its parent `collection`) and mirrors the registry to `site/public/skills.json`. `npm run build:agent-index` is the same command, and `npm run build` runs it before the site build.

4. Update the hand-maintained companions when sources changed. None of these are generated:

   - `site/public/agents.md` — the agent-facing guide served next to the catalog.
   - `ATTRIBUTIONS.md` — per-source credit and license notes, one numbered section per pack plus a license-summary table and a dated version-history table. All 13 packs have a section as of 2026-08-30; add one for any pack you introduce, and append a version-history row for every refresh that changes a count or a license.
   - `README.md` / `README_en.md` — these avoid hardcoded pack counts on purpose; keep it that way.

5. Validate before handing off:

   ```powershell
   node scripts/build-skill-index.mjs --check
   npm run validate:registry
   npm test
   npm run build
   ```

   `--check` prints the per-collection totals without writing the registry, but it still clones every remote collection — it is a verification run, not an offline one. Pair it with `--only` if you are deliberately working offline.

   `npm run validate:registry` catches duplicate skill ids, unsupported `install.method` values, `sparse-checkout` entries missing a `sparse_path`, local packs whose `sparse_path` does not exist on disk, and any `summary.zh` that was left equal to the English text.

   `npm run ci:validate` (`validate:registry` → `test` → `build`) is the final integrated check after the explicit collection rebuild. It does **not** rebuild the collections, so run step 1 first.

6. If the work touches installer behavior or install metadata, run the installer smoke tests directly. `npm run test:scripts` already covers the PowerShell installer's failure exit code; these three cover real end-to-end installs against a temporary local registry and require `git` plus `python` on PATH:

   ```bash
   bash scripts/tests/forge-install-local-registry.sh
   bash scripts/tests/forge-install-multiple-sparse-checkouts.sh
   ```

   ```powershell
   pwsh -File scripts/tests/forge-install-local-registry.ps1
   ```

   Windows behavior is not optional to verify — long paths under a temporary directory are a recurring failure mode for this project.

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
- Its license state is recorded exactly. Prefer clear permissive licenses; a no-license repository may be linked only when its usefulness is strong and the catalog visibly says `No license declared`. Existing entries also use `See repository` where upstream ships no `LICENSE` file but states terms elsewhere.
- The skill instructions do not require hidden credentials or unsafe execution merely to install. Read the frontmatter and any installation section before adding it.

When adding an accepted pack, add a top-level object to `registry/skills.json` with `id`, bilingual `name`/`summary`, `author`, `repository`, `license`, measured `skill_count`, current `stars`, `tags`, `install`, and `post_install` (use `[]` when there is nothing to do). Use `git-clone` for a full standalone pack and `sparse-checkout` with a `sparse_path` when only a subdirectory is wanted. Promote a pack to an expanded collection — a new entry in `scripts/lib/skill-collections.mjs` — only when every child can be classified, translated, and installed independently; otherwise retain it as a transparent pack-level choice.

After adding a pack, run `npm run refresh:stars` again so its saved star count is from the same refresh as every other entry, then work through the whole standard refresh procedure including the companion docs.

## Known failure modes

| Symptom | Cause | Correct response |
| --- | --- | --- |
| `Missing classification for <id> (<path>)` | An upstream collection gained a skill. | Add classification, Chinese translation, a regression test, then rebuild. |
| `Classification contains unknown ids` | A local mapping refers to an upstream skill that was renamed or removed. | Verify the default-branch tree; update or mark the old mapping deliberately, never silently delete it. |
| `Missing frontmatter in <file>` / `Missing description in <file>` | An upstream `SKILL.md` lost or malformed its YAML frontmatter. | Confirm upstream, then fix the source or exclude that one skill deliberately — do not patch the parser around it. |
| `Sparse path ... not found` | The upstream directory layout changed. | Inspect the tree and correct the sparse path; rebuild and run an installer smoke test. |
| `--only references unknown collection(s)` | Typo, or the collection is not registered in `scripts/lib/skill-collections.mjs`. | Use a `rootSkillId` from that file. |
| `Local pack '<id>' is missing from <path>` | A registry entry claims a local `sparse_path` that no longer exists under `skills/`. | Restore the directory or fix `install.sparse_path`. |
| `Skill '<id>' has untranslated summary.zh` | A new entry shipped with the English summary copied into `summary.zh`. | Write a real Chinese summary. |
| Star refresh fails with 403 | GitHub API rate limit. | Use a temporary environment token; do not persist it. |
| Public site shows old data | Generated artifacts were not rebuilt. | Run `node scripts/build-slim-index.mjs` and inspect `site/public/`. |

## Definition of done

- Every top-level source has a freshly queried star count, valid install metadata, and an accurate measured count.
- Every expanded collection builds with no missing classification or translation.
- New community packs have explicit owner approval, primary-source evidence, an explicit license state, and a clear reason they belong in an academic catalog.
- `registry/skills.json`, `site/public/skills.json`, and `site/public/index.slim.json` are in sync.
- `site/public/agents.md` and `ATTRIBUTIONS.md` reflect any source change.
- The validation and test commands above pass, and the change summary states the date/source of the refresh.
