# Site-First Light Catalog Repo Design

**Date:** 2026-04-16
**Status:** Approved Design
**Author:** HughYau + OpenCode

---

## 1. Goal

AcademicForge should become a **site-first catalog and installation service**, not a long-lived mirror of upstream skill repositories.

The repository should keep only the assets that are necessary to:

- publish the public configurator site
- define installable skill metadata
- install selected skills into Claude Code, OpenCode, or Codex projects
- maintain the single local skill pack `scientific-visualization`

This means the current hybrid model should be retired:

- no long-term local copies of upstream packs in `skills/`
- no git submodules for upstream skill repositories
- no separate `skills-only` snapshot maintenance flow

### 1.1 Branch Strategy

This design applies to a **dedicated new branch**, not to the legacy `master` branch.

The branch model is:

- `master` remains the legacy line and keeps the pre-site-first repository model for backward compatibility
- the new site-first line begins with commit `a259d1f93c047c404c22111670fa7ae32727b1d4`
- all architectural changes from that commit onward belong to the new branch
- GitHub Pages should deploy from the new branch only

Operationally, this means the repository is intentionally split into two maintained lines:

- a legacy line for historical compatibility
- a site-first line for the new public website and installer flow

The two lines should not be treated as peers for continuous bidirectional merging. They should diverge intentionally, with selective cherry-picks only when needed.

---

## 2. Repository Principle

Adopt this repository rule:

> AcademicForge is a catalog-and-install service, not a long-lived mirror of upstream skill repositories.

This principle drives all structural decisions in this design.

---

## 3. Target Repository Shape

On the new site-first branch, the repository should look like this:

```text
AcademicForge/
├── .github/workflows/
│   ├── deploy-site.yml
│   └── validate.yml
├── docs/
├── registry/
│   └── skills.json
├── scripts/
│   ├── build-skill-index.mjs
│   ├── forge-install.ps1
│   ├── forge-install.sh
│   ├── skill-classification.json
│   └── validate-registry.mjs
├── site/
├── skills/
│   └── scientific-visualization/
├── README.md
├── README_en.md
├── QUICKSTART.md
└── forge.yaml
```

The following upstream mirrors should be removed from the new site-first branch:

- `skills/scientific-agent-skills`
- `skills/AI-research-SKILLs`
- `skills/humanizer`
- `skills/humanizer-zh`
- `skills/paper-polish-workflow-skill`
- `skills/superpowers`

The following git-submodule artifact should be removed from the new site-first branch:

- `.gitmodules`

---

## 4. Runtime Responsibilities

### 4.1 `registry/skills.json`

On the new site-first branch, `registry/skills.json` becomes the only runtime source of truth.

It should define:

- what can be installed
- how each pack or sub-skill is installed
- which post-install steps apply
- which metadata the site displays

Nothing in the checked-in `skills/` tree, except `scientific-visualization`, should be required for runtime behavior.

### 4.2 `site/`

On the new site-first branch, the Astro site remains the public product surface.

It should:

- read `registry/skills.json` at build time
- render pack and sub-skill metadata
- generate install commands in the browser
- avoid any dependency on local upstream mirrors

### 4.3 `scripts/forge-install.sh` and `scripts/forge-install.ps1`

The installers remain the execution layer for end users.

They should:

- read the registry from a URL or local file
- install selected packs or sub-skills by `git-clone` or `sparse-checkout`
- support local testing without requiring publication first
- support the local `scientific-visualization` pack as a first-class entry in the registry
- default to the new site-first branch for hosted registry reads

---

## 5. Registry Contract

Keep the current `skills.json` model centered on install metadata.

Important fields remain:

- `id`
- `name`
- `summary`
- `author`
- `repository`
- `license`
- `skill_count`
- `tags`
- `install`
- `post_install`
- `sub_skills`

### 5.1 Keep `sub_skills`

`sub_skills` should stay.

Reason:

- they are part of the site product, not part of the mirror problem
- they let users install a full pack or a precise sub-skill
- they improve discovery for very large collections

### 5.2 Keep `post_install`

`post_install` should stay.

Reason:

- cleanup such as `clean_ads` is still a service concern
- post-processing should happen after installation, not through repository mirroring

### 5.3 Local pack treatment

`scientific-visualization` remains in this repository and is installed from the AcademicForge repository itself.

Its registry entry should continue to use a repo-local source, for example via `sparse-checkout` of `skills/scientific-visualization`.

### 5.4 Add install ref pinning

Because the new public site and installer flow live on a dedicated branch, registry entries should support branch pinning for repository-backed installs.

Recommended field:

- `install.ref`

Usage:

