#!/bin/bash
# Academic Forge - Download Skills Submodules Script
# Bash version - Only downloads skills folder submodules

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
echo -e "${BLUE}📥 Downloading skills submodules...${NC}"
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

echo ""
echo -e "${BLUE}💡 To update skills later, run this script again${NC}"
echo ""
