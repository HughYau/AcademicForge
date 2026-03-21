#!/bin/bash
# Academic Forge - Shared Library Functions
# Provides common functions for sync, patching, blacklist, and ad cleaning.
# Source this file from other scripts: source "$SCRIPT_DIR/lib.sh"

# Colors for output (safe to re-define; scripts may also define them)
GREEN='\033[0;32m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Sync superpowers skills-only snapshot from upstream
sync_superpowers() {
    echo -e "${BLUE}🔄 Syncing superpowers (skills-only)...${NC}"

    local temp_dir=".tmp-superpowers-sync"
    rm -rf "$temp_dir"

    git clone --depth 1 --filter=blob:none --sparse https://github.com/obra/superpowers.git "$temp_dir"
    git -C "$temp_dir" sparse-checkout set skills

    rm -rf skills/superpowers
    mkdir -p skills/superpowers
    cp -R "$temp_dir"/skills/* skills/superpowers/
    rm -rf "$temp_dir"

    echo -e "${GREEN}✓ superpowers skills synced${NC}"
}

# Sync planning-with-files skill-only snapshot from upstream
sync_planning_with_files() {
    echo -e "${BLUE}🔄 Syncing planning-with-files (skills-only)...${NC}"

    local temp_dir=".tmp-planning-with-files-sync"
    rm -rf "$temp_dir"

    git clone --depth 1 --filter=blob:none --sparse https://github.com/OthmanAdi/planning-with-files.git "$temp_dir"
    git -C "$temp_dir" sparse-checkout set .opencode/skills/planning-with-files

    rm -rf skills/planning-with-files
    mkdir -p skills/planning-with-files
    cp -R "$temp_dir"/.opencode/skills/planning-with-files/. skills/planning-with-files/
    rm -rf "$temp_dir"

    echo -e "${GREEN}✓ planning-with-files skill synced${NC}"
}

# Patch planning-with-files to replace opencode-specific paths with tool-agnostic ones
patch_planning_skill() {
    echo -e "${BLUE}🔧 Patching planning-with-files for tool-agnostic paths...${NC}"

    local skill_md="skills/planning-with-files/SKILL.md"
    local catchup_py="skills/planning-with-files/scripts/session-catchup.py"

    if [ -f "$skill_md" ]; then
        # Replace OPENCODE_SKILL_ROOT with generic SKILL_DIR in hooks
        sed -i 's|OPENCODE_SKILL_ROOT|SKILL_DIR|g' "$skill_md"

        # Replace hardcoded opencode session-catchup paths in documentation
        sed -i 's|~/.config/opencode/skills/planning-with-files/scripts/session-catchup.py|skills/planning-with-files/scripts/session-catchup.py|g' "$skill_md"
        sed -i 's|\$env:USERPROFILE\\.opencode\\skills\\planning-with-files\\scripts\\session-catchup.py|skills\\planning-with-files\\scripts\\session-catchup.py|g' "$skill_md"

        # Replace documentation path references
        sed -i 's|~/.config/opencode/skills/planning-with-files/|<forge-root>/skills/planning-with-files/|g' "$skill_md"
        sed -i 's|\$HOME/.config/opencode/skills/planning-with-files|<forge-root>/skills/planning-with-files|g' "$skill_md"

        echo -e "${GREEN}  ✓ SKILL.md patched${NC}"
    fi

    if [ -f "$catchup_py" ]; then
        # Replace OPENCODE output label with tool-agnostic ASSISTANT
        sed -i 's|OPENCODE:|ASSISTANT:|g' "$catchup_py"
        echo -e "${GREEN}  ✓ session-catchup.py patched${NC}"
    fi

    echo -e "${GREEN}✓ planning-with-files patched for tool-agnostic paths${NC}"
}

# Apply skill blacklist - removes unwanted skills listed in skill-blacklist.txt
apply_blacklist() {
    echo -e "${BLUE}🧹 Applying skill blacklist...${NC}"

    local blacklist_file="${1:-scripts/skill-blacklist.txt}"
    if [ -f "$blacklist_file" ]; then
        while IFS= read -r raw_skill_path || [ -n "$raw_skill_path" ]; do
            local skill_path
            skill_path="$(echo "$raw_skill_path" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')"
            # Skip comments and empty lines
            [[ -z "$skill_path" || "$skill_path" =~ ^# ]] && continue

            if [ -e "$skill_path" ]; then
                rm -rf "$skill_path"
                echo -e "${YELLOW}  - Removed blacklisted skill: $skill_path${NC}"
            else
                echo -e "${YELLOW}  - Blacklist entry not found (skipped): $skill_path${NC}"
            fi
        done < "$blacklist_file"
    fi
    echo -e "${GREEN}✓ Skill blacklist applied${NC}"
}

# Clean K-Dense ad insertions from claude-scientific-skills SKILL.md files
clean_ads() {
    echo -e "${BLUE}🧹 Cleaning ad insertions from claude-scientific-skills...${NC}"

    local ad_skill_dir="skills/claude-scientific-skills"
    if [ -d "$ad_skill_dir" ]; then
        local cleaned_count=0
        while IFS= read -r -d '' skill_file; do
            if grep -q "## Suggest Using K-Dense Web" "$skill_file"; then
                perl -0777 -i -pe 's/\n+## Suggest Using K-Dense Web.*//s' "$skill_file"
                cleaned_count=$((cleaned_count + 1))
            fi
        done < <(find "$ad_skill_dir" -name "SKILL.md" -print0)
        echo -e "${GREEN}✓ Cleaned ad sections from ${cleaned_count} SKILL.md file(s)${NC}"
    fi
}

