import { readdirSync, readFileSync, writeFileSync } from 'node:fs';
import { resolve, relative, dirname, basename } from 'node:path';

const repoRoot = resolve(import.meta.dirname, '..');
const registryPath = resolve(repoRoot, 'registry/skills.json');
const classificationPath = resolve(repoRoot, 'scripts/skill-classification.json');

const collections = [
  {
    rootSkillId: 'scientific-agent-skills',
    prefix: 'sa',
    rootDir: resolve(repoRoot, 'skills/scientific-agent-skills'),
    includeRootSkill: false,
  },
  {
    rootSkillId: 'AI-research-SKILLs',
    prefix: 'air',
    rootDir: resolve(repoRoot, 'skills/AI-research-SKILLs'),
    includeRootSkill: true,
  },
];

const args = new Set(process.argv.slice(2));
const checkOnly = args.has('--check');

const stripQuotes = (value) => value.replace(/^['"]|['"]$/g, '').trim();

const parseInlineArray = (value) => {
  const trimmed = value.trim();
  if (!trimmed.startsWith('[') || !trimmed.endsWith(']')) {
    return [];
  }

  return trimmed
    .slice(1, -1)
    .split(',')
    .map((item) => stripQuotes(item.trim()))
    .filter(Boolean);
};

const parseFrontmatter = (content, filePath) => {
  const match = content.match(/^---\r?\n([\s\S]*?)\r?\n---/);
  if (!match) {
    throw new Error(`Missing frontmatter in ${relative(repoRoot, filePath)}`);
  }

  const fields = {};
  match[1].split(/\r?\n/).forEach((line) => {
    if (!line || /^\s/.test(line)) {
      return;
    }

    const index = line.indexOf(':');
    if (index === -1) {
      return;
    }

    const key = line.slice(0, index).trim();
    const value = line.slice(index + 1).trim();
    fields[key] = value;
  });

  return {
    name: fields.name ? stripQuotes(fields.name) : '',
    description: fields.description ? stripQuotes(fields.description) : '',
    license: fields.license ? stripQuotes(fields.license) : '',
    tags: fields.tags ? parseInlineArray(fields.tags) : [],
  };
};

const walkSkillFiles = (rootDir, includeRootSkill = false) => {
  const entries = [];

  const walk = (dirPath) => {
    for (const entry of readdirSync(dirPath, { withFileTypes: true })) {
      if (entry.name === '.git') {
        continue;
      }

      const fullPath = resolve(dirPath, entry.name);
      if (entry.isDirectory()) {
        walk(fullPath);
        continue;
      }

      if (entry.isFile() && entry.name === 'SKILL.md') {
        entries.push(fullPath);
      }
    }
  };

  walk(rootDir);

  return entries
    .filter((filePath) => {
      const relativePath = relative(rootDir, filePath).replace(/\\/g, '/');
      const depth = relativePath.split('/').length;
      return includeRootSkill ? depth >= 2 : depth >= 3;
    })
    .sort((left, right) => left.localeCompare(right));
};

const deriveDisplayName = (collection, frontmatter, relativeDir) => {
  const folderName = basename(relativeDir);
  if (collection.prefix === 'air' && /^\d/.test(folderName)) {
    return frontmatter.name || folderName.replace(/^\d+-?/, '');
  }

  return folderName;
};

const updateLeadingCount = (text, count) => text.replace(/^\d+/, String(count));

const classification = JSON.parse(readFileSync(classificationPath, 'utf8'));
const registry = JSON.parse(readFileSync(registryPath, 'utf8'));
const seenIds = new Set();

const subSkillsByCollection = Object.fromEntries(collections.map((collection) => [collection.rootSkillId, []]));

for (const collection of collections) {
  const parentSkill = registry.skills.find((skill) => skill.id === collection.rootSkillId);
  if (!parentSkill) {
    throw new Error(`Registry entry '${collection.rootSkillId}' not found.`);
  }

  const files = walkSkillFiles(collection.rootDir, collection.includeRootSkill);
  const subSkills = files.map((filePath) => {
    const content = readFileSync(filePath, 'utf8');
    const frontmatter = parseFrontmatter(content, filePath);
    const relativeDir = relative(collection.rootDir, dirname(filePath)).replace(/\\/g, '/');
    const displayName = deriveDisplayName(collection, frontmatter, relativeDir);
    const id = `${collection.prefix}.${displayName}`;
    const classificationEntry = classification[id];

    if (!classificationEntry) {
      throw new Error(`Missing classification for ${id} (${relativeDir})`);
    }

    if (!frontmatter.description) {
      throw new Error(`Missing description in ${relative(repoRoot, filePath)}`);
    }

    seenIds.add(id);

    return {
      id,
      name: displayName,
      summary: {
        en: frontmatter.description,
        zh: frontmatter.description,
      },
      sparse_path: relativeDir,
      category: classificationEntry.category,
      ...(classificationEntry.subdiscipline ? { subdiscipline: classificationEntry.subdiscipline } : {}),
      ...(frontmatter.tags.length > 0 ? { tags: frontmatter.tags } : {}),
      ...(frontmatter.license ? { license: frontmatter.license } : {}),
      install: {
        method: 'sparse-checkout',
        url: parentSkill.install.url,
        sparse_path: relativeDir,
      },
      post_install: parentSkill.post_install ?? [],
    };
  });

  subSkillsByCollection[collection.rootSkillId] = subSkills;
}

const missingIds = Object.keys(classification).filter((id) => !seenIds.has(id));
if (missingIds.length > 0) {
  throw new Error(`Classification contains unknown ids:\n${missingIds.join('\n')}`);
}

for (const collection of collections) {
  const parentSkill = registry.skills.find((skill) => skill.id === collection.rootSkillId);
  const subSkills = subSkillsByCollection[collection.rootSkillId];

  parentSkill.skill_count = subSkills.length;
  parentSkill.is_collection = true;
  parentSkill.sub_skills = subSkills;
  parentSkill.summary.en = updateLeadingCount(parentSkill.summary.en, subSkills.length);
  parentSkill.summary.zh = updateLeadingCount(parentSkill.summary.zh, subSkills.length);
}

const totals = collections.map((collection) => {
  const count = subSkillsByCollection[collection.rootSkillId].length;
  return `${collection.rootSkillId}: ${count}`;
});

if (checkOnly) {
  console.log(totals.join('\n'));
} else {
  writeFileSync(registryPath, `${JSON.stringify(registry, null, 2)}\n`, 'utf8');
  console.log(`Updated registry with sub-skills.\n${totals.join('\n')}`);
}
