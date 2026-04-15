import type { SkillRecord, SubSkillRecord } from './registry';

export const CATEGORY_ORDER = ['workflow', 'writing', 'research', 'visualization'] as const;

export type Category = (typeof CATEGORY_ORDER)[number];

export const CATEGORY_LABELS: Record<Category, { en: string; zh: string }> = {
  workflow: { en: 'Workflow & process', zh: '流程与方法' },
  writing: { en: 'Writing & polishing', zh: '写作与润色' },
  research: { en: 'Research & science', zh: '科研与工程' },
  visualization: { en: 'Figures & visuals', zh: '图表与可视化' },
};

export const SUBDISCIPLINE_ORDER = [
  'life-sci',
  'chem-mat-phys',
  'earth-geo',
  'lab-automation',
  'llm',
  'multimodal',
] as const;

export type Subdiscipline = (typeof SUBDISCIPLINE_ORDER)[number];

export const SUBDISCIPLINE_LABELS: Record<Subdiscipline, { en: string; zh: string; icon: string }> = {
  'life-sci': { en: 'Life science & medicine', zh: '生命科学与医学', icon: '🧬' },
  'chem-mat-phys': { en: 'Chemistry · Materials · Physics', zh: '化学·材料·物理', icon: '🧪' },
  'earth-geo': { en: 'Earth & geospatial', zh: '地球与地理空间', icon: '🌍' },
  'lab-automation': { en: 'Lab automation & integration', zh: '实验室自动化', icon: '🔬' },
  llm: { en: 'LLM research', zh: '大模型研究', icon: '🤖' },
  multimodal: { en: 'Multimodal & embodied AI', zh: '多模态与具身 AI', icon: '🎨' },
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

export const getItemCategory = (item: SkillRecord | SubSkillRecord): Category => {
  if ('category' in item && typeof item.category === 'string') {
    return item.category as Category;
  }

  return getSkillCategory(item.id);
};
