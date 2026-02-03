# 🎓 Academic Forge

<div align="center">

**A curated skill collection for academic writing and research**

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Skills](https://img.shields.io/badge/Skills-3-blue.svg)](./skills)

</div>

## 📖 What is a Forge?

The name "Forge" is inspired by **Minecraft's mod loader system** (like Forge or Fabric), which allows players to run multiple mods together seamlessly. Just as Minecraft Forge provides a modpack that integrates various mods for specific gameplay experiences, **Academic Forge** integrates multiple Claude Code skills for a focused academic writing workflow.

### Why "Forge"?

- 🔧 **Integration over Installation** - Just like Minecraft modpacks, you get a curated collection that works well together
- 🎯 **Purpose-Built** - Each forge targets a specific domain (academic writing, web development, data science, etc.)
- 🔄 **Automatic Updates** - Skills remain linked to their original repositories via git submodules
- 🤝 **Community-Driven** - Built on the excellent work of multiple skill creators

## 🎯 Purpose

Academic Forge solves a common problem: **too many skills lead to poor AI agent accuracy**. By curating only the skills relevant to academic writing and research, Claude Code can:

- ✅ Make more precise skill invocations
- ✅ Avoid confusion between similar skills
- ✅ Maintain focus on your research workflow
- ✅ Stay up-to-date with improvements from original authors

## 📦 Included Skills

This forge integrates the following carefully selected skills:

### [claude-scientific-skills](https://github.com/k-dense-ai/claude-scientific-skills)
- **Author**: [@k-dense-ai](https://github.com/k-dense-ai)
- **License**: MIT
- **Purpose**: Comprehensive scientific paper writing, LaTeX formatting, and academic structure
- **Best For**: Writing papers, managing citations, formatting equations

### [AI-research-SKILLs](https://github.com/orchestra-research/AI-research-SKILLs)
- **Author**: [@orchestra-research](https://github.com/orchestra-research)
- **License**: Check original repository
- **Purpose**: Research methodology, experimental design, and data analysis workflows
- **Best For**: Designing experiments, analyzing results, research planning

### [humanizer](https://github.com/humanizer-org/humanizer)
- **Author**: Humanizer community
- **License**: Check original repository
- **Purpose**: Refining academic tone, improving readability, avoiding AI-detection patterns
- **Best For**: Polishing drafts, maintaining academic voice, peer review preparation

> **Note**: All skills retain their original licenses and authorship. This forge provides convenient integration only. See [ATTRIBUTIONS.md](./ATTRIBUTIONS.md) for detailed credits.

## 🚀 Quick Start

### Installation

Install Academic Forge directly into your Claude Code project:

```bash
# Navigate to your project
cd your-project

# Install the forge
curl -sSL https://raw.githubusercontent.com/your-username/academic-forge/main/scripts/install.sh | bash
```

Or manually:

```bash
# Clone with all submodules
git clone --recursive https://github.com/your-username/academic-forge .opencode/skills/academic-forge

# Or if you already cloned without --recursive
git submodule update --init --recursive
```

### Update Skills

Keep all skills up-to-date with the latest improvements:

```bash
cd .opencode/skills/academic-forge
./scripts/update.sh
```

## 🏗️ Structure

```
academic-forge/
├── README.md              # This file
├── LICENSE                # MIT License for the forge structure
├── ATTRIBUTIONS.md        # Detailed credits for all included skills
├── forge.yaml             # Forge metadata and skill configuration
├── .gitmodules            # Git submodule definitions
├── skills/
│   ├── claude-scientific-skills/    (submodule)
│   ├── AI-research-SKILLs/          (submodule)
│   └── humanizer/                   (submodule)
└── scripts/
    ├── install.sh         # Installation script
    └── update.sh          # Update all skills to latest versions
```

## 🎓 Use Cases

Academic Forge is perfect for:

- 📝 **Writing Research Papers** - From outline to submission-ready manuscript
- 🔬 **Experimental Design** - Planning and documenting research methodology
- 📊 **Data Analysis** - Statistical analysis and result interpretation
- 📚 **Literature Review** - Organizing and synthesizing academic sources
- ✍️ **Thesis Writing** - Long-form academic document management
- 👥 **Collaborative Research** - Maintaining consistent style across team members

## 🔄 Version Management

Academic Forge uses git submodules to track specific versions of each skill:

- **Automatic Updates**: Run `./scripts/update.sh` to pull latest changes
- **Version Locking**: Commit the `.gitmodules` state to lock specific versions
- **Rollback Safety**: Use git to revert to previous working states

## 🤝 Contributing

Found a skill that would be perfect for academic writing? Here's how to contribute:

1. **Suggest a Skill** - Open an issue with the skill repository and use case
2. **Test Compatibility** - Ensure it doesn't conflict with existing skills
3. **Submit PR** - Add as a submodule with proper attribution
4. **Update Docs** - Add to README.md and ATTRIBUTIONS.md

### Creating Your Own Forge

Inspired to create a forge for your domain? Great! Here's the template:

```bash
# Fork this repository
# Replace skills with your domain-specific collection
# Update README.md with your forge's purpose
# Share with the community!
```

## 📄 License

The **forge structure** (scripts, configuration, documentation) is licensed under the [MIT License](./LICENSE).

**Individual skills** retain their original licenses - see [ATTRIBUTIONS.md](./ATTRIBUTIONS.md) and each skill's repository for details.


## 📞 Support

- **Issues**: [GitHub Issues](https://github.com/your-username/academic-forge/issues)
- **Discussions**: [GitHub Discussions](https://github.com/your-username/academic-forge/discussions)
- **Updates**: Watch this repository for new skill additions

---

<div align="center">

**Built with 💙 for the academic research community**

⭐ If this forge helps your research, please star this repo and the individual skill repositories!

</div>
