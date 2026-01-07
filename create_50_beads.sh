#!/bin/bash

# Script to create 50 beads via direct JSON appending to issues.jsonl
# Usage: ./create_50_beads.sh

set -e

BEADS_FILE="/home/user/meal-planner/.beads/issues.jsonl"
TOTAL_BEADS=50

echo "Starting batch creation of $TOTAL_BEADS beads..."
echo "Target file: $BEADS_FILE"
echo ""

# Predefined titles for beads
declare -a TITLES=(
  "Implement batch processing for meal-planning automation"
  "Add error handling for recipe-aggregation workflow"
  "Create test suite for grocery-list module"
  "Optimize nutrition-tracking performance metrics"
  "Document meal-scheduling API and integration"
  "Set up monitoring for ingredient-matching pipeline"
  "Implement caching for tandoor-sync operations"
  "Add retry logic to fatsecret-integration batch processor"
  "Create dashboard for api-federation metrics"
  "Implement rollback strategy for data-validation"
  "Add logging to batch-update workflow"
  "Migrate cache-warming to async processing"
  "Create unit tests for report-generation edge cases"
  "Set up CI/CD pipeline for workflow-orchestration"
  "Add validation for dependency-resolution inputs"
  "Implement rate limiting for health-check operations"
  "Create backup system for api-federation data"
  "Add alerting for batch-update failures"
  "Implement meal-planning batch consolidation"
  "Create performance benchmarks for recipe-aggregation"
)

for i in $(seq 1 $TOTAL_BEADS); do
  # Select title - cycle through array
  TITLE_INDEX=$(( (i - 1) % ${#TITLES[@]} ))
  TITLE="${TITLES[$TITLE_INDEX]}"

  # Generate unique 3-char ID suffix
  ID_SUFFIX=$(printf '%03d' $i | tr '0-9' 'a-j')

  # Simple unique ID
  BEAD_ID="meal-planner-batch-$i"

  # Priority 0-3
  PRIORITY=$(( (i - 1) % 4 ))

  # Issue type rotation
  ISSUE_TYPE=$(( (i - 1) % 4 ))
  case $ISSUE_TYPE in
    0) ISSUE_TYPE="task" ;;
    1) ISSUE_TYPE="bug" ;;
    2) ISSUE_TYPE="feature" ;;
    3) ISSUE_TYPE="chore" ;;
  esac

  # Current timestamp
  NOW=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

  # Generate compact JSON line
  cat >> "$BEADS_FILE" <<EOF
{"id":"$BEAD_ID","title":"$TITLE","description":"Automated batch creation - Bead $i of $TOTAL_BEADS","status":"open","priority":$PRIORITY,"issue_type":"$ISSUE_TYPE","created_at":"$NOW","updated_at":"$NOW","labels":["batch-creation","automation"]}
EOF

  # Progress indicator every 5 beads
  if [ $((i % 5)) -eq 0 ] || [ $i -eq 1 ]; then
    echo "[$i/$TOTAL_BEADS] Created: $BEAD_ID"
  fi
done

echo ""
echo "✓ Successfully created $TOTAL_BEADS beads!"
echo ""
wc -l "$BEADS_FILE"
tail -1 "$BEADS_FILE" | jq -c '.id, .title' 2>/dev/null || echo "Last bead created successfully"
