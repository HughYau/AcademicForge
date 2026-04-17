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
REGISTRY_SOURCE="${FORGE_REGISTRY_URL:-https://raw.githubusercontent.com/HughYau/AcademicForge/refs/heads/site-first/registry/skills.json}"
REGISTRY_FILE=""

usage() {
  cat <<'EOF'
Usage: forge-install.sh --tool <claude|opencode|codex> --skills <id1,id2,...> [--path <dir>] [--registry <path-or-url>]

Options:
  --tool     Target tool: claude, opencode, or codex
  --skills   Comma-separated skill IDs from the registry
  --path     Custom install path (overrides --tool default)
  --registry Registry JSON file path or URL
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
    --registry)
      [[ $# -ge 2 ]] || {
        echo -e "${RED}Error: --registry requires a value${NC}"
        exit 1
      }
      REGISTRY_SOURCE="$2"
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

for cmd in git curl; do
  if ! command -v "$cmd" >/dev/null 2>&1; then
    echo -e "${RED}Error: '$cmd' is required but not installed.${NC}"
    exit 1
  fi
done

PYTHON_CMD=""
for candidate in python3 python; do
  if command -v "$candidate" >/dev/null 2>&1 && "$candidate" -c "import sys" >/dev/null 2>&1; then
    PYTHON_CMD="$candidate"
    break
  fi
done

if [[ -z "$PYTHON_CMD" ]]; then
  echo -e "${RED}Error: either 'python3' or 'python' is required but not installed.${NC}"
  exit 1
fi

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

echo -e "${BLUE}Loading skill registry...${NC}"
case "$REGISTRY_SOURCE" in
  http://*|https://*)
    if ! curl -fsSL "$REGISTRY_SOURCE" -o "$REGISTRY_FILE"; then
      echo -e "${RED}Error: failed to download registry from $REGISTRY_SOURCE${NC}"
      exit 1
    fi
    ;;
  *)
    if [[ ! -f "$REGISTRY_SOURCE" ]]; then
      echo -e "${RED}Error: registry file '$REGISTRY_SOURCE' does not exist${NC}"
      exit 1
    fi
    cp "$REGISTRY_SOURCE" "$REGISTRY_FILE"
    ;;
esac
echo -e "${GREEN}Registry loaded.${NC}"
echo ""

mkdir -p "$INSTALL_PATH"

json_extract() {
  local skill_id="$1"
  local field_path="$2"

  SKILL_ID="$skill_id" FIELD_PATH="$field_path" "$PYTHON_CMD" - "$REGISTRY_FILE" <<'PY'
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

  cleaned_count="$(TARGET_DIR="$target_dir" "$PYTHON_CMD" - <<'PY'
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

checkout_ref() {
  local repo_dir="$1"
  local ref="$2"

  if [[ -z "$ref" ]]; then
    return 0
  fi

  if git -C "$repo_dir" checkout --detach "$ref" >/dev/null 2>&1; then
    return 0
  fi

  git -C "$repo_dir" fetch --depth 1 origin "$ref" >/dev/null 2>&1 && git -C "$repo_dir" checkout --detach FETCH_HEAD >/dev/null 2>&1
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
  REF="$(json_extract "$sid" "install.ref" 2>/dev/null || true)"

  if [[ -z "$METHOD" || -z "$URL" ]]; then
    echo -e "${RED}  Skill '$sid' not found in registry. Skipping.${NC}"
    FAILED+=("$sid")
    continue
  fi

  TARGET="${INSTALL_PATH}/${sid}"
  rm -rf "$TARGET"

  case "$METHOD" in
    git-clone)
      clone_args=(clone --depth 1)
      clone_args+=("$URL" "$TARGET")

      if git "${clone_args[@]}" >/dev/null 2>&1; then
        if ! checkout_ref "$TARGET" "$REF"; then
          echo -e "${RED}  Failed to checkout ref $REF${NC}"
          rm -rf "$TARGET"
          FAILED+=("$sid")
          continue
        fi
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

      TMP_CHECKOUT_DIR="$(mktemp -d "${TMPDIR:-/tmp}/forge-${sid}.XXXXXX")"
      clone_args=(clone --depth 1 --filter=blob:none --sparse)
      clone_args+=("$URL" "$TMP_CHECKOUT_DIR")

      if git "${clone_args[@]}" >/dev/null 2>&1; then
        if ! checkout_ref "$TMP_CHECKOUT_DIR" "$REF"; then
          rm -rf "$TMP_CHECKOUT_DIR"
          echo -e "${RED}  Failed to checkout ref $REF${NC}"
          FAILED+=("$sid")
          continue
        fi
        if ! git -C "$TMP_CHECKOUT_DIR" sparse-checkout set "$SPARSE_PATH" >/dev/null 2>&1; then
          rm -rf "$TMP_CHECKOUT_DIR"
          echo -e "${RED}  Failed to set sparse-checkout path $SPARSE_PATH${NC}"
          FAILED+=("$sid")
          continue
        fi

        SOURCE_DIR="$TMP_CHECKOUT_DIR/$SPARSE_PATH"
        if [[ ! -d "$SOURCE_DIR" ]]; then
          rm -rf "$TMP_CHECKOUT_DIR"
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
        rm -rf "$TMP_CHECKOUT_DIR"
        echo -e "${GREEN}  Sparse-checkout completed.${NC}"
      else
        rm -rf "$TMP_CHECKOUT_DIR"
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
