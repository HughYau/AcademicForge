#!/usr/bin/env node
// Refreshes the `stars` field of every top-level skill in registry/skills.json
// from the GitHub API. Set GITHUB_TOKEN to raise the rate limit in CI.

import { readFileSync, writeFileSync } from 'node:fs';
import { resolve, dirname } from 'node:path';
import { fileURLToPath } from 'node:url';

const registryPath = resolve(dirname(fileURLToPath(import.meta.url)), '../registry/skills.json');

export function parseGithubRepo(repositoryUrl) {
  const match = /github\.com\/([^/]+)\/([^/]+?)(?:\.git)?\/?$/.exec(repositoryUrl ?? '');
  return match ? `${match[1]}/${match[2]}` : null;
}

async function fetchStars(repo, token) {
  const response = await fetch(`https://api.github.com/repos/${repo}`, {
    headers: {
      Accept: 'application/vnd.github+json',
      'User-Agent': 'AcademicForge-refresh-stars',
      ...(token ? { Authorization: `Bearer ${token}` } : {}),
    },
  });

  if (!response.ok) {
    throw new Error(`GitHub API ${response.status} for ${repo}`);
  }

  const data = await response.json();
  return data.stargazers_count;
}

const isMain = process.argv[1] && resolve(process.argv[1]) === fileURLToPath(import.meta.url);

if (isMain) {
  const token = process.env.GITHUB_TOKEN ?? '';
  const registry = JSON.parse(readFileSync(registryPath, 'utf-8'));
  let updated = 0;
  let failed = 0;

  for (const skill of registry.skills) {
    const repo = parseGithubRepo(skill.repository);
    if (!repo) {
      console.warn(`skip ${skill.id}: no parsable GitHub repository`);
      continue;
    }

    try {
      const stars = await fetchStars(repo, token);
      if (typeof stars === 'number' && stars !== skill.stars) {
        console.log(`${skill.id}: ${skill.stars} -> ${stars}`);
        skill.stars = stars;
        updated += 1;
      }
    } catch (error) {
      failed += 1;
      console.warn(`skip ${skill.id}: ${error.message}`);
    }
  }

  if (updated > 0) {
    writeFileSync(registryPath, `${JSON.stringify(registry, null, 2)}\n`, 'utf-8');
  }

  console.log(`Done. ${updated} updated, ${failed} failed.`);
  if (failed > 0) {
    process.exitCode = 1;
  }
}
