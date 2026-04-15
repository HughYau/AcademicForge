# Skill Configurator Platform Design

**Date:** 2026-04-13
**Status:** Draft
**Author:** HughYau + Claude

---

## 1. 目标与定位

AcademicForge 保持学术写作领域的专注定位不变。在此基础上，在同一 monorepo 内建设一套 **通用 skill 选配平台**：

- 用户通过一个静态前端网站浏览、筛选、勾选 skill
- 网站根据用户选择的平台（Linux/macOS/Windows）和工具（Claude Code / OpenCode / Codex）生成定制安装命令
- 用户复制命令到终端运行，即可完成 skill 安装
- 其他人可以参考此基础设施，创建自己领域的 forge

**不在本期范围：** 自动扫描 GitHub 发现新 skill、社区评分/评论、质量标签体系、用户注册。这些作为未来扩展方向。

---

## 2. 架构概览

```
AcademicForge (monorepo)
├── registry/
│   └── skills.json          # Skill 元数据（来源、安装方式、后处理）
├── site/                    # Astro 静态前端站
│   ├── src/
│   │   ├── pages/
│   │   │   └── index.astro  # 首页：skill 浏览 + 选配器
│   │   ├── components/
│   │   │   ├── SkillCard.astro
│   │   │   ├── SkillGrid.astro
│   │   │   ├── Configurator.astro
│   │   │   ├── CodeBlock.astro       # 带 copy 按钮的代码块
│   │   │   └── InstallGuide.astro    # 分步安装引导面板
│   │   └── layouts/
│   │       └── Layout.astro
│   └── public/
├── scripts/
│   ├── forge-install.sh     # 通用安装脚本（Bash）
│   └── forge-install.ps1    # 通用安装脚本（PowerShell）
├── skills/                  # AcademicForge 自身的 skill 内容（现有）
├── forge.yaml               # AcademicForge 配置（现有）
└── ...
```

**数据流：**
```
registry/skills.json
  → Astro 构建时读取，生成静态页面
  → 用户在浏览器端筛选、勾选 skill
  → 前端 JS 拼接安装命令字符串（纯客户端，不发请求）
  → 用户复制命令，在本地终端运行
  → forge-install.sh/ps1 从 GitHub 下载 skills.json + 按 skill 元数据拉取/处理
```

---

## 3. Registry 数据结构

`registry/skills.json` 是整个平台的核心数据源。每个 skill 源一条记录：

```json
{
  "skills": [
    {
      "id": "scientific-agent-skills",
      "name": "Scientific Agent Skills",
      "description": "133 个科研工作流 skills，涵盖生物信息、化学信息、临床研究等 15+ 领域",
      "author": "K-Dense-AI",
      "repository": "https://github.com/K-Dense-AI/scientific-agent-skills",
      "license": "MIT",
      "skill_count": 133,
      "tags": ["science", "research", "bioinformatics", "chemistry", "clinical"],
      "category": "academic",
      "install": {
        "method": "git-clone",
        "url": "https://github.com/K-Dense-AI/scientific-agent-skills.git"
      },
      "post_install": ["clean_ads"]
    },
    {
      "id": "AI-research-SKILLs",
      "name": "AI Research Skills",
      "description": "82 个专家级 AI 研究工程 skills，涵盖模型架构、微调、RLHF、推理等 20 个类别",
      "author": "orchestra-research",
      "repository": "https://github.com/zechenzhangAGI/AI-research-SKILLs",
      "license": "MIT",
      "skill_count": 82,
      "tags": ["AI", "deep-learning", "LLM", "training", "inference"],
      "category": "academic",
      "install": {
        "method": "git-clone",
        "url": "https://github.com/zechenzhangAGI/AI-research-SKILLs.git"
      },
      "post_install": []
    },
    {
      "id": "superpowers",
      "name": "Superpowers",
      "description": "15 个流程型技能：规划、调试、TDD、代码审查、验证",
      "author": "obra",
      "repository": "https://github.com/obra/superpowers",
      "license": "MIT",
      "skill_count": 15,
      "tags": ["workflow", "planning", "debugging", "tdd", "code-review"],
      "category": "development",
      "install": {
        "method": "sparse-checkout",
        "url": "https://github.com/obra/superpowers.git",
        "sparse_path": "skills"
      },
      "post_install": []
    },
    {
      "id": "paper-polish-workflow-skill",
      "name": "Paper Polish Workflow",
      "description": "15 个论文翻译、润色、审稿模拟与投稿工作流技能",
      "author": "Lylll9436",
      "repository": "https://github.com/Lylll9436/Paper-Polish-Workflow-skill",
      "license": "MIT",
      "skill_count": 15,
      "tags": ["writing", "translation", "polishing", "peer-review", "submission"],
      "category": "academic",
      "install": {
        "method": "git-clone",
        "url": "https://github.com/Lylll9436/Paper-Polish-Workflow-skill.git"
      },
      "post_install": []
    },
    {
      "id": "humanizer",
      "name": "Humanizer",
      "description": "学术语气润色、可读性优化、避免 AI 检测特征",
      "author": "blader",
      "repository": "https://github.com/blader/humanizer",
      "license": "See repository",
      "skill_count": 1,
      "tags": ["writing", "tone", "readability", "academic-style"],
      "category": "academic",
      "install": {
        "method": "git-clone",
        "url": "https://github.com/blader/humanizer.git"
      },
      "post_install": []
    },
    {
      "id": "humanizer-zh",
      "name": "Humanizer 中文版",
      "description": "中文去 AI 痕迹、自然化改写、保留原意的语气润色",
      "author": "op7418",
      "repository": "https://github.com/op7418/Humanizer-zh",
      "license": "MIT",
      "skill_count": 1,
      "tags": ["chinese", "writing", "tone", "de-ai"],
      "category": "academic",
      "install": {
        "method": "git-clone",
        "url": "https://github.com/op7418/Humanizer-zh.git"
      },
      "post_install": []
    },
    {
      "id": "scientific-visualization",
      "name": "Scientific Visualization",
      "description": "出版级科研图表：期刊样式模板、色盲友好配色、导出优化",
      "author": "AcademicForge",
      "repository": "https://github.com/HughYau/AcademicForge",
      "license": "MIT",
      "skill_count": 1,
      "tags": ["visualization", "matplotlib", "publication", "figures"],
      "category": "academic",
      "install": {
        "method": "sparse-checkout",
        "url": "https://github.com/HughYau/AcademicForge.git",
        "sparse_path": "skills/scientific-visualization"
      },
      "post_install": []
    }
  ]
}
```

