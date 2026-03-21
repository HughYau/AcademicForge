# 🎓 Academic Forge

<div align="center">

**A curated skill collection for academic writing and research**

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Skills](https://img.shields.io/badge/Skills-7-blue.svg)](./skills)

</div>

## 📖 What is a Forge?

The name "Forge" is inspired by **Minecraft's mod loader system** — just as Minecraft Forge provides modpacks that integrate various mods for specific gameplay experiences, **Academic Forge** integrates multiple AI coding assistant skills for an academic writing workflow.

- 🔧 **Integration over Installation** - A curated collection that works well together, not scattered installs
- 🎯 **Purpose-Built** - Only academic-relevant skills, avoiding the accuracy drop from too many skills
- 🔄 **Automatic Updates** - Skills stay current via git submodules plus skills-only sync
- 🤝 **Community-Driven** - Built on the excellent work of multiple skill creators

## 🚀 Quick Start

### Installation

**macOS/Linux:**
```bash
cd your-project
curl -sSL https://raw.githubusercontent.com/HughYau/AcademicForge/refs/heads/master/scripts/install.sh | bash
```

**Windows (PowerShell):**
```powershell
cd your-project
irm https://raw.githubusercontent.com/HughYau/AcademicForge/refs/heads/master/scripts/install.ps1 | iex
```

**Specify target tool (optional):**
```bash
bash install.sh --tool claude     # Install to .claude/skills/
bash install.sh --tool opencode   # Install to .opencode/skills/
bash install.sh /custom/path      # Custom path
```

> Without `--tool`, the script auto-detects: prefers `.claude/` if it exists, otherwise `.opencode/`.

### Verify Installation

```bash
bash scripts/verify.sh       # Check all skills are properly installed
bash scripts/list-skills.sh  # List all installed skills
```

### After Installation

Start using it right away — **skills are automatically triggered** during your conversations, no manual invocation needed.

**Try these prompts:**
- "Help me outline a research paper about deep learning in LaTeX"
- "Analyze this CSV data and generate publication-ready figures"
- "Plan a multi-step experiment and track progress with files"
- "Polish this abstract to match academic writing standards"

## 📦 Included Skills

| Skill Pack | Count | Best For | Source |
|------------|-------|----------|--------|
| [claude-scientific-skills](https://github.com/k-dense-ai/claude-scientific-skills) | 140 | Scientific writing, LaTeX, citations, databases | [@k-dense-ai](https://github.com/k-dense-ai) |
| [AI-research-SKILLs](https://github.com/zechenzhangAGI/AI-research-SKILLs) | 82 | AI research methods, training, inference, evaluation | [@zechenzhangAGI](https://github.com/zechenzhangAGI) |
| [superpowers](https://github.com/obra/superpowers) | 15 | Planning, debugging, TDD, code review | [@obra](https://github.com/obra) |
| [planning-with-files](https://github.com/OthmanAdi/planning-with-files) | 1 | File-based task management, context persistence | [@OthmanAdi](https://github.com/OthmanAdi) |
| [paper-polish-workflow-skill](https://github.com/Lylll9436/Paper-Polish-Workflow-skill) | 15 | Paper translation, polishing, review simulation, and submission workflow | [@Lylll9436](https://github.com/Lylll9436) |
| [scientific-visualization](./skills/scientific-visualization) | 1 | Publication-ready figures, colorblind-safe palettes | Local |
| [humanizer](https://github.com/blader/humanizer) | 1 | Academic tone refinement, readability | [@blader](https://github.com/blader) |

> All skills retain their original licenses and authorship. See [ATTRIBUTIONS.md](./ATTRIBUTIONS.md) for detailed credits.

<details>
<summary><b>📋 View detailed skill descriptions</b></summary>

### claude-scientific-skills (140 Skills)
- **License**: MIT
- **Coverage**: 140 ready-to-use scientific skills across 15+ domains
- **What It Includes**:
  - 🧬 **Bioinformatics & Genomics** - BioPython, Scanpy, single-cell RNA-seq, variant annotation
  - 🧪 **Cheminformatics & Drug Discovery** - RDKit, DeepChem, molecular docking, virtual screening
  - 🏥 **Clinical Research** - ClinicalTrials.gov, ClinVar, FDA databases, pharmacogenomics
  - 📊 **Data Analysis** - Statistical analysis, matplotlib, seaborn, publication figures
  - 📚 **Scientific Communication** - LaTeX formatting, citation management, peer review
  - 🔬 **Laboratory Automation** - PyLabRobot, Benchling, Opentrons integration
  - 🤖 **Machine Learning** - PyTorch Lightning, scikit-learn, deep learning workflows
  - 📚 **Databases** - 28+ scientific databases (PubMed, OpenAlex, ChEMBL, UniProt, etc.)
- **Best For**: Multi-step scientific workflows from literature review to publication
- **Ad Sanitization**: Each install/download/update run automatically strips embedded promotional sections from all SKILL.md files, keeping skill content clean

### AI-research-SKILLs (82 Skills)
- **License**: MIT
- **Coverage**: 82 expert-level AI research engineering skills across 20 categories
- **What It Includes**:
  - 🏗️ **Model Architecture** - LitGPT, Mamba, RWKV, NanoGPT, TorchTitan (5 skills)
  - 🎯 **Fine-Tuning** - Axolotl, LLaMA-Factory, PEFT, Unsloth (4 skills)
  - 🎓 **Post-Training** - TRL, GRPO, OpenRLHF, SimPO, verl (8 skills for RLHF/DPO)
  - ⚡ **Distributed Training** - DeepSpeed, FSDP, Megatron-Core, Accelerate (6 skills)
  - 🚀 **Optimization** - Flash Attention, bitsandbytes, GPTQ, AWQ (6 skills)
  - 🔥 **Inference** - vLLM, TensorRT-LLM, SGLang, llama.cpp (4 skills)
  - 📊 **Evaluation** - lm-eval-harness, BigCode, NeMo Evaluator (3 skills)
  - 🤖 **Agents & RAG** - LangChain, LlamaIndex, Chroma, FAISS (9 skills)
  - 🎨 **Multimodal** - CLIP, Whisper, LLaVA, Stable Diffusion (7 skills)
  - 📝 **ML Paper Writing** - LaTeX templates for NeurIPS, ICML, ICLR, ACL (1 skill)
- **Documentation Quality**: ~420 lines per skill + 300KB+ reference materials
- **Best For**: AI research workflows from hypothesis to paper publication

### humanizer
- **License**: Check original repository
- **Purpose**: Refining academic tone, improving readability, avoiding AI-detection patterns
- **Best For**: Polishing drafts, maintaining academic voice, peer review preparation

### superpowers (skills-only)
- **License**: MIT
- **Purpose**: Structured development workflow skills emphasizing **design first, implement, then verify**
- **Key Skills**: brainstorming, writing-plans, executing-plans, systematic-debugging, test-driven-development, code-review, verification-before-completion
- **Integration Mode**: Syncs only the upstream `skills/` directory (no plugin or non-skill folders)

### planning-with-files (skills-only)
- **License**: MIT
- **Purpose**: Manus-style file-based planning with `task_plan.md`, `findings.md`, and `progress.md`
- **Best For**: Long multi-step implementation or research tasks that need durable planning and session recovery
- **Integration Mode**: Syncs only upstream `.opencode/skills/planning-with-files`

### paper-polish-workflow-skill (15 Skills)
- **License**: MIT
- **Coverage**: A full paper-writing workflow pack with 1 coordinating meta-skill plus 14 focused sub-skills under `.claude/skills/`
- **What It Includes**:
  - translation, polishing, de-AI rewriting, reviewer simulation
  - abstract, cover letter, experiment analysis, caption writing
  - logic checking, literature search, visualization recommendations
  - repo-to-paper, team orchestration, and update helpers
- **Best For**: Taking a draft from bilingual translation through polishing, self-review, submission packaging, and literature-grounded revision

### scientific-visualization (local built-in)
- **License**: MIT
- **Purpose**: Publication-ready scientific figures with journal-specific style templates, colorblind-safe palettes, multi-panel layouts, and export optimization

</details>

## 🛡️ Defenses Against Prompt Injection & Context Pollution

To prevent potential **Prompt Injection attacks** (which might hijack AI behavior) or irrelevant advertisements from upstream Skills, this repository implements built-in security and sanitization mechanisms to keep your assistant's context clean:

- **Blacklist Filtering**: Via `scripts/skill-blacklist.txt`, the installation and update scripts automatically remove specific upstream files known to contain malicious prompts, low-quality instructions, or confusing context.
- **Post-Prompt Sanitization (Clean-AdInsertions)**: After downloading and syncing upstream content, the configuration runs sanitization functions (such as `Clean-AdInsertions`) that use Regex pattern matching to strip out irrelevant third-party platform promotions, sponsor advertisements, and other attached commands. This ensures that the provided context fed to the AI assistant remains safe and pure.

## �🔧 Managing Skills

### Update

```bash
./scripts/update.sh  # or Windows: .\scripts\update.ps1
```

> All scripts can be run from any directory — they auto-detect the repository root.

### Configuration

Edit `config.enabled` in `forge.yaml` to enable/disable specific skill packs:

```yaml
config:
  enabled:
    claude-scientific-skills: true
    paper-polish-workflow-skill: true
    humanizer: false  # Set to false to remove on next sync
```

To block specific upstream skills (not entire packs), edit `scripts/skill-blacklist.txt`.

### Automatic Updates

This repository runs automated workflows to update all upstream skill sources **every Monday at 09:00 UTC**.

## ❓ FAQ

**Q: How are skills triggered? Do I need to call them manually?**
A: No. Skills are automatically selected and invoked by the AI assistant based on your prompts. Just chat normally.

**Q: Will this many skills slow things down?**
A: No. Skills are reference information for the AI, not runtime overhead. Response speed is unaffected.

**Q: How is this different from installing skills individually?**
A: Academic Forge curates compatible skill combinations, avoids conflicts, and provides one-click install, automatic updates, and ad sanitization.

**Q: How do I uninstall?**
A: Run `bash scripts/uninstall.sh` (Windows: `.\scripts\uninstall.ps1`), or simply delete the installation directory.

## 🎓 Use Cases

- 📝 **Writing Research Papers** - From outline to submission-ready manuscript
- 🔬 **Experimental Design** - Planning and documenting research methodology
- 📊 **Data Analysis** - Statistical analysis and result interpretation
- 🖼️ **Scientific Figures** - Creating and polishing publication-quality plots
- 📚 **Literature Review** - Organizing and synthesizing academic sources
- ✍️ **Thesis Writing** - Long-form academic document management

## 🏗️ Structure

```
academic-forge/
├── forge.yaml             # Forge metadata and skill enable/disable config
├── skills/
│   ├── claude-scientific-skills/    (submodule)
│   ├── AI-research-SKILLs/          (submodule)
│   ├── humanizer/                   (submodule)
│   ├── paper-polish-workflow-skill/ (submodule)
│   ├── superpowers/                 (skills-only sync)
│   ├── planning-with-files/         (skills-only sync)
│   └── scientific-visualization/    (local built-in)
└── scripts/
    ├── lib.sh / lib.ps1             # Shared functions
    ├── install.sh/.ps1              # Installation
    ├── update.sh/.ps1               # Update all skills
    ├── download-skills.sh/.ps1      # Download/re-sync skills
    ├── verify.sh/.ps1               # Verify installation
    ├── list-skills.sh/.ps1          # List installed skills
    └── uninstall.sh/.ps1            # Uninstall
```

## 📄 Documentation

- [Quick Start Guide](./QUICKSTART.md) - Get started in 5 minutes
- [Usage Examples](./EXAMPLES.md) - Real-world workflow examples
- [Skill Credits](./ATTRIBUTIONS.md) - Detailed authorship and licensing
- [Contributing Guide](./CONTRIBUTING.md) - How to contribute or create your own forge

## 🤝 Contributing

Found a skill that would be perfect for academic writing? See [CONTRIBUTING.md](./CONTRIBUTING.md) for how to:

- Suggest new skills
- Report issues
- Improve documentation
- Create your own domain-specific forge

## 📄 License

The **forge structure** (scripts, configuration, documentation) is licensed under the [MIT License](./LICENSE).

**Individual skills** retain their original licenses - see [ATTRIBUTIONS.md](./ATTRIBUTIONS.md) and each skill's repository.

## 📞 Support

- **Issues**: [GitHub Issues](https://github.com/HughYau/AcademicForge/issues)
- **Discussions**: [GitHub Discussions](https://github.com/HughYau/AcademicForge/discussions)

## Star History

<a href="https://www.star-history.com/?repos=HughYau%2FAcademicForge&type=date&logscale=&legend=top-left">
 <picture>
   <source media="(prefers-color-scheme: dark)" srcset="https://api.star-history.com/image?repos=HughYau/AcademicForge&type=date&theme=dark&legend=top-left" />
   <source media="(prefers-color-scheme: light)" srcset="https://api.star-history.com/image?repos=HughYau/AcademicForge&type=date&legend=top-left" />
   <img alt="Star History Chart" src="https://api.star-history.com/image?repos=HughYau/AcademicForge&type=date&legend=top-left" />
 </picture>
</a>
---

<div align="center">

**Built with 💙 for the academic research community**

⭐ If this forge helps your research, please star this repo and the individual skill repositories!

</div>
