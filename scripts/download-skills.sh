#!/bin/bash
# Academic Forge - Download Skills Script
# Bash version - Downloads skills submodules and syncs skills-only sources

set -e  # Exit on error

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo ""
echo -e "${BLUE}╔═══════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║                                           ║${NC}"
echo -e "${BLUE}║    📚 Academic Forge - Skills Downloader  ║${NC}"
echo -e "${BLUE}║                                           ║${NC}"
echo -e "${BLUE}╚═══════════════════════════════════════════╝${NC}"
echo ""

# Check if git is installed
if ! command -v git &> /dev/null; then
    echo -e "${RED}❌ Error: git is not installed${NC}"
    echo "Please install git and try again."
    exit 1
fi
echo -e "${GREEN}✓ Git found${NC}"

# Check if we're in a git repository
if [ ! -d ".git" ]; then
    echo -e "${RED}❌ Error: Not in a git repository${NC}"
    echo "Please run this script from the root of the AcademicForge repository"
    exit 1
fi

echo ""
echo -e "${BLUE}📥 Downloading skills...${NC}"
echo ""

# Initialize and update only skills folder submodules
echo -e "${CYAN}→ Initializing submodules...${NC}"
git submodule init

echo -e "${CYAN}→ Downloading skills submodules...${NC}"

# Define skills submodules
SKILLS_SUBMODULES=(
    "skills/humanizer"
    "skills/AI-research-SKILLs"
    "skills/claude-scientific-skills"
)

# Download each submodule
for submodule in "${SKILLS_SUBMODULES[@]}"; do
    echo -e "${YELLOW}  ↓ Updating $submodule${NC}"
    if git submodule update --init --recursive "$submodule"; then
        echo -e "${GREEN}  ✓ $submodule downloaded successfully${NC}"
    else
        echo -e "${RED}  ⚠ Warning: Failed to download $submodule${NC}"
    fi
done

echo ""
echo -e "${CYAN}→ Syncing skills/superpowers (skills-only)...${NC}"

TEMP_DIR=".tmp-superpowers-sync"
rm -rf "$TEMP_DIR"

git clone --depth 1 --filter=blob:none --sparse https://github.com/obra/superpowers.git "$TEMP_DIR"
git -C "$TEMP_DIR" sparse-checkout set skills

rm -rf skills/superpowers
mkdir -p skills/superpowers
cp -R "$TEMP_DIR"/skills/* skills/superpowers/
rm -rf "$TEMP_DIR"

echo -e "${GREEN}  ✓ skills/superpowers synced successfully${NC}"

echo ""
echo -e "${CYAN}→ Applying skill blacklist...${NC}"
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
echo -e "${GREEN}  ✓ Skill blacklist applied${NC}"

echo ""
echo -e "${GREEN}╔═══════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║                                           ║${NC}"
echo -e "${GREEN}║            ✨ Download Complete!          ║${NC}"
echo -e "${GREEN}║                                           ║${NC}"
echo -e "${GREEN}╚═══════════════════════════════════════════╝${NC}"
echo ""

echo -e "${BLUE}📂 Skills location:${NC} $(pwd)/skills/"
echo ""
echo -e "${BLUE}Available skills:${NC}"
for submodule in "${SKILLS_SUBMODULES[@]}"; do
    skill_name=$(basename "$submodule")
    if [ -d "$submodule" ] && [ -n "$(ls -A "$submodule" 2>/dev/null)" ]; then
        echo -e "${GREEN}  ✓ $skill_name${NC}"
    else
        echo -e "${RED}  ✗ $skill_name (not found)${NC}"
    fi
done

if [ -d "skills/superpowers" ] && [ -n "$(ls -A "skills/superpowers" 2>/dev/null)" ]; then
    echo -e "${GREEN}  ✓ superpowers${NC}"
else
    echo -e "${RED}  ✗ superpowers (not found)${NC}"
fi

echo ""
echo -e "${BLUE}💡 To update skills later, run this script again${NC}"
echo ""
