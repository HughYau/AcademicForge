<p align="center">
  <img src="./assets/academicforge-banner.svg" alt="Academic Forge 头图" />
</p>


# 🎓 Academic Forge

<div align="center">

**面向 Claude Code / OpenCode / Codex 的学术 Skill 选配与安装平台**

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

<p align="center">
  <a href="https://hughyau.github.io/AcademicForge/">
    <img src="https://img.shields.io/badge/%E4%B8%80%E9%94%AE%E4%BD%93%E9%AA%8C-Academic%20Forge-blue?style=for-the-badge" alt="一键体验 Academic Forge">
  </a>
</p>

[English](./README_en.md) | 简体中文

</div>


> ✨ **新增：内置 Claude Science（Anthropic 出品）的 32 个技能**
> - 覆盖蛋白质结构与设计、基因组、单细胞、发表级图表、文献综述、远程算力等
> - **无需订阅 Claude Science** 即可安装，**跨 agent 通用**（Claude Code / OpenCode / Codex），**支持 Windows**（PowerShell 安装脚本）
> - 作为本地维护集合收录在 `skills/claude-science`，在目录中归类为「流程与方法 · Claude Science」，其下每个技能再按科研 / 写作 / 图表等分类展示

## 🔨 什么是 Academic Forge

"Forge（锻造台）" 灵感来自 **Minecraft 的模组加载器系统**——就像 Minecraft Forge 整合包为特定游戏体验集成各种模组一样，**Academic Forge** 把散落各处的学术 AI 技能，锻造成一套趁手的工具箱。🎓

不用整仓复制全部 skill，三步搞定：

1. 🖱️ 在站点里浏览、勾选需要的 pack
2. 📋 一键生成安装命令
3. ⚡ 在自己的项目根目录里执行

核心原则：

- 🧩 站点、安装脚本、命令生成都基于同一份 `registry/skills.json`
- 🌿 `site-first` 是唯一公开入口
- 📦 本仓库本地维护两组内容：`skills/scientific-visualization` 与 `skills/claude-science`（Anthropic 的 Claude Science 内置技能集合）

## 🚀 快速开始

### 🖱️ 方式一：使用选配站

打开 `https://hughyau.github.io/AcademicForge/`，勾选需要的 skill pack、选择你的平台（Claude Code / OpenCode / Codex），一键生成安装命令。

<p align="center">
  <video src="https://github.com/user-attachments/assets/3b539896-6380-4ac4-9ae9-9b79ed7adaf3" controls width="960">
  </video>
</p>

### ⌨️ 方式二：直接运行安装脚本

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

已安装的同名 skill 会被跳过并提示；追加 `--force`（PowerShell 为 `-Force`）可覆盖更新。

### 🤖 方式三：让你的 AI 替你挑选

不知道选什么？把下面这段提示词交给你的 AI 智能体（Claude Code / OpenCode / Codex 均可）：

> 请获取并阅读 https://hughyau.github.io/AcademicForge/agents.md，按其中的说明了解我的研究需求，然后从 AcademicForge 目录中为我挑选合适的学术 skills 并生成安装命令。

站点右下角的「不知道选什么？」卡片可以一键复制（会自动带上你已选择的工具与平台）。智能体可读的目录索引：

- 指南：`https://hughyau.github.io/AcademicForge/agents.md`
- 瘦索引：`https://hughyau.github.io/AcademicForge/index.slim.json`
- 完整 registry 镜像：`https://hughyau.github.io/AcademicForge/skills.json`

验证安装：

```bash
ls .claude/skills/
ls .opencode/skills/
ls .codex/skills/
```

## 📦 本地维护内容

`site-first` 分支中，保留在仓库内本地维护的内容有：

- `skills/scientific-visualization` — 单个本地 skill
- `skills/claude-science` — **Claude Science**（Anthropic）内置技能集合，共 32 个技能。作为集合根归类在「流程与方法（Workflow & Process）」下、名为 *Claude Science*、作者 *Anthropic*；其下每个子技能再按科研 / 写作 / 图表等分类。因为直接托管在本仓库，所以**无需订阅 Claude Science** 即可通过 sparse-checkout 安装，**跨 agent 通用并支持 Windows**。

  编辑该目录后，用以下命令仅重建此集合的索引（无需联网克隆其他集合）：

  ```bash
  node scripts/build-skill-index.mjs --only claude-science
  node scripts/build-slim-index.mjs
  ```

其他 pack 都通过 `registry/skills.json` 描述，并在安装时从各自来源仓库获取。

## 🔬 Claude Science 技能清单（32 个）

下面按主题整理了 [`skills/claude-science`](./skills/claude-science) 收录的全部 32 个技能。只想安装这一套：

```bash
curl -sSL https://raw.githubusercontent.com/HughYau/AcademicForge/refs/heads/site-first/scripts/forge-install.sh | bash -s -- --tool claude --skills claude-science
```

**六大主题**：🧬 结构预测与对接 · ✏️ 蛋白质设计与嵌入 · 🧫 基因组与单细胞 · 📊 图表与可视化 · ✍️ 文献与写作 · ⚙️ 算力与工作流

<details>
<summary><b>展开查看全部 32 个 Claude Science 技能</b></summary>

### 🧬 结构预测与对接（6）

| Skill | 用途 |
|-------|------|
| [alphafold2](./skills/claude-science/alphafold2) | AlphaFold2 / AF2-Multimer 折叠单体与复合物（ColabFold 运行器） |
| [openfold3](./skills/claude-science/openfold3) | AlphaFold3 的开源权重 PyTorch 复现（AlQuraishi Lab） |
| [boltz](./skills/claude-science/boltz) | Boltz-2 预测蛋白 / 核酸 / 小分子复合物，可选结合亲和力 |
| [chai1](./skills/claude-science/chai1) | Chai-1 基础模型预测抗体-抗原、蛋白-配体复合物 |
| [esmfold2](./skills/claude-science/esmfold2) | Biohub ESMFold2 / ESMFold2-Fast 全原子共折叠 |
| [diffdock](./skills/claude-science/diffdock) | DiffDock-L 预测小分子结合构象（分子对接） |

