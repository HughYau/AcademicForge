export type Locale = 'en' | 'zh';

export interface LocalizedText {
  en: string;
  zh: string;
}

export interface InstallRecord {
  method: string;
  url: string;
  ref?: string;
  sparse_path?: string;
}

export interface SubSkillRecord {
  id: string;
  name: string;
  summary: LocalizedText;
  sparse_path: string;
  category: string;
  subdiscipline?: string;
  tags?: string[];
  license?: string;
  install: InstallRecord;
  post_install: string[];
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
  install: InstallRecord;
  post_install: string[];
  sub_skills?: SubSkillRecord[];
  is_collection?: boolean;
  /** Pins a pack to the top of its category, ahead of higher-starred neighbours. */
  featured?: boolean;
}

export interface RegistryData {
  skills: SkillRecord[];
}

export interface RegistryItemMatch {
  item: SkillRecord | SubSkillRecord;
  parentSkill?: SkillRecord;
}

export const formatCount = (value: number) => new Intl.NumberFormat('en-US').format(value);

// Featured packs come first (SkillGrid buckets by category afterwards, so a
// featured pack heads its own category); everything else falls back to stars.
export const sortSkillsByStars = (skills: SkillRecord[]) => {
  return [...skills].sort(
    (left, right) => Number(right.featured ?? false) - Number(left.featured ?? false)
      || right.stars - left.stars
      || right.skill_count - left.skill_count
      || left.name.localeCompare(right.name),
  );
};

export const iterateAllItems = (registry: RegistryData | SkillRecord[]) => {
  const skills = Array.isArray(registry) ? registry : registry.skills;
  const items: RegistryItemMatch[] = [];

  skills.forEach((skill) => {
    items.push({ item: skill });

    skill.sub_skills?.forEach((subSkill) => {
      items.push({ item: subSkill, parentSkill: skill });
    });
  });

  return items;
};

export const findItemById = (registry: RegistryData | SkillRecord[], id: string) => {
  return iterateAllItems(registry).find((entry) => entry.item.id === id);
};
