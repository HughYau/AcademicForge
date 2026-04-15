#!/usr/bin/env bash

set -euo pipefail

GREEN='\033[0;32m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

TOOL=""
SKILLS=""
INSTALL_PATH=""
REGISTRY_URL="${FORGE_REGISTRY_URL:-https://raw.githubusercontent.com/HughYau/AcademicForge/refs/heads/master/registry/skills.json}"
REGISTRY_FILE=""

usage() {
  cat <<'EOF'
Usage: forge-install.sh --tool <claude|opencode|codex> --skills <id1,id2,...> [--path <dir>]

Options:
  --tool     Target tool: claude, opencode, or codex
  --skills   Comma-separated skill IDs from the registry
  --path     Custom install path (overrides --tool default)
  --help     Show this help
EOF
}

cleanup() {
  if [[ -n "$REGISTRY_FILE" && -f "$REGISTRY_FILE" ]]; then
    rm -f "$REGISTRY_FILE"
  fi
}

trap cleanup EXIT

while [[ $# -gt 0 ]]; do
  case "$1" in
    --tool)
      [[ $# -ge 2 ]] || {
        echo -e "${RED}Error: --tool requires a value${NC}"
        exit 1
      }
      TOOL="$2"
      shift 2
      ;;
    --skills)
      [[ $# -ge 2 ]] || {
        echo -e "${RED}Error: --skills requires a value${NC}"
        exit 1
      }
      SKILLS="$2"
      shift 2
      ;;
    --path)
      [[ $# -ge 2 ]] || {
        echo -e "${RED}Error: --path requires a value${NC}"
        exit 1
      }
      INSTALL_PATH="$2"
      shift 2
      ;;
    --help|-h)
      usage
      exit 0
      ;;
    *)
      echo -e "${RED}Unknown option: $1${NC}"
      usage
      exit 1
      ;;
  esac
done

if [[ -z "$TOOL" || -z "$SKILLS" ]]; then
  echo -e "${RED}Error: --tool and --skills are required${NC}"
  usage
  exit 1
fi

if [[ -z "$INSTALL_PATH" ]]; then
  case "$TOOL" in
    claude)
      INSTALL_PATH=".claude/skills"
      ;;
    opencode)
      INSTALL_PATH=".opencode/skills"
      ;;
    codex)
      INSTALL_PATH=".codex/skills"
      ;;
    *)
      echo -e "${RED}Error: unknown tool '$TOOL'. Use claude, opencode, or codex.${NC}"
      exit 1
      ;;
  esac
fi

for cmd in git curl python3; do
  if ! command -v "$cmd" >/dev/null 2>&1; then
    echo -e "${RED}Error: '$cmd' is required but not installed.${NC}"
    exit 1
  fi
done

echo ""
echo -e "${BLUE}===============================================${NC}"
echo -e "${BLUE} Skill Configurator - Forge Installer${NC}"
echo -e "${BLUE}===============================================${NC}"
echo ""
echo -e "${CYAN}Tool:${NC}   $TOOL"
echo -e "${CYAN}Skills:${NC} $SKILLS"
echo -e "${CYAN}Path:${NC}   $INSTALL_PATH"
echo ""

REGISTRY_FILE="$(mktemp "${TMPDIR:-/tmp}/forge-registry.XXXXXX.json")"

echo -e "${BLUE}Downloading skill registry...${NC}"
if ! curl -fsSL "$REGISTRY_URL" -o "$REGISTRY_FILE"; then
  echo -e "${RED}Error: failed to download registry from $REGISTRY_URL${NC}"
  exit 1
fi
echo -e "${GREEN}Registry loaded.${NC}"
echo ""

mkdir -p "$INSTALL_PATH"

json_extract() {
  local skill_id="$1"
  local field_path="$2"

  SKILL_ID="$skill_id" FIELD_PATH="$field_path" python3 - "$REGISTRY_FILE" <<'PY'
import json
import os
import sys

registry_path = sys.argv[1]
skill_id = os.environ["SKILL_ID"]
field_path = os.environ["FIELD_PATH"]

with open(registry_path, encoding="utf-8") as handle:
    data = json.load(handle)

record = None
for skill in data["skills"]:
    if skill["id"] == skill_id:
        record = skill
        break

    for sub_skill in skill.get("sub_skills", []):
        if sub_skill["id"] == skill_id:
            record = sub_skill
            break

    if record is not None:
        break

if record is None:
    raise SystemExit(1)

value = record
for part in field_path.split("."):
    value = value[part]
if isinstance(value, (dict, list)):
    print(json.dumps(value, ensure_ascii=False))
elif value is None:
    print("")
else:
    print(value)
raise SystemExit(0)

PY
}

