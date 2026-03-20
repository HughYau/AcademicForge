# Changelog

All notable changes to Academic Forge will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.0.0] - 2024-02-03

### Added
- 🎉 Initial release of Academic Forge
- Integrated 3 carefully selected skills for academic writing:
  - claude-scientific-skills (K-Dense-AI)
  - AI-research-SKILLs (orchestra-research)
  - humanizer (community)
- Created installation scripts for bash and PowerShell
- Added automatic update scripts
- Comprehensive documentation:
  - README.md with forge concept explanation
  - ATTRIBUTIONS.md for proper skill credit
  - CONTRIBUTING.md for community guidelines
  - forge.yaml for metadata and configuration
- GitHub Actions workflow for automatic update checking
- MIT license for forge structure
- Git submodule setup for skill management

### Philosophy
- Named "Forge" after Minecraft's mod loader concept
- Focus on solving the "too many skills" accuracy problem
- Curated collection approach over kitchen-sink installation
- Respect for original authors through proper attribution
- Automatic updates while maintaining version control

## [Unreleased]

### Fixed
- **脚本路径修复**: 所有脚本（install/update/download）现在支持从任意目录运行，自动定位仓库根目录
- **planning-with-files 路径适配**: 同步后自动将 opencode 专用路径替换为工具无关路径（兼容 Claude Code / OpenCode / Qita）
- **CI 工作流补全**: 自动更新 PR 现在也会应用技能黑名单、清理 K-Dense 广告、修补 planning-with-files 路径
- **死代码清理**: 移除 update.sh / install.sh 中永远为真的 `$?` 检查

### Added
- **共享函数库**: 新增 `scripts/lib.sh` 和 `scripts/lib.ps1`，消除 7 个文件间的重复代码
- **多工具安装支持**: install 脚本新增 `--tool claude` / `--tool opencode` 参数，默认自动检测目标工具目录
- **forge.yaml 功能化**: `config.enabled` 中设为 `false` 的技能在同步后会被自动移除
- **CLAUDE.md**: 新增项目结构说明文件（已加入 .gitignore）

## [1.1.0] - 2025-06-01

### Added
- Added `planning-with-files` as a skills-only synced source under `skills/planning-with-files`, synced from upstream `.opencode/skills/planning-with-files` (no submodule)
- Updated install/download/update scripts (bash + PowerShell) to sync `planning-with-files` alongside `superpowers`
- Updated automation workflow and documentation to reflect the new skills-only source
- Added local `scientific-visualization` skill documentation (no upstream dependency)
- Updated README/QUICKSTART/ATTRIBUTIONS/forge metadata to include visualization workflow capabilities

### Planned
- Example workflows and use cases
- Video tutorial for installation
- Additional skills pending community feedback
- Integration tests for skill compatibility
- Documentation in multiple languages

---

## Version History

### How Versions Work

- **Major (X.0.0)**: Breaking changes, major restructuring
- **Minor (1.X.0)**: New skills added, significant improvements
- **Patch (1.0.X)**: Bug fixes, documentation updates, skill updates

### Contributing

See [CONTRIBUTING.md](./CONTRIBUTING.md) for how to suggest changes that would appear in future versions.
