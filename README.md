# 🎓 Academic Forge

<div align="center">

**面向 Claude Code / OpenCode / Codex 的学术 Skill 选配与安装平台**

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

[English](./README_en.md) | 简体中文

</div>

> 分支模型
> - `site-first`：公开站点分支，也是 GitHub Pages、`registry/skills.json` 和安装脚本的来源。
> - `master`：保留旧架构的 legacy 兼容分支。

## 什么是 Academic Forge

Academic Forge 是一个 **site-first catalog + installer**。

你不需要整仓复制全部 skill，只需要：

1. 在站点里浏览和勾选需要的 pack
2. 生成安装命令
3. 在自己的项目根目录执行

核心原则：

- 站点、安装脚本、命令生成都基于同一份 `registry/skills.json`
- `site-first` 是公开入口
- 本仓库只保留一个本地维护 skill：`skills/scientific-visualization`

## 快速开始

### 方式一：使用选配站

打开 `https://hughyau.github.io/AcademicForge/`。

### 方式二：直接运行安装脚本

macOS / Linux:

```bash
cd your-project
curl -sSL https://raw.githubusercontent.com/HughYau/AcademicForge/refs/heads/site-first/scripts/forge-install.sh | bash -s -- \
  --tool claude \
  --skills humanizer,superpowers
```

Windows PowerShell:

```powershell
cd your-project
$script = Join-Path $PWD 'forge-install.ps1'
Invoke-WebRequest -Uri 'https://raw.githubusercontent.com/HughYau/AcademicForge/refs/heads/site-first/scripts/forge-install.ps1' -OutFile $script
& $script -Tool claude -Skills 'humanizer,superpowers'
Remove-Item $script
```

验证安装：

```bash
ls .claude/skills/
ls .opencode/skills/
ls .codex/skills/
```

## 本地维护内容

`site-first` 分支中，唯一保留在仓库内的本地 skill 是：

- `skills/scientific-visualization`

其他 pack 都通过 `registry/skills.json` 描述，并在安装时从各自来源仓库获取。

## 维护 `site-first`

常用本地命令：

```bash
npm run site:install
npm run build
npm run preview
npm run validate:registry
npm run ci:validate
node scripts/build-skill-index.mjs --check
```

本地安装器冒烟测试：

```bash
"D:\Application\Git\bin\bash.exe" scripts/tests/forge-install-local-registry.sh
pwsh -File scripts/tests/forge-install-local-registry.ps1
```

## GitHub Pages

- GitHub Pages 只从 `site-first` 分支部署
- 仓库设置中应把 `Settings -> Pages -> Source` 设为 `GitHub Actions`
- 分支开发阶段用 `npm run preview` 本地预览，不依赖分支级在线预览

## 文档

- [快速入门](./QUICKSTART.md)
- [Skill 归属](./ATTRIBUTIONS.md)
- [site-first 设计 spec](./docs/superpowers/specs/2026-04-16-site-first-light-catalog-repo-design.md)
- [site-first 实施计划](./docs/superpowers/plans/2026-04-16-site-first-branch-implementation.md)

## 许可证

- 仓库结构、站点、脚本和本地内容采用 [MIT](./LICENSE)
- 第三方 skill 保留其各自许可证与作者信息
