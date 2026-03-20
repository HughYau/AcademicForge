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

# Parse arguments: support --help, --version, --tool <name>, and positional install dir
TOOL=""
INSTALL_DIR=""
while [[ $# -gt 0 ]]; do
    case "$1" in
        --help|-h)
            echo "Usage: bash install.sh [--tool claude|opencode] [install-dir]"
            echo ""
            echo "Installs Academic Forge into your project."
            echo ""
            echo "Options:"
            echo "  --tool <name>    Target tool: 'claude' or 'opencode'"
            echo "  --help, -h       Show this help message"
            echo "  --version, -V    Show forge version"
            echo ""
            echo "If no --tool or path is given, auto-detects .claude/ or .opencode/."
            exit 0
            ;;
        --version|-V)
            echo "Academic Forge installer"
            exit 0
            ;;
        --tool)
            TOOL="$2"
            shift 2
            ;;
        *)
            INSTALL_DIR="$1"
            shift
            ;;
    esac
done

# Determine install directory based on tool type
if [ -z "$INSTALL_DIR" ]; then
    if [ -n "$TOOL" ]; then
        case "$TOOL" in
            claude)  INSTALL_DIR=".claude/skills/academic-forge" ;;
            opencode) INSTALL_DIR=".opencode/skills/academic-forge" ;;
            *)
                echo -e "${RED}❌ Unknown tool: $TOOL${NC}"
                echo "Supported: claude, opencode"
                echo "Or provide a custom path directly as an argument."
                exit 1
                ;;
        esac
    else
        # Auto-detect: prefer .claude if it exists, otherwise .opencode
        if [ -d ".claude" ]; then
            INSTALL_DIR=".claude/skills/academic-forge"
        else
            INSTALL_DIR=".opencode/skills/academic-forge"
        fi
    fi
fi

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
if git clone --recursive https://github.com/HughYau/AcademicForge "$INSTALL_DIR"; then
    echo -e "${GREEN}✓ Successfully cloned Academic Forge${NC}"
else
    echo -e "${RED}❌ Failed to clone repository${NC}"
    exit 1
fi

# Initialize submodules if they weren't cloned recursively
echo -e "${BLUE}🔄 Ensuring all skills are initialized...${NC}"
cd "$INSTALL_DIR"
REPO_ROOT="$(pwd)"

if git submodule update --init --recursive; then
    echo -e "${GREEN}✓ All skills initialized${NC}"
else
    echo -e "${RED}❌ Failed to initialize submodules${NC}"
    exit 1
fi

# Load shared library functions (now that we're in the cloned repo)
source "scripts/lib.sh"

# Sync skills-only snapshots
sync_superpowers
sync_planning_with_files

# Post-sync processing: patch paths, apply blacklist, clean ads
post_sync_all "scripts/skill-blacklist.txt"

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
