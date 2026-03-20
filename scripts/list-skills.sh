#!/bin/bash
# Academic Forge - List Installed Skills
# Displays all installed skills with their descriptions

set -e

# Auto-detect repo root
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
cd "$REPO_ROOT"

# Show help
if [[ "${1:-}" == "--help" || "${1:-}" == "-h" ]]; then
    echo "Usage: bash scripts/list-skills.sh"
    echo ""
    echo "Lists all installed Academic Forge skills with their descriptions."
    echo "Reads the 'description' field from each skill's SKILL.md frontmatter."
    exit 0
fi

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${BLUE}📚 Academic Forge - Installed Skills${NC}"
echo ""

total=0

# Iterate over all skill directories
for skill_dir in skills/*/; do
    [ -d "$skill_dir" ] || continue
    pack_name=$(basename "$skill_dir")

    # Count SKILL.md files in this pack
    skill_count=$(find "$skill_dir" -name "SKILL.md" 2>/dev/null | wc -l)
    [ "$skill_count" -eq 0 ] && continue

    echo -e "${CYAN}━━ $pack_name ($skill_count skills) ━━${NC}"

    # If the pack has a single top-level SKILL.md, show its description
    if [ -f "${skill_dir}SKILL.md" ]; then
        desc=$(sed -n '/^---$/,/^---$/{ /^description:/{ s/^description:[[:space:]]*//; s/^"//; s/"$//; p; } }' "${skill_dir}SKILL.md" 2>/dev/null | head -1)
        if [ -n "$desc" ]; then
            echo -e "  ${desc}"
        fi
    fi

    # If the pack has subdirectories with their own SKILL.md, list them
    if [ "$skill_count" -gt 1 ]; then
        find "$skill_dir" -mindepth 2 -name "SKILL.md" -print0 2>/dev/null | sort -z | while IFS= read -r -d '' skill_file; do
            rel_path=$(dirname "$skill_file")
            skill_name=$(basename "$rel_path")
            desc=$(sed -n '/^---$/,/^---$/{ /^description:/{ s/^description:[[:space:]]*//; s/^"//; s/"$//; p; } }' "$skill_file" 2>/dev/null | head -1)
            if [ -n "$desc" ]; then
                # Truncate long descriptions
                if [ ${#desc} -gt 80 ]; then
                    desc="${desc:0:77}..."
                fi
                echo -e "  ${GREEN}$skill_name${NC}: $desc"
            else
                echo -e "  ${GREEN}$skill_name${NC}"
            fi
        done
    fi

    total=$((total + skill_count))
    echo ""
done

echo -e "${BLUE}Total: $total skills across $(ls -d skills/*/ 2>/dev/null | wc -l) packs${NC}"
