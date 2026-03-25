# 🎓 Academic Forge

<div align="center">

**为学术写作整合的 Claude Code / OpenCode 技能集合**

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Skills](https://img.shields.io/badge/Skills-7-blue.svg)](./skills)

[English](./README_en.md) | 简体中文

</div>

## 📖 什么是 Forge（熔炉）？

"Forge" 灵感来自 **Minecraft 的模组加载器系统**——就像 Minecraft Forge 整合包为特定游戏体验集成各种模组一样，**Academic Forge** 为学术写作工作流程整合多个 AI 编程助手技能。

- 🔧 **集成优于安装** - 精心策划、协同工作的技能集合，而非零散安装
- 🎯 **专门构建** - 只包含学术写作相关技能，避免太多技能导致 AI 准确性下降
- 🔄 **自动更新** - Skills 通过 git submodules 与 skills-only 同步机制保持最新
- 🤝 **社区驱动** - 建立在多个 Skills 创作者的优秀工作之上

## 🚀 快速开始

### 安装

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

**指定目标工具（可选）：**
```bash
bash install.sh --tool claude     # 安装到 .claude/skills/
bash install.sh --tool opencode   # 安装到 .opencode/skills/
bash install.sh /custom/path      # 自定义路径
```

> 不指定 `--tool` 时，脚本会自动检测：优先使用 `.claude/` 目录，否则使用 `.opencode/`。

### 验证安装

```bash
bash scripts/verify.sh    # 检查所有技能是否正确安装
bash scripts/list-skills.sh  # 列出所有已安装技能
```

## 📦 包含的 Skills

| 技能包 | 数量 | 擅长领域 | 来源 |
|--------|------|----------|------|
| [claude-scientific-skills](https://github.com/k-dense-ai/claude-scientific-skills) | 140 | 科学写作、LaTeX、引文、数据库 | [@k-dense-ai](https://github.com/k-dense-ai) |
| [AI-research-SKILLs](https://github.com/zechenzhangAGI/AI-research-SKILLs) | 82 | AI 研究方法、训练、推理、评估 | [@zechenzhangAGI](https://github.com/zechenzhangAGI) |
| [superpowers](https://github.com/obra/superpowers) | 15 | 规划、调试、TDD、代码审查 | [@obra](https://github.com/obra) |
| [planning-with-files](https://github.com/OthmanAdi/planning-with-files) | 1 | 文件化任务管理、上下文持久化 | [@OthmanAdi](https://github.com/OthmanAdi) |
| [paper-polish-workflow-skill](https://github.com/Lylll9436/Paper-Polish-Workflow-skill) | 15 | 论文翻译、润色、审稿模拟与投稿工作流 | [@Lylll9436](https://github.com/Lylll9436) |
| [scientific-visualization](./skills/scientific-visualization) | 1 | 出版级图表、色盲友好配色 | 本地维护 |
| [humanizer](https://github.com/blader/humanizer) | 1 | 学术语气润色、可读性优化 | [@blader](https://github.com/blader) |

> 所有 Skills 保留其原始许可证和作者身份。详细归属请查看 [ATTRIBUTIONS.md](./ATTRIBUTIONS.md)。

<details>
<summary><b>📋 查看每个 Skills 的详细内容</b></summary>

### claude-scientific-skills (140 Skills)
- **许可证**: MIT
- **覆盖范围**: 140 个即用型科学 skills，涵盖 15+ 领域
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
- **广告净化**: 脚本每次安装/下载/更新后自动移除各 SKILL.md 中内嵌的平台推广段落，保持 skill 内容纯净

### AI-research-SKILLs (82 Skills)
- **许可证**: MIT
- **覆盖范围**: 82 个专家级AI研究工程 skills，涵盖 20 个类别
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
- **文档质量**: 每个 skill 约 420 行 + 300KB+ 参考资料
- **最适合**: 从假设到论文发表的AI研究工作流程

### humanizer
- **许可证**: 查看原始仓库
- **用途**: 优化学术语气、提高可读性、避免 AI 检测特征
- **最适合**: 润色草稿、保持学术声调、同行评审准备

### superpowers（仅包含 `skills/`）
- **许可证**: MIT
- **定位**: 一个"流程型技能库"，强调 **先设计、后实现、再验证** 的工程纪律
- **核心技能**:
  - `brainstorming`：把模糊需求收敛成可执行方案
  - `writing-plans` / `executing-plans`：把任务拆到可验证的粒度
  - `systematic-debugging`：按步骤定位根因，避免拍脑袋修 bug
  - `test-driven-development`：以测试驱动最小改动实现
  - `requesting-code-review` / `receiving-code-review`：形成闭环复盘
  - `verification-before-completion`：在宣告完成前做证据化验证

### planning-with-files（仅同步 `.opencode/skills/planning-with-files`）
- **许可证**: MIT
- **定位**: 用文件化方式管理复杂任务，把上下文沉淀到磁盘
- **核心能力**:
  - `task_plan.md`：阶段拆解、验收标准、状态追踪
  - `findings.md`：研究发现与关键证据沉淀
  - `progress.md`：执行日志、测试结果与错误记录
  - `session-catchup.py`：在 `/clear` 后恢复上下文

### scientific-visualization（本地内置 Skill）
- **许可证**: MIT
- **定位**: 面向科研论文与报告的可视化增强
- **核心能力**:
  - 出版级样式模板（期刊风格、字体/线宽/配色一致化）
  - 多子图布局与标注规范（panel labels、legend、单位、误差线）
  - 色盲友好配色与灰度可读性校验
  - 导出优化（PDF/EPS/TIFF/PNG，分辨率与尺寸对齐投稿要求）

</details>

## 🛡️ 防御 Prompt 注入与内容净化

为了防止部分上游 Skills 中可能包含的 **Prompt 注入攻击**（如劫持 AI 行为）或破坏上下文的无关广告，本仓库在同步与安装流程中内置了以下机制：

- **黑名单屏蔽 (Blacklist)**：通过维护 `scripts/skill-blacklist.txt`，安装向导和更新脚本会自动移除已知的含有恶意 Prompt、质量低下或会导致上下文混乱的特定文件。
- **Prompt 后置清理 (Clean-AdInsertions)**：在上游内容同步后，脚本会自动执行清洗策略（如 `Clean-AdInsertions` 函数），通过正则匹配自动剥离 SKILL 文件中夹带的第三方平台引流、赞助广告等附加指令，确保输入给 AI 助手的 Prompt 内容纯净、安全。

## 🔧 管理 Skills

### 更新

```bash
./scripts/update.sh  # 或 Windows: .\scripts\update.ps1
```

> 所有脚本支持从任意目录运行，会自动定位仓库根目录。

### 配置

编辑 `forge.yaml` 中的 `config.enabled` 来启用/禁用特定技能包：

```yaml
config:
  enabled:
    claude-scientific-skills: true
    humanizer: false  # 设为 false 会在下次同步后移除
```

如需屏蔽特定上游 skill（而非整个技能包），编辑 `scripts/skill-blacklist.txt`。

### 自动更新

本仓库配置了自动化工作流程，**每周一 09:00 UTC**（北京时间 17:00）自动更新所有上游 skills 来源。

## ❓ 常见问题

**Q: 技能怎么触发？需要手动调用吗？**
A: 不需要。技能由 AI 助手根据你的提示词自动选择并调用。你只需正常对话即可。

**Q: 装了这么多技能会变慢吗？**
A: 不会影响响应速度。Skills 只是提供给 AI 的参考信息，不会增加运行开销。

**Q: 和手动装单个 skill 有什么区别？**
A: Academic Forge 精选了互相兼容的技能组合，避免冲突。同时提供一键安装、自动更新、广告清理等便利功能。

**Q: 怎么卸载？**
A: 运行 `bash scripts/uninstall.sh`（Windows: `.\scripts\uninstall.ps1`），或直接删除安装目录。

## 🎓 使用案例

- 📝 **撰写研究论文** - 从大纲到提交就绪的手稿
- 🔬 **实验设计** - 规划和记录研究方法
- 📊 **数据分析** - 统计分析和结果解释
- 🖼️ **科研绘图** - 生成或改造投稿级图表
- 📚 **文献综述** - 组织和综合学术资源
- ✍️ **学位论文写作** - 长篇学术文档管理

## 📄 文档

- [快速入门指南](./QUICKSTART.md) - 5 分钟上手
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

## Star History

<a href="https://www.star-history.com/?repos=HughYau%2FAcademicForge&type=date&legend=top-left">
 <picture>
   <source media="(prefers-color-scheme: dark)" srcset="https://api.star-history.com/image?repos=HughYau/AcademicForge&type=date&theme=dark&legend=top-left" />
   <source media="(prefers-color-scheme: light)" srcset="https://api.star-history.com/image?repos=HughYau/AcademicForge&type=date&legend=top-left" />
   <img alt="Star History Chart" src="https://api.star-history.com/image?repos=HughYau/AcademicForge&type=date&legend=top-left" />
 </picture>
</a>

---

<div align="center">

**为学术研究社区用 💙 构建**

⭐ 如果这个 forge 对你的研究有帮助，请给本仓库和各个Skills仓库点星！

</div>

