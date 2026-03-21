#!/bin/bash
# Academic Forge - Installation Verification Script
# Checks that all skills are properly installed and configured

set -e

# Auto-detect repo root
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
cd "$REPO_ROOT"

# Show help
if [[ "${1:-}" == "--help" || "${1:-}" == "-h" ]]; then
    echo "Usage: bash scripts/verify.sh"
    echo ""
    echo "Verifies that Academic Forge is correctly installed by checking:"
    echo "  - forge.yaml exists"
    echo "  - All skill directories are present and non-empty"
    echo "  - Git submodules are initialized"
    exit 0
fi

# Show version
if [[ "${1:-}" == "--version" || "${1:-}" == "-V" ]]; then
    version=$(grep -m1 'version:' forge.yaml 2>/dev/null | sed 's/.*"\(.*\)".*/\1/' || echo "unknown")
    echo "Academic Forge v${version}"
    exit 0
fi

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}🔍 Academic Forge - Installation Verification${NC}"
echo ""

passed=0
failed=0
warnings=0

check_pass() {
    echo -e "${GREEN}  ✓ $1${NC}"
    passed=$((passed + 1))
}

check_fail() {
    echo -e "${RED}  ✗ $1${NC}"
    failed=$((failed + 1))
}

check_warn() {
    echo -e "${YELLOW}  ⚠ $1${NC}"
    warnings=$((warnings + 1))
}

# 1. Check forge.yaml
echo -e "${BLUE}Checking forge configuration...${NC}"
if [ -f "forge.yaml" ]; then
    check_pass "forge.yaml found"
else
    check_fail "forge.yaml not found"
fi

# 2. Check skill directories
echo -e "${BLUE}Checking skill directories...${NC}"

SKILLS=(
    "skills/claude-scientific-skills"
    "skills/AI-research-SKILLs"
    "skills/humanizer"
    "skills/superpowers"
    "skills/planning-with-files"
    "skills/paper-polish-workflow-skill"
    "skills/scientific-visualization"
)

for skill_dir in "${SKILLS[@]}"; do
    skill_name=$(basename "$skill_dir")
    if [ -d "$skill_dir" ] && [ -n "$(ls -A "$skill_dir" 2>/dev/null)" ]; then
        check_pass "$skill_name"
    elif [ -d "$skill_dir" ]; then
        check_warn "$skill_name (directory exists but is empty - run download-skills.sh)"
    else
        check_fail "$skill_name (not found)"
    fi
done

# 3. Check submodule status
echo -e "${BLUE}Checking git submodules...${NC}"
if [ -d ".git" ] || [ -f ".git" ]; then
    submodule_status=$(git submodule status 2>/dev/null || true)
    if [ -n "$submodule_status" ]; then
        while IFS= read -r line; do
            if echo "$line" | grep -q '^-'; then
                name=$(echo "$line" | awk '{print $2}')
                check_warn "$name (not initialized - run: git submodule update --init)"
            elif echo "$line" | grep -q '^+'; then
                name=$(echo "$line" | awk '{print $2}')
                check_warn "$name (has local changes)"
            else
                name=$(echo "$line" | awk '{print $2}')
                check_pass "$name (initialized)"
            fi
        done <<< "$submodule_status"
    fi
else
    check_warn "Not a git repository (submodule checks skipped)"
fi

# 4. Check shared library
echo -e "${BLUE}Checking scripts...${NC}"
if [ -f "scripts/lib.sh" ]; then
    check_pass "scripts/lib.sh found"
else
    check_fail "scripts/lib.sh not found"
fi

# Summary
echo ""
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "  ${GREEN}Passed: $passed${NC}  ${RED}Failed: $failed${NC}  ${YELLOW}Warnings: $warnings${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

if [ $failed -eq 0 ]; then
    echo -e "${GREEN}✨ Academic Forge is correctly installed!${NC}"
    exit 0
else
    echo -e "${RED}Some checks failed. Run 'bash scripts/download-skills.sh' to fix.${NC}"
    exit 1
fi
