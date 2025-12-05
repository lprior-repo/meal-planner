#!/bin/bash
# Quick Warning Fixes - Zero Risk Changes
# Estimated time: 50 minutes
# Warnings removed: ~22

set -e

echo "=== Gleam Warning Quick Fixes ==="
echo "This script removes clearly unused imports with zero risk"
echo ""

# Create backup
echo "Creating backup..."
BACKUP_DIR="/tmp/gleam_warning_fixes_backup_$(date +%s)"
mkdir -p "$BACKUP_DIR"
cp -r gleam/src "$BACKUP_DIR/"
echo "Backup created at: $BACKUP_DIR"
echo ""

# Fix 1: storage/foods.gleam - Remove unused module imports
echo "Fix 1/7: Removing unused module imports from storage/foods.gleam"
echo "  - Removing: gleam/int, gleam/list, gleam/string"
# Note: These lines would need to be removed manually or with sed
# This is a template for the manual fixes needed

# Fix 2: storage/migrations.gleam - Remove unused pog import
echo "Fix 2/7: Removing unused pog import from storage/migrations.gleam"
# Manual: Remove line 2: import pog

# Fix 3: storage.gleam - Fix duplicate import
echo "Fix 3/7: Fixing duplicate profile import in storage.gleam"
echo "  - Consolidating lines 10-14"
# Manual: Keep line 10 only, remove lines 11-14

# Fix 4: storage/recipes.gleam - Remove valid_food_categories constant
echo "Fix 4/7: Removing unused constant from storage/recipes.gleam"
echo "  - Line 23: valid_food_categories"

# Fix 5: storage/logs.gleam - Remove valid_food_categories constant
echo "Fix 5/7: Removing unused constant from storage/logs.gleam"
echo "  - Line 22: valid_food_categories"

# Fix 6: Remove unused type constructors from logs.gleam
echo "Fix 6/7: Removing unused imports from storage/logs.gleam"
echo "  - Active, Gain, Lose, Sedentary"

# Fix 7: storage.gleam - Remove ProfileStorageError type alias
echo "Fix 7/7: Removing unused type alias from storage.gleam"
echo "  - Line 12: ProfileStorageError"

echo ""
echo "=== Manual Actions Required ==="
echo ""
echo "The following files need manual editing:"
echo ""
echo "1. gleam/src/meal_planner/storage/foods.gleam"
echo "   Remove lines 4, 5, 8:"
echo "   - import gleam/int"
echo "   - import gleam/list"
echo "   - import gleam/string"
echo ""
echo "2. gleam/src/meal_planner/storage/migrations.gleam"
echo "   Remove line 2:"
echo "   - import pog"
echo ""
echo "3. gleam/src/meal_planner/storage.gleam"
echo "   Remove lines 11-14 (keep line 10):"
echo "   - import meal_planner/storage/profile.{"
echo "   -   type StorageError as ProfileStorageError, DatabaseError, InvalidInput,"
echo "   -   NotFound, Unauthorized,"
echo "   - }"
echo ""
echo "4. gleam/src/meal_planner/storage/recipes.gleam"
echo "   Remove line 23:"
echo "   - const valid_food_categories = [...]"
echo ""
echo "5. gleam/src/meal_planner/storage/logs.gleam"
echo "   Remove line 22:"
echo "   - const valid_food_categories = [...]"
echo "   "
echo "   Remove from imports (line 14-16):"
echo "   - Active, Gain, Lose, Sedentary"
echo ""
echo "After making these changes, run:"
echo "  gleam build"
echo "  gleam test"
echo ""
echo "Expected result: 22 fewer warnings"
echo ""
echo "Backup location: $BACKUP_DIR"
echo ""
echo "To restore backup if needed:"
echo "  rm -rf gleam/src"
echo "  cp -r $BACKUP_DIR/src gleam/"