### 字段说明

| 字段 | 类型 | 必填 | 说明 |
|------|------|------|------|
| `id` | string | 是 | 唯一标识符，用于安装命令参数 |
| `name` | string | 是 | 显示名称 |
| `description` | string | 是 | 一句话描述 |
| `author` | string | 是 | 原作者 |
| `repository` | string | 是 | 源仓库 URL |
| `license` | string | 是 | 许可证 |
| `skill_count` | number | 是 | 包含的 skill 数量 |
| `tags` | string[] | 是 | 用于筛选的标签 |
| `category` | string | 是 | 分类（academic / development / writing 等） |
| `install.method` | string | 是 | 安装方式：`git-clone` / `sparse-checkout` |
| `install.url` | string | 是 | Git 仓库 URL |
| `install.sparse_path` | string | 否 | 仅 `sparse-checkout` 时需要，指定要拉取的子目录 |
| `post_install` | string[] | 是 | 后处理步骤列表（可为空数组） |

### install.method 类型

- **`git-clone`** —— 克隆整个仓库，安装到 `<target_dir>/<id>/`
- **`sparse-checkout`** —— 只拉取仓库的指定子目录（通过 `sparse_path` 指定），将该子目录的 **内容** 安装到 `<target_dir>/<id>/`（即剥离上层路径，只保留子目录内容）

**示例：** superpowers 的 `sparse_path` 为 `skills`，拉取后将 `skills/*` 的内容放入 `<target_dir>/superpowers/`，而不是 `<target_dir>/superpowers/skills/`。

后续按需可扩展新的 method（如 `release-download`、`npm-install` 等）。

### post_install 处理函数

初期内置一个：

- **`clean_ads`** —— 清理 scientific-agent-skills 中 SKILL.md 的广告段落（匹配 `## Suggest Using K-Dense Web` 并删除）

后续按需添加新的处理函数。每个处理函数在安装脚本中实现。

---

## 4. 安装脚本

全新的 `scripts/forge-install.sh`（Bash）和 `scripts/forge-install.ps1`（PowerShell），参数驱动，不继承任何旧逻辑。

### 参数

| 参数 | 必填 | 说明 |
|------|------|------|
| `--tool` | 是 | 目标工具：`claude` / `opencode` / `codex` |
| `--skills` | 是 | 逗号分隔的 skill id 列表 |
| `--path` | 否 | 自定义安装路径，覆盖 `--tool` 的默认路径 |

### 默认安装路径

| `--tool` 值 | 默认路径 |
|-------------|---------|
| `claude` | `.claude/skills/` |
| `opencode` | `.opencode/skills/` |
| `codex` | `.codex/skills/` |

### 执行流程

```
1. 解析参数（--tool, --skills, --path）
2. 从 GitHub raw 下载 registry/skills.json
3. 确定安装目标目录
4. 对用户选择的每个 skill id：
   a. 在 skills.json 中查找对应记录
   b. 如果 id 不存在，报错跳过
   c. 根据 install.method 执行拉取：
      - git-clone: git clone --depth 1 <url> <target_dir>/<id>
      - sparse-checkout: 用 git sparse-checkout 只拉取指定子目录
   d. 执行 post_install 中的每个处理函数
5. 输出安装摘要（成功/失败的 skill 列表）
```

### 错误处理

- 无 git → 报错退出
- 单个 skill 拉取失败 → 警告但继续安装其他 skill
- 未知 skill id → 警告跳过
- 网络不可用 → 报错退出