- for remote packs that should follow a specific branch or tag, the installer may pass that ref to `git clone --branch`
- for local packs such as `scientific-visualization`, `install.ref` should point to the new site-first branch so that end users do not accidentally install the legacy `master` version

The site should generate commands consistent with this branch pinning strategy.

---

## 6. Upstream Metadata Sync Model

The old model syncs upstream content into this repository.

The new model should sync **metadata only**.

### 6.1 `build-skill-index.mjs`

`scripts/build-skill-index.mjs` should be retained but redesigned.

Current behavior:

- scans checked-in upstream directories under `skills/`
- derives `sub_skills` from those local copies

New behavior:

- clone required upstream repos into temporary directories only
- use sparse checkout when possible
- read frontmatter and folder structure from those temporary clones
- generate `sub_skills` into `registry/skills.json`
- delete temporary clones at the end of the run

This preserves the rich registry while removing the need to store upstream content in the repository.

### 6.2 `skill-classification.json`

Keep `scripts/skill-classification.json`.

It still provides classification and subdiscipline metadata for generated `sub_skills`.

### 6.3 Replace blacklist-as-files with blacklist-as-metadata

The repository should stop relying on a post-sync file deletion blacklist.

Current model:

- sync upstream files into `skills/`
- remove blacklisted paths afterward

New model:

- skip disallowed items during registry generation
- keep exclusion rules in metadata form, not as repository cleanup

Recommended implementation:

- retire `scripts/skill-blacklist.txt`
- move exclusions into `skill-classification.json` or an equivalent JSON config
- support a flag such as `disabled: true` for entries that should not appear in the registry

---

## 7. Script Cleanup

The following legacy scripts are tied to the mirror-based model and should be removed:

- `scripts/install.sh`
- `scripts/install.ps1`
- `scripts/update.sh`
- `scripts/update.ps1`
- `scripts/download-skills.sh`
- `scripts/download-skills.ps1`
- `scripts/lib.sh`
- `scripts/lib.ps1`
- `scripts/uninstall.sh`
- `scripts/uninstall.ps1`
- `scripts/SKILLS-DOWNLOAD-README.md`

The following verification/listing scripts should also be removed or replaced because they assume full local `skills/*` mirrors exist:

- `scripts/list-skills.sh`
- `scripts/list-skills.ps1`
- `scripts/verify.sh`
- `scripts/verify.ps1`

### 7.1 New validation script

Add `scripts/validate-registry.mjs`.

It should validate at least:

- valid JSON structure
- unique `id` values across packs and sub-skills
- valid `install.method`
- presence of `install.sparse_path` when method is `sparse-checkout`
- presence of local path `skills/scientific-visualization` when referenced
- no unresolved parent-child metadata errors

### 7.2 Optional smoke-test scripts

Add lightweight smoke-test wrappers if needed:

- `scripts/smoke-install.sh`
- `scripts/smoke-install.ps1`

These should install selected targets into a temporary directory using the local registry.

---

## 8. Installer Changes

The Bash and PowerShell installers should be extended for local development and pre-merge testing.

### 8.1 Add local registry override

Add one new parameter to both installers:

- Bash: `--registry <path-or-url>`
- PowerShell: `-Registry <path-or-url>`

Behavior:

- if omitted, use the current GitHub raw URL
- if a local path is provided, read the local file directly
- if a URL is provided, fetch it remotely

This enables testing updated registry data before pushing to GitHub.

If no override is provided, the default hosted registry URL should point to the new site-first branch, not to `master`.

### 8.2 Keep custom install path

Keep the existing custom path support:

- Bash: `--path <dir>`
- PowerShell: `-Path <dir>`

This allows safe installs into a temporary test location.

### 8.3 Required test scenario

The installers should be able to handle this mixed install successfully:

- one remote pack such as `superpowers`
- one local pack such as `scientific-visualization`

That scenario is the minimum smoke test for the new architecture.

---

## 9. CI and Automation

### 9.1 `deploy-site.yml`

Keep the GitHub Pages deployment workflow.

Its job remains:

- install site dependencies
- build the Astro site
- upload `site/dist`
- deploy through GitHub Actions Pages

The workflow should continue to trigger when relevant public site inputs change, especially:

- `site/**`
- `registry/**`

It should deploy from the new site-first branch rather than from `master`.

### 9.2 Add `validate.yml`

Add a separate validation workflow.

It should run on changes to:

- `registry/**`
- `scripts/**`
- `site/**`
- `skills/scientific-visualization/**`

It should run checks such as:

- registry validation
- site build
- optional installer smoke tests

This separates correctness checks from deployment.

### 9.3 Remove mirror-update automation

The old update workflow should no longer maintain repository mirrors.

`check-updates.yml` should either:

- be removed entirely, or
- be repurposed to validate that configured upstream repositories remain reachable and structurally compatible