post_clean_ads() {
  local target_dir="$1"
  local cleaned_count

  cleaned_count="$(TARGET_DIR="$target_dir" python3 - <<'PY'
from pathlib import Path
import os
import re

root = Path(os.environ["TARGET_DIR"])
pattern = re.compile(r"\n+## Suggest Using K-Dense Web.*", re.S)
count = 0

for path in root.rglob("SKILL.md"):
    text = path.read_text(encoding="utf-8")
    updated = pattern.sub("", text)
    if updated != text:
        path.write_text(updated, encoding="utf-8")
        count += 1

print(count)
PY
)"

  if [[ "$cleaned_count" != "0" ]]; then
    echo -e "${YELLOW}  Cleaned ad sections from ${cleaned_count} file(s)${NC}"
  fi
}

SUCCESS=()
FAILED=()

IFS=',' read -r -a SKILL_IDS <<< "$SKILLS"

for raw_id in "${SKILL_IDS[@]}"; do
  sid="$(printf '%s' "$raw_id" | xargs)"

  if [[ -z "$sid" ]]; then
    continue
  fi

  echo -e "${CYAN}Installing: ${sid}${NC}"

  METHOD="$(json_extract "$sid" "install.method" 2>/dev/null || true)"
  URL="$(json_extract "$sid" "install.url" 2>/dev/null || true)"

  if [[ -z "$METHOD" || -z "$URL" ]]; then
    echo -e "${RED}  Skill '$sid' not found in registry. Skipping.${NC}"
    FAILED+=("$sid")
    continue
  fi

  TARGET="${INSTALL_PATH}/${sid}"
  rm -rf "$TARGET"

  case "$METHOD" in
    git-clone)
      if git clone --depth 1 "$URL" "$TARGET" >/dev/null 2>&1; then
        rm -rf "$TARGET/.git"
        echo -e "${GREEN}  Cloned successfully.${NC}"
      else
        echo -e "${RED}  Failed to clone $URL${NC}"
        FAILED+=("$sid")
        continue
      fi
      ;;
    sparse-checkout)
      SPARSE_PATH="$(json_extract "$sid" "install.sparse_path" 2>/dev/null || true)"
      if [[ -z "$SPARSE_PATH" ]]; then
        echo -e "${RED}  sparse-checkout requires sparse_path. Skipping.${NC}"
        FAILED+=("$sid")
        continue
      fi

      TMPDIR="$(mktemp -d "${TMPDIR:-/tmp}/forge-${sid}.XXXXXX")"
      if git clone --depth 1 --filter=blob:none --sparse "$URL" "$TMPDIR" >/dev/null 2>&1; then
        if ! git -C "$TMPDIR" sparse-checkout set "$SPARSE_PATH" >/dev/null 2>&1; then
          rm -rf "$TMPDIR"
          echo -e "${RED}  Failed to set sparse-checkout path $SPARSE_PATH${NC}"
          FAILED+=("$sid")
          continue
        fi

        SOURCE_DIR="$TMPDIR/$SPARSE_PATH"
        if [[ ! -d "$SOURCE_DIR" ]]; then
          rm -rf "$TMPDIR"
          echo -e "${RED}  Sparse path '$SPARSE_PATH' not found in repository.${NC}"
          FAILED+=("$sid")
          continue
        fi

        mkdir -p "$TARGET"
        shopt -s dotglob nullglob
        items=("$SOURCE_DIR"/*)
        if [[ ${#items[@]} -gt 0 ]]; then
          cp -R "${items[@]}" "$TARGET/"
        fi
        shopt -u dotglob nullglob
        rm -rf "$TMPDIR"
        echo -e "${GREEN}  Sparse-checkout completed.${NC}"
      else
        rm -rf "$TMPDIR"
        echo -e "${RED}  Failed to sparse-checkout $URL${NC}"
        FAILED+=("$sid")
        continue
      fi
      ;;
    *)
      echo -e "${RED}  Unknown install method: $METHOD. Skipping.${NC}"
      FAILED+=("$sid")
      continue
      ;;
  esac

  POST_INSTALL="$(json_extract "$sid" "post_install" 2>/dev/null || true)"
  if [[ "$POST_INSTALL" == *'"clean_ads"'* ]]; then
    post_clean_ads "$TARGET"
  fi

  SUCCESS+=("$sid")
done

echo ""
echo -e "${BLUE}===============================================${NC}"
echo -e "${BLUE} Installation Summary${NC}"
echo -e "${BLUE}===============================================${NC}"

if [[ ${#SUCCESS[@]} -gt 0 ]]; then
  for skill in "${SUCCESS[@]}"; do
    echo -e "${GREEN}  OK  $skill${NC}"
  done
fi

if [[ ${#FAILED[@]} -gt 0 ]]; then
  for skill in "${FAILED[@]}"; do
    echo -e "${RED}  FAIL $skill${NC}"
  done
fi

echo ""
echo -e "${CYAN}Installed skill packs live under:${NC} $INSTALL_PATH"
