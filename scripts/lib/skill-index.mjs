import { execFileSync } from 'node:child_process';
import { mkdtempSync, readdirSync, readFileSync, rmSync } from 'node:fs';
import { tmpdir } from 'node:os';
import { basename, dirname, join, relative, resolve } from 'node:path';

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

export const parseFrontmatter = (content, filePath) => {
  const match = content.match(/^---\r?\n([\s\S]*?)\r?\n---/);
  if (!match) {
    throw new Error(`Missing frontmatter in ${filePath}`);
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

const walkSkillFiles = (dirPath) => {
  const entries = [];

  const walk = (currentPath) => {
    for (const entry of readdirSync(currentPath, { withFileTypes: true })) {
      if (entry.name === '.git') {
        continue;
      }

      const fullPath = resolve(currentPath, entry.name);
      if (entry.isDirectory()) {
        walk(fullPath);
        continue;
      }

      if (entry.isFile() && entry.name === 'SKILL.md') {
        entries.push(fullPath);
      }
    }
  };

  walk(dirPath);
  return entries.sort((left, right) => left.localeCompare(right));
};

const deriveDisplayName = ({ prefix, frontmatter, relativeDir }) => {
  const folderName = basename(relativeDir);
  if (prefix === 'air' && /^\d/.test(folderName)) {
    return frontmatter.name || folderName.replace(/^\d+-?/, '');
  }

  return folderName;
};

export const collectSubSkills = ({
  rootDir,
  relativeRoot = '',
  includeRootSkill,
  prefix,
  parentSkill,
  classification,
}) => {
  const scanRoot = relativeRoot ? resolve(rootDir, relativeRoot) : rootDir;

  return walkSkillFiles(scanRoot)
    .filter((filePath) => {
      const relativePath = relative(rootDir, filePath).replace(/\\/g, '/');
      const depth = relativePath.split('/').length;
      return includeRootSkill ? depth >= 2 : depth >= 3;
    })
    .flatMap((filePath) => {
      const content = readFileSync(filePath, 'utf8');
      const frontmatter = parseFrontmatter(content, filePath);
      const relativeDir = relative(rootDir, dirname(filePath)).replace(/\\/g, '/');
      const displayName = deriveDisplayName({ prefix, frontmatter, relativeDir });
      const id = `${prefix}.${displayName}`;
      const classificationEntry = classification[id];

      if (!classificationEntry) {
        throw new Error(`Missing classification for ${id} (${relativeDir})`);
      }

      if (classificationEntry.disabled === true) {
        return [];
      }

      if (!frontmatter.description) {
        throw new Error(`Missing description in ${filePath}`);
      }

      const hasExplicitSubdiscipline = Object.prototype.hasOwnProperty.call(classificationEntry, 'subdiscipline');
      const fallbackSubdiscipline = classificationEntry.category === 'research'
        ? (hasExplicitSubdiscipline ? classificationEntry.subdiscipline : 'other')
        : classificationEntry.subdiscipline;

      return [{
        id,
        name: displayName,
        summary: {
          en: frontmatter.description,
          zh: frontmatter.description,
        },
        sparse_path: relativeDir,
        category: classificationEntry.category,
        ...(fallbackSubdiscipline !== undefined ? { subdiscipline: fallbackSubdiscipline } : {}),
        ...(frontmatter.tags.length > 0 ? { tags: frontmatter.tags } : {}),
        ...(frontmatter.license ? { license: frontmatter.license } : {}),
        install: {
          method: 'sparse-checkout',
          url: parentSkill.install.url,
          ...(parentSkill.install.ref ? { ref: parentSkill.install.ref } : {}),
          sparse_path: relativeDir,
        },
        post_install: parentSkill.post_install ?? [],
      }];
    });
};

export const withTemporaryClone = ({ url, ref, sparsePath }, callback) => {
  const tempDir = mkdtempSync(join(tmpdir(), 'skill-source-'));

  const checkoutRef = () => {
    if (!ref) {
      return;
    }

    try {
      execFileSync('git', ['-C', tempDir, 'checkout', '--detach', ref], { stdio: 'ignore' });
    } catch {
      execFileSync('git', ['-C', tempDir, 'fetch', '--depth', '1', 'origin', ref], { stdio: 'ignore' });
      execFileSync('git', ['-C', tempDir, 'checkout', '--detach', 'FETCH_HEAD'], { stdio: 'ignore' });
    }
  };

  try {
    if (sparsePath) {
      const cloneArgs = ['clone', '--depth', '1', '--filter=blob:none', '--sparse'];
      cloneArgs.push(url, tempDir);
      execFileSync('git', cloneArgs, { stdio: 'ignore' });
      execFileSync('git', ['-C', tempDir, 'sparse-checkout', 'set', sparsePath], { stdio: 'ignore' });
      checkoutRef();
    } else {
      const cloneArgs = ['clone', '--depth', '1'];
      cloneArgs.push(url, tempDir);
      execFileSync('git', cloneArgs, { stdio: 'ignore' });
      checkoutRef();
    }

    return callback(tempDir);
  } finally {
    rmSync(tempDir, { recursive: true, force: true });
  }
};
