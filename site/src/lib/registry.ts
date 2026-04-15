export type Locale = 'en' | 'zh';

export interface LocalizedText {
  en: string;
  zh: string;
}

export interface SkillRecord {
  id: string;
  name: string;
  summary: LocalizedText;
  author: string;
  repository: string;
  license: string;
  skill_count: number;
  stars: number;
  tags: string[];
  install: {
    method: string;
    url: string;
    sparse_path?: string;
  };
  post_install: string[];
}

export interface RegistryData {
  skills: SkillRecord[];
}

export const formatCount = (value: number) => new Intl.NumberFormat('en-US').format(value);

export const sortSkillsByStars = (skills: SkillRecord[]) => {
  return [...skills].sort(
    (left, right) => right.stars - left.stars || right.skill_count - left.skill_count || left.name.localeCompare(right.name),
  );
};
