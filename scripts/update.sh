#!/bin/bash
# Academic Forge Update Script
# Updates all included skills to their latest versions

set -e  # Exit on error

# Auto-detect repo root from script location
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
cd "$REPO_ROOT"

# Load shared library functions
source "$SCRIPT_DIR/lib.sh"

# Show help
if [[ "${1:-}" == "--help" || "${1:-}" == "-h" ]]; then
    echo "Usage: bash scripts/update.sh"
    echo ""
    echo "Updates Academic Forge and all included skills to their latest versions."
    echo "This includes git submodules, skills-only snapshots, and post-sync processing."
    echo ""
    echo "Options:"
    echo "  --help, -h       Show this help message"
    echo "  --version, -V    Show forge version"
    exit 0
fi

if [[ "${1:-}" == "--version" || "${1:-}" == "-V" ]]; then
    version=$(grep -m1 'version:' forge.yaml 2>/dev/null | sed 's/.*"\(.*\)".*/\1/' || echo "unknown")
    echo "Academic Forge v${version}"
    exit 0
fi

echo -e "${BLUE}╔═══════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║                                           ║${NC}"
echo -e "${BLUE}║       🔄 Academic Forge Updater           ║${NC}"
echo -e "${BLUE}║                                           ║${NC}"
echo -e "${BLUE}╚═══════════════════════════════════════════╝${NC}"
echo ""

# Check if we're in the forge directory
if [ ! -f "forge.yaml" ]; then
    echo -e "${RED}❌ Error: Not in Academic Forge directory${NC}"
    echo "Please ensure the script is located inside the forge repository"
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
if git pull origin main 2>/dev/null || git pull origin master 2>/dev/null; then
    echo -e "${GREEN}✓ Forge repository updated${NC}"
else
    echo -e "${YELLOW}⚠️  Could not update forge repository (might be on a detached HEAD)${NC}"
fi

echo ""
echo -e "${BLUE}🔄 Updating all skills...${NC}"
echo ""

# Update all submodules
if git submodule update --remote --merge; then
    echo -e "${GREEN}✓ All submodule skills updated${NC}"
else
    echo -e "${RED}❌ Some skills failed to update${NC}"
    echo "You may need to resolve conflicts manually"
    exit 1
fi

# Sync skills-only snapshots
sync_superpowers
sync_planning_with_files

# Post-sync processing: patch paths, apply blacklist, clean ads
post_sync_all "scripts/skill-blacklist.txt"

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
