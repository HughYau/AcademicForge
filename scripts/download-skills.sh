#!/bin/bash
# Academic Forge - Download Skills Script
# Bash version - Downloads skills submodules and syncs skills-only sources

set -e  # Exit on error

# Auto-detect repo root from script location
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
cd "$REPO_ROOT"

# Load shared library functions
source "$SCRIPT_DIR/lib.sh"

# Show help
if [[ "${1:-}" == "--help" || "${1:-}" == "-h" ]]; then
    echo "Usage: bash scripts/download-skills.sh"
    echo ""
    echo "Downloads and syncs all Academic Forge skills (submodules + skills-only snapshots)."
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
    echo "Please ensure the script is located inside the AcademicForge repository"
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
    "skills/paper-polish-workflow-skill"
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

# Sync skills-only snapshots
sync_superpowers
echo ""
sync_planning_with_files

echo ""

# Post-sync processing: patch paths, apply blacklist, clean ads
post_sync_all "scripts/skill-blacklist.txt"

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

if [ -d "skills/planning-with-files" ] && [ -n "$(ls -A "skills/planning-with-files" 2>/dev/null)" ]; then
    echo -e "${GREEN}  ✓ planning-with-files${NC}"
else
    echo -e "${RED}  ✗ planning-with-files (not found)${NC}"
fi

echo ""
echo -e "${BLUE}💡 To update skills later, run this script again${NC}"
echo ""
