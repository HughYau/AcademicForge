# 🚀 Quick Start Guide

Get started with Academic Forge in 5 minutes!

## What You'll Get

By installing Academic Forge, you'll have access to:

- ✍️ **Scientific Paper Writing** - LaTeX formatting, proper structure, academic conventions
- 🔬 **Research Methodology** - Experimental design, data analysis, statistical rigor
- 📝 **Academic Tone** - Professional writing style, clarity improvements, polish

All seamlessly integrated into Claude Code for your academic workflow.

## Prerequisites

- [Claude Code](https://claude.ai/code) installed
- [Git](https://git-scm.com/) installed on your system
- A project where you're doing academic writing

## Installation (3 steps)

### Option A: Automatic Installation (Recommended)

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

### Option B: Manual Installation

```bash
# 1. Navigate to your project
cd your-project

# 2. Clone Academic Forge with all skills
git clone --recursive https://github.com/HughYau/academic-forge .opencode/skills/academic-forge

# 3. Restart Claude Code
```

## First Use

1. **Start Claude Code** in your project
2. **Create or open** an academic document
3. **Ask Claude** to help with your writing:

```
"Help me write the introduction for my research paper on [topic]"
"Format this equation in LaTeX"
"Design an experiment to test [hypothesis]"
"Improve the academic tone of this paragraph"
```

Claude will automatically invoke the appropriate skills from the forge!

## Common Use Cases

### Writing a Research Paper

```markdown
You: "I need to write a research paper about machine learning in healthcare. 
     Let's start with an outline."

Claude: *Uses claude-scientific-skills to create proper academic structure*

You: "Now help me design the experimental methodology."

Claude: *Uses AI-research-SKILLs for rigorous research design*

You: "Polish the writing to sound more academic."

Claude: *Uses humanizer to refine tone and style*
```

### Formatting LaTeX

```markdown
You: "Convert this equation to LaTeX: E = mc^2"

Claude: *Uses claude-scientific-skills for proper LaTeX formatting*
```

### Analyzing Results

```markdown
You: "I have these experiment results: [data]. How should I analyze them?"

Claude: *Uses AI-research-SKILLs for statistical analysis guidance*
```

## Updating Skills

Keep your skills up-to-date with the latest improvements:

**macOS/Linux:**
```bash
cd .opencode/skills/academic-forge
./scripts/update.sh
```

**Windows:**
```powershell
cd .opencode/skills/academic-forge
.\scripts\update.ps1
```

## Configuration

You can customize Academic Forge by editing `forge.yaml`:

```yaml
# Enable/disable individual skills
config:
  enabled:
    claude-scientific-skills: true
    AI-research-SKILLs: true
    superpowers: true
    humanizer: true
  
  # Adjust which skills are invoked first
  priority:
    claude-scientific-skills: 10
    AI-research-SKILLs: 9
    superpowers: 8
    humanizer: 7
```

## Troubleshooting

### Skills not loading?

1. Restart Claude Code
2. Check that the forge is in `.opencode/skills/academic-forge`
3. Verify submodules initialized: `git submodule status`
4. Verify `skills/superpowers` exists (synced skills-only snapshot)

### Getting old versions?

Run the update script to pull latest changes:
```bash
./scripts/update.sh  # or update.ps1 on Windows
```

### Conflicts with other skills?

Disable conflicting skills by editing `forge.yaml` or removing them from your main skills directory.

To auto-remove specific upstream skills after sync/install/update, add paths to `scripts/skill-blacklist.txt`.

## Getting Help

- 📚 [Full Documentation](./README.md)
- 💬 [Ask Questions](https://github.com/HughYau/academic-forge/discussions)
- 🐛 [Report Issues](https://github.com/HughYau/academic-forge/issues)

## What's Next?

- Explore the [included skills](./README.md#included-skills) in detail
- Learn about [attribution](./ATTRIBUTIONS.md) and licensing
- Consider [contributing](./CONTRIBUTING.md) a skill suggestion
- Share with your research group! 🎓

---

**Ready to write better papers with AI assistance? Let's get started! 🚀**
