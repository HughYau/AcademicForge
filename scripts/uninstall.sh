#!/bin/bash
# Academic Forge - Uninstall Script
# Removes the Academic Forge installation

set -e

# Auto-detect repo root
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Show help
if [[ "${1:-}" == "--help" || "${1:-}" == "-h" ]]; then
    echo "Usage: bash scripts/uninstall.sh"
    echo ""
    echo "Removes the Academic Forge installation directory."
    echo "This will delete all skills and configuration in: $REPO_ROOT"
    exit 0
fi

echo -e "${BLUE}🗑️  Academic Forge - Uninstall${NC}"
echo ""
echo -e "This will remove the entire Academic Forge installation at:"
echo -e "${YELLOW}  $REPO_ROOT${NC}"
echo ""

read -p "Are you sure you want to uninstall? (y/N): " -n 1 -r
echo

if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo -e "${RED}Uninstall cancelled${NC}"
    exit 0
fi

# Move out of the directory before deleting
cd /

rm -rf "$REPO_ROOT"

echo -e "${GREEN}✓ Academic Forge has been uninstalled${NC}"
echo -e "The directory ${YELLOW}$REPO_ROOT${NC} has been removed."
