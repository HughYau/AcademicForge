# 🎓 Academic Forge

<div align="center">

**为学术写作整合的Skills集合**

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Skills](https://img.shields.io/badge/Skills-3-blue.svg)](./skills)

[English](./README_en.md) | 简体中文

</div>

## 📖 什么是 Forge（熔炉）？

"Forge" 这个名字灵感来自 **Minecraft 的模组加载器系统**（如 Forge 或 Fabric），它允许玩家无缝运行多个模组。就像 Minecraft Forge 提供的整合包为特定游戏体验集成各种模组一样，**Academic Forge** 为专注的学术写作工作流程集成多个 Claude Code 技能。

### 为什么叫 "Forge"？

- 🔧 **集成优于安装** - 就像 Minecraft 整合包，你得到的是一个精心策划、协同工作的集合
- 🎯 **专门构建** - 每个 forge 针对特定领域（学术写作、Web 开发、数据科学等）
- 🔄 **自动更新** - 技能通过 git submodules 保持与原始仓库的链接
- 🤝 **社区驱动** - 建立在多个技能创作者的优秀工作之上

## 🎯 用途

Academic Forge 解决了一个常见问题：**太多技能会导致 AI 代理准确性下降**。通过只精选与学术写作和研究相关的技能，Claude Code 可以：

- ✅ 做出更精准的技能调用
- ✅ 避免类似技能之间的混淆
- ✅ 保持对研究工作流程的专注
- ✅ 及时获得原始作者的改进更新

## 📦 包含的技能

本 forge 整合了以下精心挑选的技能：

### [claude-scientific-skills](https://github.com/k-dense-ai/claude-scientific-skills)
- **作者**: [@k-dense-ai](https://github.com/k-dense-ai)
- **许可证**: MIT
- **用途**: 全面的科学论文写作、LaTeX 格式化和学术结构
- **最适合**: 写论文、管理引用、格式化公式

### [AI-research-SKILLs](https://github.com/zechenzhangAGI/AI-research-SKILLs)
- **作者**: [@zechenzhangAGI](https://github.com/zechenzhangAGI)
- **许可证**: MIT
- **用途**: 研究方法、实验设计和数据分析工作流程
- **最适合**: 设计实验、分析结果、研究规划

### [humanizer](https://github.com/blader/humanizer)
- **作者**: [@blader](https://github.com/blader)
- **许可证**: 查看原始仓库
- **用途**: 优化学术语气、提高可读性、避免 AI 检测特征
- **最适合**: 润色草稿、保持学术声调、同行评审准备

> **注意**: 所有技能保留其原始许可证和作者身份。本 forge 仅提供便捷的集成。详细归属请查看 [ATTRIBUTIONS.md](./ATTRIBUTIONS.md)。

## 🚀 快速开始

### 安装

直接将 Academic Forge 安装到你的 Claude Code 项目中：

**macOS/Linux:**
```bash
cd your-project
curl -sSL https://raw.githubusercontent.com/your-username/academic-forge/main/scripts/install.sh | bash
```

**Windows (PowerShell):**
```powershell
cd your-project
irm https://raw.githubusercontent.com/your-username/academic-forge/main/scripts/install.ps1 | iex
```

或手动安装：

```bash
# 克隆包含所有 submodules
git clone --recursive https://github.com/your-username/academic-forge .opencode/skills/academic-forge
```

### 更新技能

保持所有技能与最新改进同步：

```bash
cd .opencode/skills/academic-forge
./scripts/update.sh  # 或在 Windows 上使用 update.ps1
```

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
- [技能归属](./ATTRIBUTIONS.md) - 详细的作者信息和许可证
- [贡献指南](./CONTRIBUTING.md) - 如何贡献或创建你自己的 forge

## 🤝 贡献

发现了一个非常适合学术写作的技能？请查看 [CONTRIBUTING.md](./CONTRIBUTING.md) 了解如何：

- 建议新技能
- 报告问题
- 改进文档
- 创建你自己领域的 forge

## 📄 许可证

**forge 结构**（脚本、配置、文档）采用 [MIT 许可证](./LICENSE)。

**单个技能**保留其原始许可证 - 详见 [ATTRIBUTIONS.md](./ATTRIBUTIONS.md) 和每个技能的仓库。


---

<div align="center">

**为学术研究社区用 💙 构建**

⭐ 如果这个 forge 对你的研究有帮助，请给本仓库和各个技能仓库点星！

</div>
