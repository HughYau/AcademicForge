# Attributions and Credits

This project integrates skills from multiple authors across the AI agent ecosystem. We are deeply grateful for their contributions and want to ensure proper credit is given.

## How This Forge Works

Academic Forge uses a **hybrid integration model**:

- Most skills are described in `registry/skills.json` and installed from their upstream repositories on demand
- Large upstream collections are scanned into categorized `sub_skills` entries for the site-first catalog
- `superpowers` is installed from upstream `skills/` via sparse checkout
- `scientific-visualization` is maintained locally in this repository (no upstream dependency)
- `claude-science` (Anthropic's Claude Science skills) is maintained locally as a categorized collection and installs by sparse-checkout of this repo — no subscription required

This means:

- ✅ External license metadata and source links are preserved in the registry
- ✅ External skills link directly to their source repositories
- ✅ Authors receive proper credit and GitHub attribution
- ✅ Updates flow from the original repositories
- ✅ `superpowers` is intentionally limited to skills-only content to keep this forge focused
- ✅ Local custom skills remain fully transparent in this repository's git history

## Included Skills

### 1. scientific-agent-skills

**Original Repository**: [K-Dense-AI/scientific-agent-skills](https://github.com/K-Dense-AI/scientific-agent-skills)

- **Author**: K-Dense-AI
- **License**: MIT License
- **Included Version**: Installed from the current upstream default branch at install time
- **Purpose**: Scientific and research workflows for any AI agent
- **Modifications**: None (installed from upstream via git clone, or sparse checkout for individual sub-skills)
- **Original License Text**: See upstream `LICENSE.md`

**Why we included it**: The most comprehensive scientific skills collection available, now published as Scientific Agent Skills. As of the 2026-08-08 refresh it provides 160 ready-to-use scientific and research skills, broad AI-agent compatibility via the open Agent Skills standard, coverage across 15+ domains, and deep integration with scientific databases and optimized Python package workflows.

---

### 2. AI-research-SKILLs

**Original Repository**: [Orchestra-Research/AI-Research-SKILLs](https://github.com/Orchestra-Research/AI-Research-SKILLs)

- **Author**: Orchestra-Research
- **License**: MIT License
- **Included Version**: Installed from the current upstream default branch at install time
- **Purpose**: Research methodology, experimental design, data analysis
- **Modifications**: None (installed from upstream via git clone, or sparse checkout for individual sub-skills)
- **Original License Text**: See upstream `LICENSE`

**Why we included it**: The gold standard for AI research engineering workflows, with 98 expert-level skills covering the complete research lifecycle. Each skill contains detailed documentation and reference materials. Covers cutting-edge frameworks across model architecture (LitGPT, Mamba, RWKV), training (Axolotl, DeepSpeed, FSDP), post-training (TRL, OpenRLHF), inference (vLLM, TensorRT-LLM), and evaluation (lm-eval-harness). Invaluable for researchers and engineers working on LLMs, multimodal models, or publishing ML papers at top-tier conferences (NeurIPS, ICML, ICLR).

---

### 3. humanizer

**Original Repository**: [blader/humanizer](https://github.com/blader/humanizer)

- **Author**: blader (Siqi Chen)
- **License**: MIT License
- **Included Version**: Installed from the current upstream default branch at install time
- **Purpose**: Academic tone refinement, readability improvement
- **Modifications**: None (installed from upstream via git clone)
- **Original License Text**: See upstream `LICENSE`

**Why we included it**: Helps refine academic writing to maintain appropriate scholarly tone while improving clarity and readability.

---

### 4. humanizer-zh

**Original Repository**: [op7418/Humanizer-zh](https://github.com/op7418/Humanizer-zh)

- **Author**: op7418
- **License**: MIT License
- **Included Version**: Installed from the current upstream default branch at install time
- **Purpose**: Chinese de-AI rewriting, naturalization, and Chinese academic polishing
- **Modifications**: None (installed from upstream via git clone)
- **Original License Text**: See upstream `LICENSE`

**Why we included it**: Complements `humanizer` with a Chinese-first variant for more natural Chinese abstracts, paper sections, and bilingual revision workflows.

---

### 5. superpowers (skills-only)

**Original Repository**: [obra/superpowers](https://github.com/obra/superpowers)

- **Author**: obra
- **License**: MIT License
- **Included Version**: Installed from the current upstream default branch at install time
- **Purpose**: Structured development workflow skills (planning, debugging, TDD, review workflows)
- **Modifications**: None. Installed by sparse checkout of the upstream `skills/` directory only, so plugin/non-skill directories are intentionally excluded.
- **Original License Text**: See upstream `obra/superpowers` repository

**Why we included it**: Adds battle-tested workflow skills like brainstorming, writing-plans, systematic-debugging, and test-driven-development that complement academic and research implementation workflows. The upstream `skills/` directory holds 14 skills as of the 2026-08-08 refresh.

---

### 6. paper-polish-workflow-skill

**Original Repository**: [Lylll9436/Paper-Polish-Workflow-skill](https://github.com/Lylll9436/Paper-Polish-Workflow-skill)

- **Author**: Lylll9436
- **License**: MIT License
- **Included Version**: Installed from the current upstream default branch at install time
- **Purpose**: End-to-end academic paper translation, polishing, review simulation, and submission workflow
- **Modifications**: None (installed from upstream via git clone)
- **Original License Text**: See upstream `LICENSE`

**Why we included it**: It adds a tightly integrated paper-writing workflow pack that complements Academic Forge's research and visualization skills with bilingual translation, polishing, reviewer simulation, literature search, and submission-focused helpers. The pack holds 16 skills as of the 2026-08-08 refresh.

---

### 7. scientific-visualization (local built-in)

**Source**: Local skill maintained in this repository at `skills/scientific-visualization`

- **Author**: Academic Forge contributors
- **License**: MIT License (inherits this forge's repository license)
- **Included Version**: Tracked directly by this repository's commit history
- **Purpose**: Publication-focused scientific plotting and figure polishing (matplotlib/seaborn/plotly)
- **Modifications**: First-party local skill, no upstream mirror/submodule
- **Original License Text**: See root `LICENSE`

**Why we included it**: Academic projects regularly fail quality bars at the figure stage. This skill directly targets publication-readiness (layout consistency, accessibility-safe colors, export formats, and journal-oriented styling), which strongly complements writing and research-methodology skills.

---

### 8. nature-skills

**Original Repository**: [Yuan1z0825/nature-skills](https://github.com/Yuan1z0825/nature-skills)

- **Author**: Yuan1z0825 / Yuan Yizhe
- **License**: Apache-2.0
- **Included Version**: Installed from the current upstream default branch
- **Purpose**: Nature-style academic writing, polishing, citations, data availability, figures, paper reading, reviewer responses, slides, statistics reporting, reference verification, and literature search
- **Modifications**: None (installed from upstream via git clone or sparse checkout for sub-skills)
- **Original License Text**: See upstream `LICENSE`

**Why we included it**: It provides a focused Nature-family publication workflow that complements Academic Forge's research, writing, citation, figure, and revision workflows with practical Chinese-author support. The pack holds 19 skills as of the 2026-08-08 refresh; `ns.nature-shared` is an internal shared-reference package that the other Nature skills load, so select it alongside them when installing individual sub-skills.

---

### 9. claude-science (local built-in, by Anthropic)

**Source**: Anthropic's Claude Science skills, maintained locally in this repository at `skills/claude-science`

- **Author**: Anthropic
- **License**: Apache-2.0 (most skills; a few bundle their own `LICENSE.txt`)
- **Included Version**: Tracked directly by this repository's commit history
- **Purpose**: 32 skills spanning protein structure & design (AlphaFold2, Boltz, Chai-1, ESMFold2, OpenFold3, ProteinMPNN, LigandMPNN, SolubleMPNN, DiffDock), genomics & single-cell (Borzoi, Evo 2, ESM-2, scGPT, scvi-tools), publication figures (figure-composer, figure-style, algorithmic-art, web-artifacts-builder), literature & narrative (literature-review, paper-narrative, indication-dossier, pdf-explore), and workflow/compute (compute-env-setup, remote-compute, model endpoints, skill-creator, learn, customize)
- **Modifications**: Collection root filed under "Workflow & Process" as *Claude Science*; each sub-skill is re-classified into research / writing / figures / workflow. Content is unmodified.
- **Original License Text**: See each skill's frontmatter and the bundled `LICENSE.txt` where present.

**Why we included it**: These are Anthropic's own first-party research skills. Hosting them locally in this repo means they install by sparse-checkout **without a Claude Science subscription**, work **across agents** (Claude Code / OpenCode / Codex), and run **on Windows** — while staying fully transparent in this repository's git history.

---

### 10. andrej-karpathy-skills

**Original Repository**: [multica-ai/andrej-karpathy-skills](https://github.com/multica-ai/andrej-karpathy-skills)

- **Author**: multica-ai
- **License**: No license file declared upstream — see the repository before redistributing
- **Included Version**: Installed from the current upstream default branch at install time
- **Purpose**: A single workflow skill encoding four coding principles — Think Before Coding, Simplicity First, Surgical Changes, Goal-Driven Execution
- **Modifications**: None. Installed by sparse checkout of the upstream `skills/` directory only.
- **Original License Text**: None published upstream at the time of review

**Why we included it**: Research code drifts toward accidental complexity. This pack gives a short, opinionated discipline for keeping analysis code minimal and verifiable, complementing the heavier workflow packs.

---

### 11. qiushi-skill

**Original Repository**: [HughYau/qiushi-skill](https://github.com/HughYau/qiushi-skill)

- **Author**: HughYau
- **License**: MIT License
- **Included Version**: Installed from the current upstream default branch at install time
- **Purpose**: Chinese-first academic writing and research workflow helpers
- **Modifications**: None (installed from upstream via git clone)
- **Original License Text**: See upstream `LICENSE`

**Why we included it**: It covers Chinese-language academic conventions that the Nature-family and English-first packs do not, and it is maintained by this project's author, so breakage is fixable quickly.

---

### 12. posterskill

**Original Repository**: [ethanweber/posterskill](https://github.com/ethanweber/posterskill)

- **Author**: ethanweber
- **License**: No license file declared upstream — see the repository before redistributing
- **Included Version**: Installed from the current upstream default branch at install time
- **Purpose**: Conference poster generation
- **Modifications**: None (installed from upstream via git clone)
- **Original License Text**: None published upstream at the time of review

**Why we included it**: Poster production is a recurring, deadline-driven academic task that the writing and figure packs do not cover end to end.

---

### 13. academic-humanizer

**Original Repository**: [AIScientists-Dev/academic-humanizer](https://github.com/AIScientists-Dev/academic-humanizer)

- **Author**: AIScientists-Dev (Jie Ding, University of Minnesota)
- **License**: MIT License — the upstream `LICENSE` adds a notice that the work builds on [blader/humanizer](https://github.com/blader/humanizer) (MIT) and adopts standards from [koaeraser/ARMS](https://github.com/koaeraser/ARMS)
- **Included Version**: Installed from the current upstream default branch at install time
- **Purpose**: Remove AI-writing tells from manuscripts, theses, rebuttals, and NSF/NIH proposals while preserving scholarly conventions, author voice, and claim-to-evidence discipline
- **Modifications**: None (installed from upstream via git clone)
- **Original License Text**: See upstream `LICENSE`

**Why we included it**: It is the most carefully scoped skill in this category. Where general humanizers flatten academic precision, this one is layered — strip AI tells, then explicitly preserve calibrated hedging, passive voice, citations, and numbers; then enforce that no verb outruns its evidence; then calibrate to the author's own prior accepted writing; then shift register for proposal mode. The upstream README is explicit that it does not generate findings, alter data or citations, and is not built to evade AI-use disclosure. It is also the tool [*Nature* covered in July 2026](https://www.nature.com/articles/d41586-026-02105-3), which makes the scope limits worth reading alongside it. Featured first under **Writing & polishing**.

---

## License Compliance

This forge's structure (configuration files, scripts, documentation) is licensed under MIT. However, **each included skill retains its original license**. When using Academic Forge, you must comply with:

1. The MIT License of this forge's structure
2. The individual license of each skill you use

### License Summary

Verified against each upstream repository on 2026-08-08.

| Skill | License | Commercial Use | Attribution Required |
|-------|---------|----------------|---------------------|
| scientific-agent-skills | MIT | ✅ Yes | ✅ Yes |
| AI-research-SKILLs | MIT | ✅ Yes | ✅ Yes |
| academic-humanizer | MIT | ✅ Yes | ✅ Yes |
| humanizer | MIT | ✅ Yes | ✅ Yes |
| humanizer-zh | MIT | ✅ Yes | ✅ Yes |
| superpowers | MIT | ✅ Yes | ✅ Yes |
| paper-polish-workflow-skill | MIT | ✅ Yes | ✅ Yes |
| scientific-visualization | MIT | ✅ Yes | ✅ Yes |
| nature-skills | Apache-2.0 | ✅ Yes | ✅ Yes |
| claude-science | Apache-2.0† | ✅ Yes | ✅ Yes |
| qiushi-skill | MIT | ✅ Yes | ✅ Yes |
| andrej-karpathy-skills | None declared* | ⚠️ Check repo | ⚠️ Check repo |
| posterskill | None declared* | ⚠️ Check repo | ⚠️ Check repo |

*No `LICENSE` file is published upstream. Default copyright applies: the code is readable on GitHub but not clearly licensed for redistribution or commercial use. Contact the author before relying on it in a commercial or redistributed product.

†Most Claude Science skills are Apache-2.0; a few bundle their own `LICENSE.txt` — check each skill's frontmatter.

## How to Give Credit

If you use this forge in your work, we appreciate (but don't require) acknowledgment:

### In Academic Papers

```
We used the Academic Forge skill collection for Claude Code
(https://github.com/HughYau/academic-forge), which integrates
skills from k-dense-ai, orchestra-research, blader, and op7418.
```

### In Projects

Add to your README.md:

```markdown
This project uses [Academic Forge](https://github.com/HughYau/academic-forge)
for AI-assisted academic writing.
```

### On Social Media

```
Writing my paper with @ClaudeAI and Academic Forge - amazing integration
of skills from @k-dense-ai and @orchestra-research! 🎓
```

## Supporting Original Authors

The best way to support the creators of these skills:

1. ⭐ **Star their repositories** on GitHub
2. 🐛 **Report bugs** or suggest improvements directly to their repos
3. 💬 **Share their work** with others in the community
4. 🤝 **Contribute** to their projects if you can
5. 💰 **Sponsor** them if they have sponsorship options

## Reporting Attribution Issues

If you are an author of one of these skills and have concerns about attribution or licensing:

1. Open an issue on this repository
2. We will respond within 48 hours and make necessary corrections

We are committed to proper attribution and respecting all licenses.

## Contributing New Skills

Want to add a skill to this forge? Please ensure:

1. The skill has a clear, open-source license
2. You have permission to include it (or it's clearly licensed for redistribution)
3. You provide full attribution in this document
4. You use a traceable integration method in `registry/skills.json`

## Version History

This document tracks which versions of each skill are included:

| Date | Skill | Version/Commit | Change |
|------|-------|----------------|--------|
| 2024-XX-XX | scientific-agent-skills | abc123... | Initial inclusion |
| 2026-04-13 | scientific-agent-skills | upstream rename + metadata refresh | Migrated submodule path and project references from `claude-scientific-skills` |
| 2024-XX-XX | AI-research-SKILLs | def456... | Initial inclusion |
| 2024-XX-XX | humanizer | ghi789... | Initial inclusion |
| 2026-04-03 | humanizer-zh | submodule from op7418/Humanizer-zh | Initial inclusion |
| 2026-02-15 | superpowers (skills-only) | synced from obra/superpowers/skills | Initial inclusion |
| 2026-03-21 | paper-polish-workflow-skill | submodule from Lylll9436/Paper-Polish-Workflow-skill | Initial inclusion |
| 2026-03-04 | scientific-visualization (local) | tracked in this repository | Initial inclusion |
| 2026-05-17 | nature-skills | installed from Yuan1z0825/nature-skills | Initial inclusion |
| 2026-07-02 | claude-science (local) | tracked in this repository | Initial inclusion of Anthropic's 32 Claude Science skills as a categorized local collection |
| 2026-08-08 | scientific-agent-skills | upstream default branch | Catalog refresh: 149 → 160 skills; upstream replaced `iso-13485-certification` with the broader `iso-standards-readiness` |
| 2026-08-08 | nature-skills | upstream default branch | Catalog refresh: 15 → 19 skills; **license corrected from MIT to Apache-2.0** |
| 2026-08-08 | superpowers | upstream default branch | Measured count corrected 15 → 14 |
| 2026-08-08 | paper-polish-workflow-skill | upstream default branch | Measured count corrected 15 → 16 |
| 2026-08-08 | humanizer | upstream default branch | License recorded exactly: "See repository" → MIT |
| 2026-08-08 | andrej-karpathy-skills, qiushi-skill, posterskill | upstream default branch | Attribution sections added (previously listed in the registry but undocumented here) |
| 2026-08-11 | academic-humanizer | installed from AIScientists-Dev/academic-humanizer | Initial inclusion; pinned first under Writing & polishing via the new `featured` registry flag |

Packs are no longer vendored as git submodules. Every non-local pack is fetched from its upstream
default branch at install time by `scripts/forge-install.sh` / `scripts/forge-install.ps1`, so the
"included version" is whatever upstream HEAD is when a user installs. For the two local packs
(`claude-science`, `scientific-visualization`), check normal file history in this repository.

---

## Thank You

This forge exists because of the generosity of open-source contributors who share their work freely. Thank you to all skill creators for making the AI agent ecosystem richer and more powerful! 🙏

