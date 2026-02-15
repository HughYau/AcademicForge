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

echo -e "${BLUE}🧹 Applying skill blacklist...${NC}"
BLACKLIST_FILE="scripts/skill-blacklist.txt"
if [ -f "$BLACKLIST_FILE" ]; then
    while IFS= read -r skill_path; do
        # Skip comments and empty lines
        [[ -z "$skill_path" || "$skill_path" =~ ^# ]] && continue

        if [ -e "$skill_path" ]; then
            rm -rf "$skill_path"
            echo -e "${YELLOW}  - Removed blacklisted skill: $skill_path${NC}"
        fi
    done < "$BLACKLIST_FILE"
fi
echo -e "${GREEN}✓ Skill blacklist applied${NC}"

echo ""
echo -e "${BLUE}📊 Update Summary:${NC}"
echo ""

# Show status of each submodule
git submodule foreach 'echo "📚 $name:"; git log --oneline -3 --decorate; echo ""'
echo "📚 skills/superpowers: synced from obra/superpowers (skills/)"
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
