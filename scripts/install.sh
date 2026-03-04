#!/bin/bash
# Academic Forge Installation Script
# Installs the forge and all included skills into your Claude Code project

set -e  # Exit on error

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Default installation directory
DEFAULT_DIR=".opencode/skills/academic-forge"
INSTALL_DIR="${1:-$DEFAULT_DIR}"

echo -e "${BLUE}╔═══════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║                                           ║${NC}"
echo -e "${BLUE}║        🎓 Academic Forge Installer        ║${NC}"
echo -e "${BLUE}║                                           ║${NC}"
echo -e "${BLUE}╚═══════════════════════════════════════════╝${NC}"
echo ""

# Check if git is installed
if ! command -v git &> /dev/null; then
    echo -e "${RED}❌ Error: git is not installed${NC}"
    echo "Please install git and try again."
    exit 1
fi

echo -e "${BLUE}📍 Installation directory:${NC} $INSTALL_DIR"
echo ""

# Check if directory already exists
if [ -d "$INSTALL_DIR" ]; then
    echo -e "${YELLOW}⚠️  Directory already exists: $INSTALL_DIR${NC}"
    read -p "Do you want to remove it and reinstall? (y/N): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        rm -rf "$INSTALL_DIR"
        echo -e "${GREEN}✓ Removed existing directory${NC}"
    else
        echo -e "${RED}Installation cancelled${NC}"
        exit 0
    fi
fi

# Create parent directory if it doesn't exist
mkdir -p "$(dirname "$INSTALL_DIR")"

echo -e "${BLUE}📦 Cloning Academic Forge...${NC}"
git clone --recursive https://github.com/HughYau/AcademicForge "$INSTALL_DIR"

if [ $? -eq 0 ]; then
    echo -e "${GREEN}✓ Successfully cloned Academic Forge${NC}"
else
    echo -e "${RED}❌ Failed to clone repository${NC}"
    exit 1
fi

# Initialize submodules if they weren't cloned recursively
echo -e "${BLUE}🔄 Ensuring all skills are initialized...${NC}"
cd "$INSTALL_DIR"
git submodule update --init --recursive

if [ $? -eq 0 ]; then
    echo -e "${GREEN}✓ All skills initialized${NC}"
else
    echo -e "${RED}❌ Failed to initialize submodules${NC}"
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
echo -e "${GREEN}╔═══════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║                                           ║${NC}"
echo -e "${GREEN}║     ✨ Installation Complete! ✨          ║${NC}"
echo -e "${GREEN}║                                           ║${NC}"
echo -e "${GREEN}╚═══════════════════════════════════════════╝${NC}"
echo ""

echo -e "${BLUE}📚 Included Skills:${NC}"
git submodule foreach --quiet 'echo "  ✓ $name"'
echo "  ✓ skills/superpowers"
echo "  ✓ skills/planning-with-files"

echo ""
echo -e "${BLUE}📖 Next Steps:${NC}"
echo "  1. Restart Claude Code to load the new skills"
echo "  2. Check forge.yaml for configuration options"
echo "  3. Run '$INSTALL_DIR/scripts/update.sh' to update skills later"
echo ""
echo -e "${BLUE}📄 Documentation:${NC}"
echo "  - README.md: Overview and usage guide"
echo "  - ATTRIBUTIONS.md: Skill credits and licenses"
echo "  - forge.yaml: Configuration options"
echo ""
echo -e "${GREEN}Happy writing! 🎓📝${NC}"
