# Academic Forge 快速入门

## 1. 分支说明

- `site-first`：公开配置站分支，也是安装器和 `registry/skills.json` 的来源
- `master`：legacy 兼容分支

如果你要维护公开网站，请在 `site-first` 分支工作。

## 2. 安装到项目里

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

## 3. 验证安装

```bash
ls .claude/skills/
ls .opencode/skills/
ls .codex/skills/
```

Windows 也可以用：

```powershell
dir .claude\skills
dir .opencode\skills
dir .codex\skills
```

## 4. 本地开发与预览

```bash
npm run site:install
npm run build
npm run preview
```

## 5. 本地校验

```bash
npm run validate:registry
npm run ci:validate
node scripts/build-skill-index.mjs --check
```

## 6. 本地安装器冒烟测试

```bash
"D:\Application\Git\bin\bash.exe" scripts/tests/forge-install-local-registry.sh
pwsh -File scripts/tests/forge-install-local-registry.ps1
```

## 7. GitHub Pages

- `site-first` 推送后由 GitHub Actions 部署到 Pages
- 分支开发阶段优先使用 `npm run preview` 做本地预览
