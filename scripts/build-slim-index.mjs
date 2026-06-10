#!/usr/bin/env node
// Generates site/public/index.slim.json (compact catalog for AI agents)
// and mirrors registry/skills.json into site/public/skills.json so both
// are reachable on the GitHub Pages domain.

import { readFileSync, writeFileSync, copyFileSync } from 'node:fs';
import { resolve, dirname } from 'node:path';
import { fileURLToPath } from 'node:url';

const rootDir = resolve(dirname(fileURLToPath(import.meta.url)), '..');
const registryPath = resolve(rootDir, 'registry/skills.json');
const slimPath = resolve(rootDir, 'site/public/index.slim.json');
const mirrorPath = resolve(rootDir, 'site/public/skills.json');

const SUMMARY_LIMIT = 200;

const truncate = (text) => {
  if (typeof text !== 'string' || text.length <= SUMMARY_LIMIT) {
    return text;
  }
  return `${text.slice(0, SUMMARY_LIMIT - 1).trimEnd()}…`;
};

export function buildSlimIndex(registry) {
  const slimEntry = (record, parentId) => ({
    id: record.id,
    name: record.name,
    summary: {
      en: truncate(record.summary?.en),
      zh: truncate(record.summary?.zh),
    },
    tags: record.tags ?? [],
    ...(typeof record.skill_count === 'number' ? { skill_count: record.skill_count } : {}),
    ...(parentId ? { collection: parentId } : {}),
  });

  const entries = [];
  for (const skill of registry.skills) {
    entries.push(slimEntry(skill));
    for (const subSkill of skill.sub_skills ?? []) {
      entries.push(slimEntry(subSkill, skill.id));
    }
  }

  return {
    generated_from: 'registry/skills.json',
    full_registry: [
      'https://hughyau.github.io/AcademicForge/skills.json',
      'https://raw.githubusercontent.com/HughYau/AcademicForge/refs/heads/site-first/registry/skills.json',
    ],
    entries,
  };
}

const isMain = process.argv[1] && resolve(process.argv[1]) === fileURLToPath(import.meta.url);

if (isMain) {
  const registry = JSON.parse(readFileSync(registryPath, 'utf-8'));
  const slim = buildSlimIndex(registry);
  writeFileSync(slimPath, `${JSON.stringify(slim)}\n`, 'utf-8');
  copyFileSync(registryPath, mirrorPath);
  console.log(`Wrote ${slimPath} (${slim.entries.length} entries) and mirrored skills.json.`);
}
