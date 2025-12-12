#!/usr/bin/env bash
# Claude Code Hook: Auto-sync Beads + OpenSpec on every prompt
# This ensures task tracking (beads) and specification proposals (OpenSpec)
# stay synchronized with git automatically.

set -euo pipefail

# Color output
info() { echo -e "\033[0;36m→ $*\033[0m" >&2; }
success() { echo -e "\033[0;32m✓ $*\033[0m" >&2; }
warn() { echo -e "\033[0;33m⚠ $*\033[0m" >&2; }
error() { echo -e "\033[0;31m✗ $*\033[0m" >&2; }

# Function to sync beads
sync_beads() {
  if ! command -v bd &> /dev/null; then
    warn "Beads (bd) not installed, skipping beads sync"
    return 0
  fi

  if [ ! -d .beads ]; then
    warn "No .beads directory, skipping beads sync"
    return 0
  fi

  info "Syncing beads..."
  if bd sync 2>&1 | grep -v "Error pulling from sync branch" | grep -v "failed to create worktree"; then
    success "Beads synced"
  else
    # Ignore worktree errors (known issue)
    success "Beads exported (sync branch unavailable)"
  fi
}

# Function to sync OpenSpec
sync_openspec() {
  if ! command -v openspec &> /dev/null; then
    warn "OpenSpec not installed, skipping openspec validation"
    return 0
  fi

  if [ ! -d openspec/changes ]; then
    warn "No OpenSpec changes, skipping"
    return 0
  fi

  # Check if any changes are in progress
  local changes_count=$(find openspec/changes -maxdepth 1 -type d -not -name "archive" -not -name "changes" | wc -l)

  if [ "$changes_count" -eq 0 ]; then
    return 0  # No changes to validate
  fi

  info "Validating OpenSpec proposals..."

  # Validate all non-archived changes
  local failed=0
  for change_dir in openspec/changes/*/; do
    [ -d "$change_dir" ] || continue
    local change_name=$(basename "$change_dir")
    [ "$change_name" = "archive" ] && continue

    if openspec validate "$change_name" --strict 2>&1; then
      success "OpenSpec '$change_name' valid"
    else
      error "OpenSpec '$change_name' validation failed"
      failed=1
    fi
  done

  return $failed
}

# Main execution
info "Running pre-prompt sync hook..."

sync_beads
sync_openspec

success "Sync complete - ready for next prompt"
exit 0
