# Attributions and Credits

This project integrates skills from multiple authors in the Claude Code ecosystem. We are deeply grateful for their contributions and want to ensure proper credit is given.

## How This Forge Works

Academic Forge uses **git submodules** to include skills from their original repositories. This means:

- ✅ All original LICENSE files are preserved
- ✅ Skills link directly to their source repositories
- ✅ Authors receive proper credit and GitHub attribution
- ✅ Updates flow from the original repositories
- ✅ No code is copied or redistributed without proper linking

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
4. You add it as a git submodule (not a copy) to maintain the link to the original

## Version History

This document tracks which versions of each skill are included:

| Date | Skill | Version/Commit | Change |
|------|-------|----------------|--------|
| 2024-XX-XX | claude-scientific-skills | abc123... | Initial inclusion |
| 2024-XX-XX | AI-research-SKILLs | def456... | Initial inclusion |
| 2024-XX-XX | humanizer | ghi789... | Initial inclusion |

To see the current versions, run:
```bash
git submodule status
```

---

## Thank You

This forge exists because of the generosity of open-source contributors who share their work freely. Thank you to all skill creators for making the Claude Code ecosystem richer and more powerful! 🙏