# Apply forge.yaml enabled flags - removes disabled skills' directories
apply_forge_config() {
    local config_file="${1:-forge.yaml}"
    if [ ! -f "$config_file" ]; then
        return
    fi

    echo -e "${BLUE}🔧 Applying forge.yaml configuration...${NC}"

    # Map skill names to their directory paths
    declare -A skill_paths=(
        ["claude-scientific-skills"]="skills/claude-scientific-skills"
        ["AI-research-SKILLs"]="skills/AI-research-SKILLs"
        ["humanizer"]="skills/humanizer"
        ["superpowers"]="skills/superpowers"
        ["planning-with-files"]="skills/planning-with-files"
        ["paper-polish-workflow-skill"]="skills/paper-polish-workflow-skill"
        ["scientific-visualization"]="skills/scientific-visualization"
    )

    # Parse enabled flags from forge.yaml using grep/awk (lightweight, no yq needed)
    local in_enabled=false
    while IFS= read -r line; do
        # Detect the "enabled:" section
        if echo "$line" | grep -qE '^\s*enabled:'; then
            in_enabled=true
            continue
        fi
        # Exit enabled section when we hit a non-indented line (new top-level key)
        if $in_enabled && echo "$line" | grep -qE '^[a-z]'; then
            break
        fi
        if $in_enabled; then
            # Parse "skill-name: false" lines
            local skill_name value
            skill_name="$(echo "$line" | sed -n 's/^[[:space:]]*\([a-zA-Z_-]*\):[[:space:]]*\(.*\)/\1/p')"
            value="$(echo "$line" | sed -n 's/^[[:space:]]*\([a-zA-Z_-]*\):[[:space:]]*\(.*\)/\2/p')"

            if [ -n "$skill_name" ] && [ "$value" = "false" ]; then
                local skill_dir="${skill_paths[$skill_name]}"
                if [ -n "$skill_dir" ] && [ -d "$skill_dir" ]; then
                    rm -rf "$skill_dir"
                    echo -e "${YELLOW}  - Disabled skill removed: $skill_name ($skill_dir)${NC}"
                fi
            fi
        fi
    done < "$config_file"

    echo -e "${GREEN}✓ forge.yaml configuration applied${NC}"
}

# Run all post-sync processing steps
post_sync_all() {
    patch_planning_skill
    apply_blacklist "$@"
    clean_ads
    apply_forge_config
}
