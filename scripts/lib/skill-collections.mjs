export const collections = [
  {
    // Locally maintained collection: content lives in this repo under
    // skills/claude-science, so the build reads it straight from disk (no clone)
    // and each sub-skill installs via sparse-checkout of the AcademicForge repo.
    rootSkillId: 'claude-science',
    prefix: 'cs',
    relativeRoot: 'skills/claude-science',
    clonePath: 'skills/claude-science',
    includeRootSkill: false,
    local: true,
  },
  {
    rootSkillId: 'scientific-agent-skills',
    prefix: 'sa',
    relativeRoot: 'skills',
    clonePath: 'skills',
    includeRootSkill: false,
  },
  {
    rootSkillId: 'AI-research-SKILLs',
    prefix: 'air',
    relativeRoot: '',
    clonePath: '',
    includeRootSkill: true,
  },
  {
    rootSkillId: 'nature-skills',
    prefix: 'ns',
    relativeRoot: 'skills',
    clonePath: 'skills',
    includeRootSkill: false,
  },
];
