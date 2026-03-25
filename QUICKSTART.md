# ⚡ Academic Forge 快速入门（5 分钟）

这份指南帮助你在 **5 分钟内**把 Academic Forge 安装到项目中并开始使用。  
适用于 Claude Code / OpenCode 场景。

## 1) 前置准备（约 1 分钟）

请先确认：

- 已安装 **Git**（`git` 命令可用）
- 已安装并可使用 AI 助手环境（Claude Code 或 OpenCode）
- 你当前位于一个项目目录中（建议新建空目录测试）

> 不需要手动下载每个 skills 仓库，安装脚本会自动完成。

## 2) 一键安装（约 2 分钟）

### macOS / Linux

```bash
cd your-project
curl -sSL https://raw.githubusercontent.com/HughYau/AcademicForge/refs/heads/master/scripts/install.sh | bash
```

### Windows（PowerShell）

```powershell
cd your-project
irm https://raw.githubusercontent.com/HughYau/AcademicForge/refs/heads/master/scripts/install.ps1 | iex
```

### 可选：指定安装目标

- Claude Code：安装到 `.claude/skills/academic-forge`
- OpenCode：安装到 `.opencode/skills/academic-forge`

示例：

```bash
bash install.sh --tool claude
bash install.sh --tool opencode
bash install.sh /custom/path
```

> 不指定参数时会自动检测：优先 `.claude/`，否则 `.opencode/`。

## 3) 验证安装（约 1 分钟）

在已安装后的目录中运行：

```bash
bash scripts/verify.sh
bash scripts/list-skills.sh
```

Windows 也可使用：

```powershell
.\scripts\verify.ps1
.\scripts\list-skills.ps1
```

如果输出显示所有技能正常，即安装成功。

## 4) 立刻开始用（约 1 分钟）

安装后 **无需手动触发 skills**，直接对话即可，系统会自动匹配调用。

你可以先试这些提示词：

- 「帮我用 LaTeX 生成一份深度学习论文大纲」
- 「分析这份 CSV 并生成投稿级图表」
- 「把这个研究任务拆成可执行步骤，并记录进度文件」
- 「把这段摘要润色成更学术、自然的英文」

## 常用后续操作

### 更新全部 Skills

```bash
./scripts/update.sh
```

Windows：

```powershell
.\scripts\update.ps1
```

### 卸载

```bash
bash scripts/uninstall.sh
```

Windows：

```powershell
.\scripts\uninstall.ps1
```

## 常见问题（超短版）

**Q：为什么我没有看到“手动启用 skill”的步骤？**  
A：skills 会由 AI 助手根据上下文自动选择，不同AI助手也有指定指定技能的能力。

**Q：装很多 skills 会变慢吗？**  
A：不会显著影响响应速度；skills 是上下文能力，不是额外运行进程。

**Q：安装到哪里了？**  
A：默认安装到项目内的 `.claude/skills/academic-forge` 或 `.opencode/skills/academic-forge`。

---

如果你是第一次使用，建议接着阅读：

- [README.md](./README.md)（完整说明）
- [ATTRIBUTIONS.md](./ATTRIBUTIONS.md)（来源与许可证）
- [forge.yaml](./forge.yaml)（启用/禁用技能包）

祝你写作顺利、实验顺利、投稿顺利。🎓✨
