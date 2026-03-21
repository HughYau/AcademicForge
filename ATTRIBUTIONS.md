# Attributions and Credits

This project integrates skills from multiple authors in the Claude Code ecosystem. We are deeply grateful for their contributions and want to ensure proper credit is given.

## How This Forge Works

Academic Forge uses a **hybrid integration model**:

- Most skills are linked via git submodules
- `paper-polish-workflow-skill` is linked via git submodule
- `superpowers` is synced as a skills-only snapshot from upstream `skills/`
- `planning-with-files` is synced as a single skills-only folder from upstream `.opencode/skills/planning-with-files`
- `scientific-visualization` is maintained locally in this repository (no upstream dependency)

This means:

- ✅ All original LICENSE files are preserved
- ✅ External skills link directly to their source repositories
- ✅ Authors receive proper credit and GitHub attribution
- ✅ Updates flow from the original repositories
- ✅ `superpowers` and `planning-with-files` are intentionally limited to skills-only content to keep this forge focused
- ✅ Local custom skills remain fully transparent in this repository's git history

## Included Skills

### 1. claude-scientific-skills

**Original Repository**: [k-dense-ai/claude-scientific-skills](https://github.com/k-dense-ai/claude-scientific-skills)

- **Author**: k-dense-ai
- **License**: MIT License
- **Included Version**: See `.gitmodules` for current commit hash
- **Purpose**: Scientific paper writing, LaTeX formatting, citation management
- **Modifications**: None (used as-is via git submodule)
- **Original License Text**: See `skills/claude-scientific-skills/LICENSE`

**Why we included it**: The most comprehensive scientific skills collection available, with 140 ready-to-use skills spanning 15+ scientific domains. Includes deep integration with 28+ scientific databases (PubMed, OpenAlex, ChEMBL, UniProt), 55+ specialized Python packages (BioPython, RDKit, DeepChem, Scanpy), and complete workflows from literature review through publication. Essential for any researcher working in bioinformatics, cheminformatics, clinical research, or computational biology.

---

### 2. AI-research-SKILLs

**Original Repository**: [orchestra-research/AI-research-SKILLs](https://github.com/orchestra-research/AI-research-SKILLs)

- **Author**: orchestra-research
- **License**: Check original repository for license details
- **Included Version**: See `.gitmodules` for current commit hash
- **Purpose**: Research methodology, experimental design, data analysis
- **Modifications**: None (used as-is via git submodule)
- **Original License Text**: See `skills/AI-research-SKILLs/LICENSE`

**Why we included it**: The gold standard for AI research engineering workflows, with 82 expert-level skills covering the complete research lifecycle. Each skill contains ~420 lines of detailed documentation plus 300KB+ reference materials. Covers cutting-edge frameworks across model architecture (LitGPT, Mamba, RWKV), training (Axolotl, DeepSpeed, FSDP), post-training (TRL, OpenRLHF), inference (vLLM, TensorRT-LLM), and evaluation (lm-eval-harness). Invaluable for researchers and engineers working on LLMs, multimodal models, or publishing ML papers at top-tier conferences (NeurIPS, ICML, ICLR).

---

### 3. humanizer

**Original Repository**: [humanizer-org/humanizer](https://github.com/humanizer-org/humanizer)

- **Author**: Humanizer community contributors
- **License**: Check original repository for license details
- **Included Version**: See `.gitmodules` for current commit hash
- **Purpose**: Academic tone refinement, readability improvement
- **Modifications**: None (used as-is via git submodule)
- **Original License Text**: See `skills/humanizer/LICENSE`

**Why we included it**: Helps refine academic writing to maintain appropriate scholarly tone while improving clarity and readability.

---

### 4. superpowers (skills-only)

**Original Repository**: [obra/superpowers](https://github.com/obra/superpowers)

- **Author**: obra
- **License**: MIT License
- **Included Version**: Synced snapshot of `skills/` (see git history for latest sync commit)
- **Purpose**: Structured development workflow skills (planning, debugging, TDD, review workflows)
- **Modifications**: Integrated as skills-only content under `skills/superpowers` (plugin/non-skill directories are intentionally excluded)
- **Original License Text**: See upstream `obra/superpowers` repository

**Why we included it**: Adds battle-tested workflow skills like brainstorming, writing-plans, systematic-debugging, and test-driven-development that complement academic and research implementation workflows.

---

### 5. planning-with-files (skills-only single folder)

**Original Repository**: [OthmanAdi/planning-with-files](https://github.com/OthmanAdi/planning-with-files)

- **Author**: OthmanAdi
- **License**: MIT License
- **Included Version**: Synced snapshot of `.opencode/skills/planning-with-files` (see git history for latest sync commit)
- **Purpose**: Manus-style file-based planning and session persistence for complex tasks
- **Modifications**: Integrated as skills-only content under `skills/planning-with-files` (not as a submodule)
- **Original License Text**: See upstream `OthmanAdi/planning-with-files` repository

**Why we included it**: Adds durable planning primitives (`task_plan.md`, `findings.md`, `progress.md`) and session catchup scripts that are especially useful for long-running research and implementation work.

---

### 6. paper-polish-workflow-skill

**Original Repository**: [Lylll9436/Paper-Polish-Workflow-skill](https://github.com/Lylll9436/Paper-Polish-Workflow-skill)

- **Author**: Lylll9436
- **License**: MIT License
- **Included Version**: See `.gitmodules` for current commit hash
- **Purpose**: End-to-end academic paper translation, polishing, review simulation, and submission workflow
- **Modifications**: None (used as-is via git submodule)
- **Original License Text**: See `skills/paper-polish-workflow-skill/LICENSE`

**Why we included it**: It adds a tightly integrated paper-writing workflow pack that complements Academic Forge's research and visualization skills with bilingual translation, polishing, reviewer simulation, literature search, and submission-focused helpers.

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

## License Compliance

This forge's structure (configuration files, scripts, documentation) is licensed under MIT. However, **each included skill retains its original license**. When using Academic Forge, you must comply with:

1. The MIT License of this forge's structure
2. The individual license of each skill you use

### License Summary

| Skill | License | Commercial Use | Attribution Required |
|-------|---------|----------------|---------------------|
| claude-scientific-skills | MIT | ✅ Yes | ✅ Yes |
| AI-research-SKILLs | TBD* | Check repo | Check repo |
| humanizer | TBD* | Check repo | Check repo |
| superpowers | MIT | ✅ Yes | ✅ Yes |
| planning-with-files | MIT | ✅ Yes | ✅ Yes |
| scientific-visualization | MIT | ✅ Yes | ✅ Yes |

*Please check the original repository for current license information.

## How to Give Credit

If you use this forge in your work, we appreciate (but don't require) acknowledgment:

### In Academic Papers

```
We used the Academic Forge skill collection for Claude Code
(https://github.com/HughYau/academic-forge), which integrates
skills from k-dense-ai, orchestra-research, and the humanizer community.
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
4. You use a traceable integration method (prefer submodule; skills-only sync is acceptable when justified)

## Version History

This document tracks which versions of each skill are included:

| Date | Skill | Version/Commit | Change |
|------|-------|----------------|--------|
| 2024-XX-XX | claude-scientific-skills | abc123... | Initial inclusion |
| 2024-XX-XX | AI-research-SKILLs | def456... | Initial inclusion |
| 2024-XX-XX | humanizer | ghi789... | Initial inclusion |
| 2026-02-15 | superpowers (skills-only) | synced from obra/superpowers/skills | Initial inclusion |
| 2026-03-04 | planning-with-files (skills-only folder) | synced from OthmanAdi/planning-with-files/.opencode/skills/planning-with-files | Initial inclusion |
| 2026-03-21 | paper-polish-workflow-skill | submodule from Lylll9436/Paper-Polish-Workflow-skill | Initial inclusion |
| 2026-03-04 | scientific-visualization (local) | tracked in this repository | Initial inclusion |

To see the current linked submodule versions, run:
```bash
git submodule status
```

For `superpowers` and `planning-with-files` (skills-only syncs), check the latest sync commits in this repository's git history. For `scientific-visualization`, check normal file history in this repository.

---

## Thank You

This forge exists because of the generosity of open-source contributors who share their work freely. Thank you to all skill creators for making the Claude Code ecosystem richer and more powerful! 🙏

