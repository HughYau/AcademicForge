# Academic Forge 快速入门

这份指南帮助你在几分钟内用新的选配式安装流程把 skill pack 装进项目。

## 1. 前置准备

- 已安装 `git`
- 准备好目标工具：Claude Code、OpenCode 或 Codex
- 进入一个你希望放置 skills 的项目目录

## 2. 选择安装方式

### 方式一：使用选配站

打开 `https://hughyau.github.io/AcademicForge/`，完成三步：

1. 勾选想安装的 skill pack
2. 选择平台和工具
3. 复制生成的安装命令并执行

### 方式二：直接运行安装脚本

macOS / Linux:

```bash
cd your-project
curl -sSL https://raw.githubusercontent.com/HughYau/AcademicForge/refs/heads/master/scripts/forge-install.sh | bash -s -- \
  --tool claude \
  --skills humanizer,superpowers
```

Windows PowerShell:

```powershell
cd your-project
$script = Join-Path $PWD 'forge-install.ps1'
Invoke-WebRequest -Uri 'https://raw.githubusercontent.com/HughYau/AcademicForge/refs/heads/master/scripts/forge-install.ps1' -OutFile $script
& $script -Tool claude -Skills 'humanizer,superpowers'
Remove-Item $script
```

## 3. 验证安装

根据你选择的工具检查目录：

```bash
ls .claude/skills/
ls .opencode/skills/
ls .codex/skills/
```

Windows 可以改用：

```powershell
dir .claude\skills
dir .opencode\skills
dir .codex\skills
```

如果目录下已经出现你选择的 pack，例如 `humanizer`、`superpowers`，说明安装成功。

## 4. 立刻开始使用

安装后的 skills 会被工具自动发现，你可以直接开始对话，例如：

- 帮我把这段摘要润色成更自然的学术英文
- 分析这份 CSV 并生成投稿级图表
- 把这段中文摘要改得更自然，保留原意但去掉 AI 味

## 5. 卸载与调整

- 卸载某个 pack：直接删除对应目录，例如 `.claude/skills/humanizer`
- 调整组合：重新运行选配站或安装脚本，传入新的 `--skills`

## 6. 维护仓库

如果你是在维护 AcademicForge 仓库本身，而不是安装 skill pack 到项目里，可以继续使用：

```bash
./scripts/update.sh
```

Windows：

```powershell
.\scripts\update.ps1
```
