# Contributing

Thanks for helping improve AcademicForge.

## Branch Model

- `site-first`: public branch for site, registry, and installer flow
- `master`: legacy compatibility branch

Unless explicitly discussed, open contributions against `site-first`.

## Local Setup

```bash
npm run site:install
```

## Verification Before PR

```bash
npm run ci:validate
node scripts/build-skill-index.mjs --check
```

If you touch installer behavior, also run:

```bash
"D:\Application\Git\bin\bash.exe" scripts/tests/forge-install-local-registry.sh
pwsh -File scripts/tests/forge-install-local-registry.ps1
```

## Scope Guidelines

- Keep changes focused and small.
- Preserve the existing design language in `site/`.
- Do not reintroduce mirror-era scripts or submodule flows on `site-first`.

## Commit / PR Notes

- Use clear commit messages describing intent.
- Include validation evidence in your PR description.
