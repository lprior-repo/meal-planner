#!/bin/bash
# Git hooks installer
#
# This script copies git hooks from .githooks/ to .git/hooks/
# and makes them executable.
#
# Usage:
#   ./.githooks/install.sh
#   # or
#   bash .githooks/install.sh

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
GIT_HOOKS_DIR="$PROJECT_ROOT/.git/hooks"

# Ensure .git/hooks directory exists
mkdir -p "$GIT_HOOKS_DIR"

echo "Installing git hooks..."
echo ""

# List of hooks to install
HOOKS=(
    "pre-commit"
    "post-commit"
    "prepare-commit-msg"
    "pre-push"
)

for hook in "${HOOKS[@]}"; do
    SRC="$SCRIPT_DIR/$hook"
    DST="$GIT_HOOKS_DIR/$hook"
    
    if [ -f "$SRC" ]; then
        echo "  Installing $hook..."
        cp "$SRC" "$DST"
        chmod +x "$DST"
        echo "    ✓ $hook installed"
    else
        echo "  ⚠ $hook not found in .githooks/, skipping"
    fi
done

echo ""
echo "✅ Git hooks installed successfully!"
echo ""
echo "Hooks are now active. They will run on:"
echo "  • pre-commit:       Before each commit (can be bypassed with --no-verify)"
echo "  • post-commit:      After each commit (always runs)"
echo "  • prepare-commit-msg: When preparing commit message (helper)"
echo "  • pre-push:         Before pushing (ENFORCED)"
echo ""
echo "To verify hooks are working:"
echo "  git commit --allow-empty -m \"Test hook\""
echo ""
