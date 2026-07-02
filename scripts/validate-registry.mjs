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

    // Locally maintained packs (scientific-visualization, claude-science and its
    // sub-skills) install by sparse-checkout of this repo, so their content must
    // actually exist on disk at the advertised sparse_path.
    const sparsePath = record.install?.sparse_path;
    if (
      method === 'sparse-checkout'
      && sparsePath
      && (record.install?.url ?? '').includes('HughYau/AcademicForge')
    ) {
      const localPath = resolve(repoRoot, sparsePath);
      if (!existsSync(localPath)) {
        errors.push(`Local pack '${record.id}' is missing from ${sparsePath}`);
      }
    }

    if (record.summary?.en && record.summary?.zh && record.summary.en.trim() === record.summary.zh.trim()) {
      errors.push(`Skill '${record.id}' has untranslated summary.zh`);
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
