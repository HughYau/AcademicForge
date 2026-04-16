export const ACADEMIC_FORGE_BRANCH = 'site-first';
export const SCRIPT_BASE = `https://raw.githubusercontent.com/HughYau/AcademicForge/refs/heads/${ACADEMIC_FORGE_BRANCH}/scripts`;

export const TOOL_PATHS = {
  claude: { linux: '.claude/skills', windows: '.claude\\skills' },
  opencode: { linux: '.opencode/skills', windows: '.opencode\\skills' },
  codex: { linux: '.codex/skills', windows: '.codex\\skills' },
};

export function getToolPath({ platform = 'linux', tool = 'claude' }) {
  const toolPaths = TOOL_PATHS[tool] ?? TOOL_PATHS.claude;
  return platform === 'windows' ? toolPaths.windows : toolPaths.linux;
}

export function buildInstallCommand({ platform = 'linux', tool = 'claude', skillIds = [] }) {
  const skillList = skillIds.join(',');

  if (platform === 'windows') {
    return [
      "$script = Join-Path $PWD 'forge-install.ps1'",
      `Invoke-WebRequest -Uri '${SCRIPT_BASE}/forge-install.ps1' -OutFile $script`,
      `& $script -Tool ${tool} -Skills '${skillList}'`,
      'Remove-Item $script',
    ].join('\n');
  }

  return [
    `curl -sSL ${SCRIPT_BASE}/forge-install.sh | bash -s -- \\`,
    `  --tool ${tool} \\`,
    `  --skills ${skillList}`,
  ].join('\n');
}

export function buildVerifyCommand({ platform = 'linux', tool = 'claude' }) {
  const toolPath = getToolPath({ platform, tool });
  return platform === 'windows' ? `dir ${toolPath}` : `ls ${toolPath}/`;
}
