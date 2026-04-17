#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
TMP_DIR="$(mktemp -d "${TMPDIR:-/tmp}/forge-install-test.XXXXXX")"
REGISTRY_FILE="$TMP_DIR/registry.json"
OUTPUT_DIR="$TMP_DIR/output"
BIN_DIR="$TMP_DIR/bin"
LOCAL_REF="$(git -C "$REPO_ROOT" rev-parse HEAD)"

cleanup() {
  rm -rf "$TMP_DIR"
}

trap cleanup EXIT

mkdir -p "$BIN_DIR"
if command -v python >/dev/null 2>&1; then
  REAL_PYTHON="$(command -v python)"
elif command -v python3 >/dev/null 2>&1; then
  REAL_PYTHON="$(command -v python3)"
else
  echo "python is required for this test" >&2
  exit 1
fi

cat > "$BIN_DIR/python3" <<'SH'
#!/usr/bin/env bash
echo "python3 shim intentionally unavailable in this test" >&2
exit 127
SH
chmod +x "$BIN_DIR/python3"

cat > "$BIN_DIR/python" <<SH
#!/usr/bin/env bash
exec "$REAL_PYTHON" "\$@"
SH
chmod +x "$BIN_DIR/python"

export PATH="$BIN_DIR:$PATH"

cat > "$REGISTRY_FILE" <<JSON
{
  "skills": [
    {
      "id": "scientific-visualization",
      "name": "Scientific Visualization",
      "summary": { "en": "local test", "zh": "local test" },
      "author": "AcademicForge",
      "repository": "https://github.com/HughYau/AcademicForge",
      "license": "MIT",
      "skill_count": 1,
      "stars": 0,
      "tags": ["visualization"],
      "install": {
        "method": "sparse-checkout",
        "url": "$REPO_ROOT",
        "ref": "$LOCAL_REF",
        "sparse_path": "skills/scientific-visualization"
      },
      "post_install": []
    }
  ]
}
JSON

bash "$REPO_ROOT/scripts/forge-install.sh" \
  --tool opencode \
  --skills scientific-visualization \
  --registry "$REGISTRY_FILE" \
  --path "$OUTPUT_DIR"

test -f "$OUTPUT_DIR/scientific-visualization/SKILL.md"
