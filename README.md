# 🎓 Academic Forge

<div align="center">

**为学术写作整合的Skills集合**

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Skills](https://img.shields.io/badge/Skills-4-blue.svg)](./skills)

[English](./README_en.md) | 简体中文

</div>

## 📖 什么是 Forge（熔炉）？

"Forge" 这个名字灵感来自 **Minecraft 的模组加载器系统**（如 Forge 或 Fabric），它允许玩家无缝运行多个模组。就像 Minecraft Forge 提供的整合包为特定游戏体验集成各种模组一样，**Academic Forge** 为专注的学术写作工作流程集成多个 Skills。

### 为什么叫 "Forge"？

- 🔧 **集成优于安装** - 就像 Minecraft 整合包，你得到的是一个精心策划、协同工作的集合
- 🎯 **专门构建** - 每个 forge 针对特定领域（学术写作、Web 开发、数据科学等）
- 🔄 **自动更新** - Skills 通过 git submodules 与 skills-only 同步机制保持最新
- 🤝 **社区驱动** - 建立在多个Skills创作者的优秀工作之上

## 🎯 用途

Academic Forge 解决了一个常见问题：**太多Skills会导致 AI agent准确性下降**。通过只精选与学术写作和研究相关的Skills，可以：

- ✅ 做出更精准的Skills调用
- ✅ 避免类似Skills之间的混淆
- ✅ 保持对研究工作流程的专注
- ✅ 及时获得原始作者的改进更新

## 📦 包含的Skills

本 forge 整合了以下精心挑选的Skills：

### [claude-scientific-skills](https://github.com/k-dense-ai/claude-scientific-skills) (140 Skills)
- **作者**: [@k-dense-ai](https://github.com/k-dense-ai) - By K-Dense Inc.
- **许可证**: MIT
- **覆盖范围**: 140 个即用型科学skills，涵盖15+领域
- **包含内容**:
  - 🧬 **生物信息学与基因组学** - BioPython, Scanpy, 单细胞RNA-seq, 变异注释
  - 🧪 **化学信息学与药物发现** - RDKit, DeepChem, 分子对接, 虚拟筛选
  - 🏥 **临床研究** - ClinicalTrials.gov, ClinVar, FDA数据库, 药物基因组学
  - 📊 **数据分析** - 统计分析, matplotlib, seaborn, 出版级图表
  - 📚 **科学写作** - LaTeX格式化, 引用管理, 同行评审
  - 🔬 **实验室自动化** - PyLabRobot, Benchling, Opentrons集成
  - 🤖 **机器学习** - PyTorch Lightning, scikit-learn, 深度学习工作流
  - 📚 **数据库** - 28+ 科学数据库 (PubMed, OpenAlex, ChEMBL, UniProt等)
- **最适合**: 从文献综述到论文发表的多步骤科学工作流程

### [AI-research-SKILLs](https://github.com/zechenzhangAGI/AI-research-SKILLs) (82 Skills)
- **作者**: [@zechenzhangAGI](https://github.com/zechenzhangAGI) - By Orchestra Research
- **许可证**: MIT
- **覆盖范围**: 82 个专家级AI研究工程skills，涵盖20个类别
- **包含内容**:
  - 🏗️ **模型架构** - LitGPT, Mamba, RWKV, NanoGPT, TorchTitan (5个skills)
  - 🎯 **微调** - Axolotl, LLaMA-Factory, PEFT, Unsloth (4个skills)
  - 🎓 **后训练** - TRL, GRPO, OpenRLHF, SimPO, verl (8个RLHF/DPO skills)
  - ⚡ **分布式训练** - DeepSpeed, FSDP, Megatron-Core, Accelerate (6个skills)
  - 🚀 **优化** - Flash Attention, bitsandbytes, GPTQ, AWQ (6个skills)
  - 🔥 **推理** - vLLM, TensorRT-LLM, SGLang, llama.cpp (4个skills)
  - 📊 **评估** - lm-eval-harness, BigCode, NeMo Evaluator (3个skills)
  - 🤖 **Agents与RAG** - LangChain, LlamaIndex, Chroma, FAISS (9个skills)
  - 🎨 **多模态** - CLIP, Whisper, LLaVA, Stable Diffusion (7个skills)
  - 📝 **机器学习论文写作** - NeurIPS, ICML, ICLR, ACL的LaTeX模板 (1个skill)
- **文档质量**: 每个skill约420行 + 300KB+参考资料
- **最适合**: 从假设到论文发表的AI研究工作流程

### [humanizer](https://github.com/blader/humanizer)
- **作者**: [@blader](https://github.com/blader)
- **许可证**: 查看原始仓库
- **用途**: 优化学术语气、提高可读性、避免 AI 检测特征
- **最适合**: 润色草稿、保持学术声调、同行评审准备

### [superpowers](https://github.com/obra/superpowers)（仅包含 `skills/`）
- **作者**: [@obra](https://github.com/obra)
- **许可证**: MIT
- **定位**: 一个“流程型技能库”，强调 **先设计、后实现、再验证** 的工程纪律，减少“直接开写导致返工”的问题
- **核心技能**:
  - `brainstorming`：把模糊需求收敛成可执行方案
  - `writing-plans` / `executing-plans`：把任务拆到可验证的粒度
  - `systematic-debugging`：按步骤定位根因，避免拍脑袋修 bug
  - `test-driven-development`：以测试驱动最小改动实现
  - `requesting-code-review` / `receiving-code-review`：形成闭环复盘
  - `verification-before-completion`：在宣告完成前做证据化验证
- **在学术项目中的价值**:
  - 📌 **课题与实验规划**：先澄清假设、变量、验收标准，再落地代码
  - 🧪 **实验管线开发**：把“数据处理→训练→评估→可视化”拆成可追踪步骤
  - 🛠️ **复现实验与排错**：用系统化调试减少不可复现与隐性错误
  - ✅ **交付质量**：通过测试与验证步骤，降低结果描述与代码实现不一致
- **集成方式**: 本 forge 仅同步上游仓库 `skills/` 子目录，不包含插件与其他目录（即不注入 OpenCode 插件逻辑）

> **注意**: 所有Skills保留其原始许可证和作者身份。本 forge 仅提供便捷的集成。详细归属请查看 [ATTRIBUTIONS.md](./ATTRIBUTIONS.md)。

## 🚀 快速开始

### 安装

直接将 Academic Forge 安装到你的 Claude Code/OpenCode 项目中：

**macOS/Linux:**
```bash
cd your-project
curl -sSL https://raw.githubusercontent.com/HughYau/AcademicForge/master/scripts/install.sh | bash
```

**Windows (PowerShell):**
```powershell
cd your-project
irm https://raw.githubusercontent.com/HughYau/AcademicForge/master/scripts/install.ps1 | iex
```

或手动安装：

```bash
# 克隆仓库（包含 submodules，可后续同步 skills-only 来源）
git clone --recursive https://github.com/HughYau/AcademicForge .opencode/skills/academic-forge
```

### 下载/同步 Skills

如果你只想在现有仓库中拉取最新 skills（包含 submodules + superpowers skills-only）：

**Windows (PowerShell):**
```powershell
.\scripts\download-skills.ps1
```

**Linux/macOS:**
```bash
bash scripts/download-skills.sh
```

这些脚本将自动同步本地 `skills/`（包括所有子模块和 `superpowers` 的 `skills/` 子目录快照）。

### 更新 Skills

保持所有 Skills 与最新改进同步：

```bash
cd .opencode/skills/academic-forge
./scripts/update.sh  # 或在 Windows 上使用 update.ps1
```

> 可选：如需屏蔽特定上游 skill，可编辑 `scripts/skill-blacklist.txt`。安装/下载/更新脚本会自动移除清单中的路径。

#### 🔄 自动更新

本仓库配置了自动化工作流程，**每周一 09:00 UTC** 自动更新所有 skills 来源（submodules + superpowers skills-only 同步）。这意味着：

- ✅ Skills 始终保持最新状态
- ✅ 自动获取原作者的改进和bug修复
- ✅ 无需手动运行更新脚本
- 📅 更新时间：每周一 09:00 UTC（北京时间 17:00）

## 🎓 使用案例

Academic Forge 非常适合：

- 📝 **撰写研究论文** - 从大纲到提交就绪的手稿
- 🔬 **实验设计** - 规划和记录研究方法
- 📊 **数据分析** - 统计分析和结果解释
- 📚 **文献综述** - 组织和综合学术资源
- ✍️ **学位论文写作** - 长篇学术文档管理
- 👥 **协作研究** - 在团队成员之间保持一致的风格

## 📄 文档

- [快速入门指南](./QUICKSTART.md) - 5 分钟上手
- [使用示例](./EXAMPLES.md) - 真实工作流程示例
- [Skills归属](./ATTRIBUTIONS.md) - 详细的作者信息和许可证
- [贡献指南](./CONTRIBUTING.md) - 如何贡献或创建你自己的 forge

## 🤝 贡献

发现了一个非常适合学术写作的Skills？请查看 [CONTRIBUTING.md](./CONTRIBUTING.md) 了解如何：

- 建议新Skills
- 报告问题
- 改进文档
- 创建你自己领域的 forge

## 📄 许可证

**forge 结构**（脚本、配置、文档）采用 [MIT 许可证](./LICENSE)。

**单个Skills**保留其原始许可证 - 详见 [ATTRIBUTIONS.md](./ATTRIBUTIONS.md) 和每个Skills的仓库。


---

<div align="center">

**为学术研究社区用 💙 构建**

⭐ 如果这个 forge 对你的研究有帮助，请给本仓库和各个Skills仓库点星！

</div>
