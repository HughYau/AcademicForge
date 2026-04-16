import { readFileSync, writeFileSync } from 'node:fs';
import { resolve } from 'node:path';

import { collectSubSkills, withTemporaryClone } from './lib/skill-index.mjs';

const repoRoot = resolve(import.meta.dirname, '..');
const registryPath = resolve(repoRoot, 'registry/skills.json');
const classificationPath = resolve(repoRoot, 'scripts/skill-classification.json');

const collections = [
  {
    rootSkillId: 'scientific-agent-skills',
    prefix: 'sa',
    relativeRoot: 'scientific-skills',
    clonePath: 'scientific-skills',
    includeRootSkill: false,
  },
  {
    rootSkillId: 'AI-research-SKILLs',
    prefix: 'air',
    relativeRoot: '',
    clonePath: '',
    includeRootSkill: true,
  },
];

const args = new Set(process.argv.slice(2));
const checkOnly = args.has('--check');

const updateLeadingCount = (text, count) => text.replace(/^\d+/, String(count));

const classification = JSON.parse(readFileSync(classificationPath, 'utf8'));
const registry = JSON.parse(readFileSync(registryPath, 'utf8'));
const seenIds = new Set();

for (const collection of collections) {
  const parentSkill = registry.skills.find((skill) => skill.id === collection.rootSkillId);
  if (!parentSkill) {
    throw new Error(`Registry entry '${collection.rootSkillId}' not found.`);
  }

  const subSkills = withTemporaryClone(
    {
      url: parentSkill.install.url,
      ref: parentSkill.install.ref,
      sparsePath: collection.clonePath,
    },
    (cloneRoot) => collectSubSkills({
      rootDir: cloneRoot,
      relativeRoot: collection.relativeRoot,
      includeRootSkill: collection.includeRootSkill,
      prefix: collection.prefix,
      parentSkill,
      classification,
    }),
  );

  subSkills.forEach((subSkill) => {
    seenIds.add(subSkill.id);
  });

  parentSkill.skill_count = subSkills.length;
  parentSkill.is_collection = true;
  parentSkill.sub_skills = subSkills;
  parentSkill.summary.en = updateLeadingCount(parentSkill.summary.en, subSkills.length);
  parentSkill.summary.zh = updateLeadingCount(parentSkill.summary.zh, subSkills.length);
}

const missingIds = Object.entries(classification)
  .filter(([id, entry]) => entry.disabled !== true && !seenIds.has(id))
  .map(([id]) => id);

if (missingIds.length > 0) {
  throw new Error(`Classification contains unknown ids:\n${missingIds.join('\n')}`);
}

const totals = collections.map((collection) => {
  const skill = registry.skills.find((entry) => entry.id === collection.rootSkillId);
  return `${collection.rootSkillId}: ${skill?.skill_count ?? 0}`;
});

if (checkOnly) {
  console.log(totals.join('\n'));
} else {
  writeFileSync(registryPath, `${JSON.stringify(registry, null, 2)}\n`, 'utf8');
  console.log(`Updated registry with sub-skills.\n${totals.join('\n')}`);
}
