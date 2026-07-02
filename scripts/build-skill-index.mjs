import { readFileSync, writeFileSync } from 'node:fs';
import { resolve } from 'node:path';

import { collections } from './lib/skill-collections.mjs';
import { collectSubSkills, withTemporaryClone } from './lib/skill-index.mjs';

const repoRoot = resolve(import.meta.dirname, '..');
const registryPath = resolve(repoRoot, 'registry/skills.json');
const classificationPath = resolve(repoRoot, 'scripts/skill-classification.json');
const translationsPath = resolve(repoRoot, 'scripts/skill-translations.zh.json');

const rawArgs = process.argv.slice(2);
const checkOnly = rawArgs.includes('--check');

// --only <id[,id...]> (or --only=<id[,id...]>) rebuilds just the named
// collections and leaves the rest of the registry untouched — handy for the
// locally maintained collections that don't need a network fetch.
const parseOnly = () => {
  for (let index = 0; index < rawArgs.length; index += 1) {
    const arg = rawArgs[index];
    if (arg === '--only') {
      return (rawArgs[index + 1] ?? '').split(',').map((value) => value.trim()).filter(Boolean);
    }
    if (arg.startsWith('--only=')) {
      return arg.slice('--only='.length).split(',').map((value) => value.trim()).filter(Boolean);
    }
  }
  return null;
};

const onlyIds = parseOnly();

const updateLeadingCount = (text, count) => text.replace(/^\d+/, String(count));

const classification = JSON.parse(readFileSync(classificationPath, 'utf8'));
const translations = JSON.parse(readFileSync(translationsPath, 'utf8'));
const registry = JSON.parse(readFileSync(registryPath, 'utf8'));
const seenIds = new Set();

const processedCollections = collections.filter((collection) => !onlyIds || onlyIds.includes(collection.rootSkillId));

if (onlyIds) {
  const unknown = onlyIds.filter((id) => !collections.some((collection) => collection.rootSkillId === id));
  if (unknown.length > 0) {
    throw new Error(`--only references unknown collection(s): ${unknown.join(', ')}`);
  }
}

for (const collection of processedCollections) {
  const parentSkill = registry.skills.find((skill) => skill.id === collection.rootSkillId);
  if (!parentSkill) {
    throw new Error(`Registry entry '${collection.rootSkillId}' not found.`);
  }

  const collectArgs = {
    relativeRoot: collection.relativeRoot,
    includeRootSkill: collection.includeRootSkill,
    prefix: collection.prefix,
    parentSkill,
    classification,
    translations,
  };

  const subSkills = collection.local
    ? collectSubSkills({ rootDir: repoRoot, ...collectArgs })
    : withTemporaryClone(
        {
          url: parentSkill.install.url,
          ref: parentSkill.install.ref,
          sparsePath: collection.clonePath,
        },
        (cloneRoot) => collectSubSkills({ rootDir: cloneRoot, ...collectArgs }),
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

const processedPrefixes = new Set(processedCollections.map((collection) => collection.prefix));

const missingIds = Object.entries(classification)
  .filter(([id, entry]) => {
    if (entry.disabled === true || seenIds.has(id)) {
      return false;
    }
    // In --only mode, ignore ids from collections we deliberately skipped.
    return !onlyIds || processedPrefixes.has(id.split('.')[0]);
  })
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
