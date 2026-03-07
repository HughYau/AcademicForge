#!/bin/bash
# Academic Forge Update Script
# Updates all included skills to their latest versions

set -e  # Exit on error

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${BLUE}╔═══════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║                                           ║${NC}"
echo -e "${BLUE}║       🔄 Academic Forge Updater           ║${NC}"
echo -e "${BLUE}║                                           ║${NC}"
echo -e "${BLUE}╚═══════════════════════════════════════════╝${NC}"
echo ""

# Check if we're in the forge directory
if [ ! -f "forge.yaml" ]; then
    echo -e "${RED}❌ Error: Not in Academic Forge directory${NC}"
    echo "Please run this script from the forge root directory"
    exit 1
fi

# Check for uncommitted changes
if ! git diff-index --quiet HEAD -- 2>/dev/null; then
    echo -e "${YELLOW}⚠️  Warning: You have uncommitted changes${NC}"
    echo "It's recommended to commit or stash changes before updating."
    read -p "Continue anyway? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo -e "${RED}Update cancelled${NC}"
        exit 0
    fi
fi

# Update the forge repository itself
echo -e "${BLUE}📦 Updating forge repository...${NC}"
git pull origin main || git pull origin master

if [ $? -eq 0 ]; then
    echo -e "${GREEN}✓ Forge repository updated${NC}"
else
    echo -e "${YELLOW}⚠️  Could not update forge repository (might be on a detached HEAD)${NC}"
fi

echo ""
echo -e "${BLUE}🔄 Updating all skills...${NC}"
echo ""

# Update all submodules
git submodule update --remote --merge

if [ $? -eq 0 ]; then
    echo -e "${GREEN}✓ All skills updated${NC}"
else
    echo -e "${RED}❌ Some skills failed to update${NC}"
    echo "You may need to resolve conflicts manually"
    exit 1
fi

echo -e "${BLUE}🔄 Syncing superpowers (skills-only)...${NC}"

TEMP_DIR=".tmp-superpowers-sync"
rm -rf "$TEMP_DIR"

git clone --depth 1 --filter=blob:none --sparse https://github.com/obra/superpowers.git "$TEMP_DIR"
git -C "$TEMP_DIR" sparse-checkout set skills

rm -rf skills/superpowers
mkdir -p skills/superpowers
cp -R "$TEMP_DIR"/skills/* skills/superpowers/
rm -rf "$TEMP_DIR"

echo -e "${GREEN}✓ superpowers skills synced${NC}"

echo -e "${BLUE}🔄 Syncing planning-with-files (skills-only)...${NC}"

TEMP_DIR=".tmp-planning-with-files-sync"
rm -rf "$TEMP_DIR"

git clone --depth 1 --filter=blob:none --sparse https://github.com/OthmanAdi/planning-with-files.git "$TEMP_DIR"
git -C "$TEMP_DIR" sparse-checkout set .opencode/skills/planning-with-files

rm -rf skills/planning-with-files
mkdir -p skills/planning-with-files
cp -R "$TEMP_DIR"/.opencode/skills/planning-with-files/. skills/planning-with-files/
rm -rf "$TEMP_DIR"

echo -e "${GREEN}✓ planning-with-files skill synced${NC}"

echo -e "${BLUE}🧹 Applying skill blacklist...${NC}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
BLACKLIST_FILE="$REPO_ROOT/scripts/skill-blacklist.txt"
if [ -f "$BLACKLIST_FILE" ]; then
    while IFS= read -r raw_skill_path || [ -n "$raw_skill_path" ]; do
        skill_path="$(echo "$raw_skill_path" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')"
        # Skip comments and empty lines
        [[ -z "$skill_path" || "$skill_path" =~ ^# ]] && continue

        if [[ "$skill_path" = /* ]]; then
            target_path="$skill_path"
        else
            target_path="$REPO_ROOT/$skill_path"
        fi

        if [ -e "$target_path" ]; then
            rm -rf "$target_path"
            echo -e "${YELLOW}  - Removed blacklisted skill: $skill_path${NC}"
        else
            echo -e "${YELLOW}  - Blacklist entry not found (skipped): $skill_path${NC}"
        fi
    done < "$BLACKLIST_FILE"
fi
echo -e "${GREEN}✓ Skill blacklist applied${NC}"

echo -e "${BLUE}🧹 Cleaning ad insertions from claude-scientific-skills...${NC}"
AD_SKILL_DIR="skills/claude-scientific-skills"
if [ -d "$AD_SKILL_DIR" ]; then
    cleaned_count=0
    while IFS= read -r -d '' skill_file; do
        if grep -q "## Suggest Using K-Dense Web" "$skill_file"; then
            perl -0777 -i -pe 's/\n+## Suggest Using K-Dense Web.*//s' "$skill_file"
            cleaned_count=$((cleaned_count + 1))
        fi
    done < <(find "$AD_SKILL_DIR" -name "SKILL.md" -print0)
    echo -e "${GREEN}✓ Cleaned ad sections from ${cleaned_count} SKILL.md file(s)${NC}"
fi

echo ""
echo -e "${BLUE}📊 Update Summary:${NC}"
echo ""

# Show status of each submodule
git submodule foreach 'echo "📚 $name:"; git log --oneline -3 --decorate; echo ""'
echo "📚 skills/superpowers: synced from obra/superpowers (skills/)"
echo "📚 skills/planning-with-files: synced from OthmanAdi/planning-with-files (.opencode/skills/planning-with-files)"
echo ""

echo ""
echo -e "${GREEN}╔═══════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║                                           ║${NC}"
echo -e "${GREEN}║        ✨ Update Complete! ✨             ║${NC}"
echo -e "${GREEN}║                                           ║${NC}"
echo -e "${GREEN}╚═══════════════════════════════════════════╝${NC}"
echo ""

echo -e "${BLUE}📖 Next Steps:${NC}"
echo "  1. Review changes: git status"
echo "  2. Test the updated skills with your projects"
echo "  3. Commit if everything works: git add . && git commit -m 'Update skills'"
echo ""

# Check if there are any changes to commit
if ! git diff-index --quiet HEAD -- 2>/dev/null; then
    echo -e "${YELLOW}⚠️  You have uncommitted changes after the update${NC}"
    echo "Run 'git status' to see what changed"
    echo ""
    read -p "Would you like to commit these changes? (y/N): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        git add .
        git commit -m "chore: update skills to latest versions"
        echo -e "${GREEN}✓ Changes committed${NC}"
    fi
fi

echo -e "${GREEN}Happy writing! 🎓📝${NC}"
