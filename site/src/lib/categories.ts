export const CATEGORY_ORDER = ['workflow', 'writing', 'research', 'visualization'] as const;

export type Category = (typeof CATEGORY_ORDER)[number];

export const CATEGORY_LABELS: Record<Category, { en: string; zh: string }> = {
  workflow: { en: 'Workflow & process', zh: '流程与方法' },
  writing: { en: 'Writing & polishing', zh: '写作与润色' },
  research: { en: 'Research & science', zh: '科研与工程' },
  visualization: { en: 'Figures & visuals', zh: '图表与可视化' },
};

export const SKILL_CATEGORY: Partial<Record<string, Category>> = {
  superpowers: 'workflow',
  humanizer: 'writing',
  'humanizer-zh': 'writing',
  'paper-polish-workflow-skill': 'writing',
  'scientific-agent-skills': 'research',
  'AI-research-SKILLs': 'research',
  'scientific-visualization': 'visualization',
};

export const getSkillCategory = (skillId: string): Category => SKILL_CATEGORY[skillId] ?? 'workflow';