---

## 5. 静态前端站

### 技术栈

- **框架：** Astro（静态站生成）
- **样式：** Tailwind CSS
- **部署：** GitHub Pages（通过 GitHub Actions 自动构建部署）
- **数据源：** 构建时读取 `registry/skills.json`

### 页面结构

单页应用，从上到下分为三个区域：

#### 5.1 头部区域

- 项目名称 + 一句话 tagline（如 "Pick your skills. Get your command."）
- 简要说明这是什么、怎么用

#### 5.2 Skill 浏览区

卡片网格布局。每张卡片包含：

- Skill 名称
- 一句话描述
- 作者（链接到源仓库）
- Skill 数量徽章
- 标签
- 勾选框

顶部有筛选栏：
- 按 category 筛选（All / Academic / Development / Writing）
- 按关键词搜索（客户端 JS 实时过滤）

#### 5.3 选配器 + 安装引导区

固定在页面底部或作为侧边栏：

- 已选 skill 列表（可移除）
- 已选总 skill 数统计
- 平台选择：Linux / macOS / Windows
- 工具选择：Claude Code / OpenCode / Codex
- "生成安装命令" 按钮

点击按钮后展示 **分步安装引导面板**：

```
Step 1: 打开终端，进入你的项目根目录
┌──────────────────────────────────────┐
│ cd /path/to/your-project             │  [复制]
└──────────────────────────────────────┘
提示文字根据平台变化：
  - Linux/macOS: "打开终端 (Terminal)"
  - Windows: "打开 PowerShell"

Step 2: 运行安装命令
┌──────────────────────────────────────┐
│ curl -sSL https://raw.githubuserc... │  [复制]
│   | bash -s -- \                     │
│   --tool claude \                    │
│   --skills skill1,skill2,skill3      │
└──────────────────────────────────────┘
  - Linux/macOS: curl | bash 格式
  - Windows: irm | iex 格式

Step 3: 验证安装
┌──────────────────────────────────────┐
│ ls .claude/skills/                   │  [复制]
└──────────────────────────────────────┘
  - 路径根据 --tool 选择动态调整
  - Windows: 使用 dir 或 ls 命令

提示区：
  - "Skills 安装到 .claude/skills/ 目录下"
  - "Claude Code 会自动识别和加载这些 skills"
  - "运行 claude 即可开始使用"
```

### 5.4 CodeBlock 组件

所有代码展示统一使用 `CodeBlock` 组件：

- 代码内容区（等宽字体，语法高亮，深色背景）
- 右上角 copy 按钮
- 点击后按钮文字变为 "Copied!" 并在 2 秒后恢复
- 使用 `navigator.clipboard.writeText()` API

---

## 6. 部署与 CI

### GitHub Pages 部署

在 `.github/workflows/` 新增一个 workflow：

- 触发条件：`site/` 或 `registry/` 目录有变更推送到 main
- 构建 Astro 站点
- 部署到 GitHub Pages

### 现有 CI 不受影响

现有的 `check-updates.yml`（每周自动更新 skill submodule）保持不变或按需调整。

---

## 7. 目录结构变更

在现有 monorepo 中新增：

```
AcademicForge/
├── registry/
│   └── skills.json              # 新增：skill 元数据
├── site/                        # 新增：Astro 前端站
│   ├── astro.config.mjs
│   ├── package.json
│   ├── tailwind.config.mjs
│   ├── tsconfig.json
│   ├── src/
│   │   ├── pages/
│   │   │   └── index.astro
│   │   ├── components/
│   │   │   ├── SkillCard.astro
│   │   │   ├── SkillGrid.astro
│   │   │   ├── Configurator.astro
│   │   │   ├── CodeBlock.astro
│   │   │   └── InstallGuide.astro
│   │   ├── layouts/
│   │   │   └── Layout.astro
│   │   └── styles/
│   │       └── global.css
│   └── public/
│       └── favicon.svg
├── scripts/
│   ├── forge-install.sh         # 新增：通用安装脚本（Bash）
│   └── forge-install.ps1        # 新增：通用安装脚本（PowerShell）
└── ...（现有文件保持不变）
```

---

## 8. 未来扩展方向（不在本期实现）

以下功能在本期不实现，但数据结构和架构设计已预留扩展空间：

1. **自动扫描发现 skill** —— GitHub Actions 定期搜索含 SKILL.md 的仓库，自动跑质量检查，通过的进入 `unverified` 区
2. **社区评分与评论** —— 基于 GitHub Discussions API 或 skills.json 中新增评分字段
3. **质量标签** —— skills.json 中新增 `status` 字段（`verified` / `community` / `unverified`）
4. **Skill 详情页** —— 点击卡片展开详情（完整描述、包含的子 skill 列表、安装量统计）
5. **Forge 模板** —— 提供 `forge init` CLI 或网站上 "Create Your Forge" 功能
6. **更多 install.method** —— `release-download`（从 GitHub Release 下载）、`npm-install` 等
