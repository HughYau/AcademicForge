# Contributing to Academic Forge

Thank you for your interest in contributing to Academic Forge! 🎓

## What is Academic Forge?

Academic Forge is a **curated skill collection** (inspired by Minecraft modpacks) that integrates multiple Claude Code skills specifically for academic writing and research. It's not a skill itself, but rather a convenient way to install and manage multiple related skills together.

## How to Contribute

### 1. Suggest a New Skill

Have a skill that would be perfect for academic workflows? Here's what we're looking for:

**Good candidates:**
- ✅ Directly supports academic writing or research
- ✅ Has a clear, open-source license
- ✅ Is actively maintained
- ✅ Doesn't conflict with existing skills
- ✅ Adds unique value to the forge

**How to suggest:**
1. Open a [GitHub Issue](https://github.com/your-username/academic-forge/issues/new)
2. Use the template: "Skill Suggestion: [Skill Name]"
3. Provide:
   - Skill repository URL
   - Brief description
   - Why it fits the forge
   - Any potential conflicts you've noticed

### 2. Report Issues

Found a bug or compatibility problem?

1. Check [existing issues](https://github.com/your-username/academic-forge/issues) first
2. Open a new issue with:
   - Clear description of the problem
   - Steps to reproduce
   - Which skill(s) are affected
   - Your environment (OS, Claude Code version)

### 3. Improve Documentation

Documentation improvements are always welcome!

- Fix typos or unclear instructions
- Add examples or use cases
- Improve installation guides
- Translate to other languages

**Process:**
1. Fork the repository
2. Make your changes
3. Submit a pull request

### 4. Add a New Skill to the Forge

**Before adding a skill:**

1. **Permission Check**: Ensure the skill has a license that allows inclusion
2. **Attribution Check**: Verify you can properly credit the original author
3. **Compatibility Test**: Test it with existing skills in the forge
4. **Quality Check**: Ensure the skill is well-documented and maintained

**Adding process:**

```bash
# 1. Fork and clone the forge
git clone https://github.com/your-username/academic-forge.git
cd academic-forge

# 2. Add the skill as a submodule
git submodule add https://github.com/author/skill-name.git skills/skill-name

# 3. Update documentation
# - Add to README.md (Included Skills section)
# - Add to ATTRIBUTIONS.md (with full details)
# - Update forge.yaml (add skill metadata)

# 4. Test the integration
# Install in a test project and verify it works with other skills

# 5. Commit and push
git add .
git commit -m "feat: add skill-name for [purpose]"
git push origin main

# 6. Create pull request
# Include: why the skill is valuable, testing results, attribution info
```

### 5. Update Existing Skills

If you notice a skill is outdated:

```bash
cd skills/skill-name
git pull origin main
cd ../..
git add skills/skill-name
git commit -m "chore: update skill-name to version X.X.X"
```

Or use the update script:
```bash
./scripts/update.sh
```

## Development Guidelines

### Commit Message Convention

We follow [Conventional Commits](https://www.conventionalcommits.org/):

- `feat:` - New skill added
- `fix:` - Bug fix or skill update
- `docs:` - Documentation changes
- `chore:` - Maintenance tasks
- `refactor:` - Restructuring without functionality changes

Examples:
```
feat: add citation-manager skill for BibTeX support
fix: resolve conflict between skill-a and skill-b triggers
docs: clarify installation instructions for Windows users
chore: update all skills to latest versions
```

### Testing Checklist

Before submitting a PR with a new skill:

- [ ] Skill installs correctly via submodule
- [ ] No conflicts with existing skills
- [ ] Attribution added to ATTRIBUTIONS.md
- [ ] Skill listed in README.md
- [ ] Metadata added to forge.yaml
- [ ] Installation tested on at least one OS
- [ ] Documentation is clear and complete

### Code of Conduct

- Be respectful and constructive
- Give credit where it's due
- Assume good intentions
- Help others learn and grow

## Licensing

**Important:** 
- The forge structure (scripts, docs, config) is MIT licensed
- Each skill retains its original license
- When adding a skill, verify license compatibility
- Always provide proper attribution

## Questions?

- 💬 [Open a Discussion](https://github.com/your-username/academic-forge/discussions)
- 🐛 [Report an Issue](https://github.com/your-username/academic-forge/issues)
- 📧 Contact: [your-email]

## Creating Your Own Forge

Inspired to create a forge for a different domain (web development, data science, etc.)?

1. Fork this repository as a template
2. Replace the skills with ones relevant to your domain
3. Update all documentation
4. Share with the community!

We encourage creating specialized forges for different use cases. That's the whole point of the concept! 🎯

---

Thank you for helping make Academic Forge better for the research community! 🙏
