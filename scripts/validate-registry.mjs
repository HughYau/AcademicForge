import { existsSync, readFileSync } from 'node:fs';
import { fileURLToPath } from 'node:url';
import { resolve } from 'node:path';

export function validateRegistry(registry, { repoRoot }) {
  const errors = [];
  const seenIds = new Set();

  const visit = (record) => {
    if (seenIds.has(record.id)) {
      errors.push(`Duplicate skill id '${record.id}'`);
    }
    seenIds.add(record.id);

    const method = record.install?.method;
    if (!['git-clone', 'sparse-checkout'].includes(method)) {
      errors.push(`Skill '${record.id}' uses unsupported install.method '${method}'`);
    }

    if (method === 'sparse-checkout' && !record.install?.sparse_path) {
      errors.push(`Skill '${record.id}' uses sparse-checkout without install.sparse_path`);
    }

    if (record.id === 'scientific-visualization') {
      const localPath = resolve(repoRoot, 'skills/scientific-visualization');
      if (!existsSync(localPath)) {
        errors.push("Local pack 'scientific-visualization' is missing from skills/scientific-visualization");
      }
    }
  };

  for (const skill of registry.skills ?? []) {
    visit(skill);
    for (const subSkill of skill.sub_skills ?? []) {
      visit(subSkill);
    }
  }

  return errors;
}

const currentFilePath = fileURLToPath(import.meta.url);
const executedFilePath = process.argv[1] ? resolve(process.argv[1]) : '';

if (executedFilePath === currentFilePath) {
  const repoRoot = resolve(fileURLToPath(new URL('.', import.meta.url)), '..');
  const registry = JSON.parse(readFileSync(resolve(repoRoot, 'registry/skills.json'), 'utf8'));
  const errors = validateRegistry(registry, { repoRoot });

  if (errors.length > 0) {
    errors.forEach((error) => console.error(error));
    process.exit(1);
  }

  console.log('Registry validation passed.');
}