It should not update checked-in submodules or checked-in upstream content anymore.

---

## 10. Documentation Changes

The documentation should be rewritten to match the new service model.

### 10.1 README and QUICKSTART

Update these docs so that they:

- describe AcademicForge as a site-first catalog and installer
- stop describing the repository as an upstream mirror bundle
- remove contributor guidance based on `submodule` and `update.sh`
- explain that only `scientific-visualization` is maintained locally
- explain that `master` is the legacy compatibility line and the site-first architecture lives on the new branch

### 10.2 `forge.yaml`

`forge.yaml` should be simplified.

Remove legacy mirror-era semantics such as:

- `hybrid-submodule-and-skills-sync`
- repository-local enable/disable switches for mirrored packs
- notes that describe ongoing submodule maintenance as a core architecture rule

Keep only metadata that still serves the service architecture.

---

## 11. Local Testing Workflow

Before merging or pushing, local testing should follow this sequence.

### 11.1 Site development preview

```bash
npm run site:install
npm run dev
```

Use this for:

- UI iteration
- card rendering
- filtering behavior
- install command generation behavior

### 11.2 Production-like preview

```bash
npm run build
npm run preview
```

Use this for:

- verifying the Astro production build
- checking the configured base path `/AcademicForge`
- catching issues that do not appear in dev mode

### 11.3 Installer smoke test

After the `--registry` / `-Registry` option is added, the expected test commands are:

```bash
bash scripts/forge-install.sh --tool opencode --skills superpowers,scientific-visualization --registry ./registry/skills.json --path ./tmp/opencode-skills
```

```powershell
.\scripts\forge-install.ps1 -Tool opencode -Skills 'superpowers,scientific-visualization' -Registry .\registry\skills.json -Path .\tmp\opencode-skills
```

Check that:

- `tmp/opencode-skills/superpowers/` exists
- `tmp/opencode-skills/scientific-visualization/` exists
- directory layout matches tool expectations
- remote and local install entries both work in one run

---

## 12. GitHub Pages Deployment Workflow

The repository should continue to deploy the site through GitHub Pages using GitHub Actions.

### 12.1 Repository settings

In GitHub repository settings:

- open `Settings -> Pages`
- set `Source` to `GitHub Actions`

### 12.2 Release flow

Recommended release sequence:

1. run `npm run build`
2. run `npm run preview`
3. run the installer smoke test using the local registry
4. push the approved changes to the new site-first branch
5. let GitHub Actions build and deploy the site
6. verify the live site at `https://hughyau.github.io/AcademicForge/`

### 12.3 Preview boundary

GitHub Pages should be treated as the single production site, not as a branch-preview system.

Therefore:

- use local preview for branch work
- use the production deploy only after changes are ready
- do not rely on `workflow_dispatch` branch deployments as a normal preview workflow because they can overwrite the public site

---

## 13. Migration Plan

Recommended migration order:

1. create the new site-first branch using the line that begins at `a259d1f93c047c404c22111670fa7ae32727b1d4`
2. update the site and installers so all hosted URLs point to the new branch, not `master`
3. add local-registry support to both installers
4. add `install.ref` support for repository-backed installs
5. add `validate-registry.mjs`
6. redesign `build-skill-index.mjs` to use temporary upstream clones
7. add `validate.yml`
8. update docs to reflect the site-first architecture and the legacy role of `master`
9. remove mirror-era scripts from the new branch
10. remove `.gitmodules` from the new branch
11. remove checked-in upstream skill mirrors from the new branch
12. keep only `skills/scientific-visualization`
13. verify local build, preview, and installer smoke test before release

This order keeps the service working while the mirror-based architecture is dismantled.

---

## 14. Success Criteria

The migration is complete when all of the following are true:

- the new public website and installer flow live on a dedicated branch that starts with `a259d1f93c047c404c22111670fa7ae32727b1d4`
- `master` remains available as the legacy compatibility line
- the repository contains no upstream skill submodules
- the repository keeps only `skills/scientific-visualization` as local skill content
- the site builds from `registry/skills.json` without local upstream mirrors
- installers can read a local registry for pre-push testing
- installers can install both remote and local entries successfully
- hosted registry reads and generated install commands no longer point to `master`
- CI validates registry and site changes separately from deployment
- GitHub Pages deploys successfully from `site/dist`
- documentation no longer describes the repository as a hybrid mirror system

---

## 15. Out of Scope

This design does not include:

- user accounts
- branch preview environments
- automatic GitHub discovery of new skill repositories
- community rating or review systems
- turning AcademicForge into a hosted backend service with persistent server-side state

The target remains a static site plus install tooling, not a full hosted SaaS backend.