### ✏️ 蛋白质设计与嵌入（4）

| Skill | 用途 |
|-------|------|
| [proteinmpnn](./skills/claude-science/proteinmpnn) | 对蛋白骨架逆折叠生成氨基酸序列 |
| [ligandmpnn](./skills/claude-science/ligandmpnn) | 带配体 / 核酸 / 金属上下文的逆折叠 |
| [solublempnn](./skills/claude-science/solublempnn) | 面向可溶性重训的 ProteinMPNN 变体 |
| [fair-esm2](./skills/claude-science/fair-esm2) | 用 Meta ESM-2 生成蛋白质嵌入表征 |

### 🧫 基因组与单细胞（4）

| Skill | 用途 |
|-------|------|
| [borzoi](./skills/claude-science/borzoi) | 从 DNA 序列预测全基因组功能轨迹（RNA-seq/CAGE/DNase/ChIP） |
| [evo2](./skills/claude-science/evo2) | 长上下文基因组基础模型：打分 / 嵌入 / 生成 DNA |
| [scgpt](./skills/claude-science/scgpt) | 单细胞基础模型 scGPT：嵌入与细胞注释 |
| [scvi-tools](./skills/claude-science/scvi-tools) | 概率式单细胞 RNA-seq（scVI / scANVI + 贝叶斯差异表达） |

### 📊 图表与可视化（4）

| Skill | 用途 |
|-------|------|
| [figure-composer](./skills/claude-science/figure-composer) | 组合出版级多面板图 |
| [figure-style](./skills/claude-science/figure-style) | 出版级图表正确性与可读性规范 |
| [algorithmic-art](./skills/claude-science/algorithmic-art) | 用 p5.js 创作算法 / 生成艺术 |
| [web-artifacts-builder](./skills/claude-science/web-artifacts-builder) | 构建复杂的 claude.ai HTML 交互产物（React/Tailwind/shadcn） |

### ✍️ 文献与写作（4）

| Skill | 用途 |
|-------|------|
| [literature-review](./skills/claude-science/literature-review) | 检索、核验并综合科学文献 |
| [paper-narrative](./skills/claude-science/paper-narrative) | 审视并重塑论文图表讲述的“故事线” |
| [indication-dossier](./skills/claude-science/indication-dossier) | 生成治疗适应症档案（indication dossier） |
| [pdf-explore](./skills/claude-science/pdf-explore) | 跨整篇 PDF / 论文定位、比较与抽取内容 |

### ⚙️ 算力与工作流（10）

| Skill | 用途 |
|-------|------|
| [compute-env-setup](./skills/claude-science/compute-env-setup) | 在远程算力上搭建运行环境 |
| [remote-compute-modal](./skills/claude-science/remote-compute-modal) | 在你自己的 Modal 账户上运行 GPU 任务 |
| [remote-compute-ssh](./skills/claude-science/remote-compute-ssh) | SSH / SLURM 主机的提交 → 等待 → 回收工作流 |
| [managed-model-endpoints](./skills/claude-science/managed-model-endpoints) | 注册本地 / 远程模型服务端点 |
| [using-model-endpoint](./skills/claude-science/using-model-endpoint) | 通过原生 HTTP API 调用已注册的模型端点 |
| [self-awareness](./skills/claude-science/self-awareness) | 对 Claude Science 会话数据库 / SDK 做自省 |
| [skill-creator](./skills/claude-science/skill-creator) | 创建、改进并评测 skill |
| [customize](./skills/claude-science/customize) | 自定义 agent 画像并创作新 skill |
| [learn](./skills/claude-science/learn) | 面向“理解原理”的学习 / 讲解型 skill |
| [product-self-knowledge](./skills/claude-science/product-self-knowledge) | 涉及 Anthropic 产品事实时先自查核对 |

</details>

## 🛠️ 维护 `site-first`

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

## 🌐 GitHub Pages

- GitHub Pages 只从 `site-first` 分支部署
- 仓库设置中应把 `Settings -> Pages -> Source` 设为 `GitHub Actions`
- 分支开发阶段用 `npm run preview` 本地预览，不依赖分支级在线预览

## 📚 文档

- [快速入门](./QUICKSTART.md)
- [Skill 归属](./ATTRIBUTIONS.md)
- [site-first 设计 spec](./docs/superpowers/specs/2026-04-16-site-first-light-catalog-repo-design.md)
- [site-first 实施计划](./docs/superpowers/plans/2026-04-16-site-first-branch-implementation.md)

## ⭐ Star History

<a href="https://www.star-history.com/?repos=HughYau%2FAcademicForge&type=date&legend=top-left">
 <picture>
   <source media="(prefers-color-scheme: dark)" srcset="https://api.star-history.com/image?repos=HughYau/AcademicForge&type=date&theme=dark&legend=top-left" />
   <source media="(prefers-color-scheme: light)" srcset="https://api.star-history.com/image?repos=HughYau/AcademicForge&type=date&legend=top-left" />
   <img alt="Star History Chart" src="https://api.star-history.com/image?repos=HughYau/AcademicForge&type=date&legend=top-left" />
 </picture>
</a>

---

## 📄 许可证

- 仓库结构、站点、脚本和本地内容采用 [MIT](./LICENSE)
- 第三方 skill 保留其各自许可证与作者信息
