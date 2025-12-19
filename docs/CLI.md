# Meal Planner CLI Documentation

## Overview

The Meal Planner CLI provides two complementary interfaces for interacting with the meal planning system:

1. **Interactive TUI Mode** (Glint + Shore): Full-featured terminal user interface with navigation, menus, and real-time feedback
2. **Command-line Mode** (Glint): Direct command execution for scripting and automation

Both modes are powered by the Glint command parser and the Shore TUI framework, following the Elm Architecture (Model-Update-View pattern).

## Requirements

- **Erlang/OTP**: 28 or later
- **Gleam**: 1.4.0 or later
- **PostgreSQL**: 14 or later (for data persistence)
- **Terminal**: Modern terminal emulator with ANSI color support

## Installation

### Option 1: Build from Source

```bash
# Clone the repository
git clone https://github.com/lprior-repo/meal-planner
cd meal-planner

# Install dependencies
gleam deps download

# Build the project
gleam build

# The CLI is available as part of the main application
gleam run
```

### Option 2: Using Make

```bash
cd meal-planner

# Run the server (includes CLI availability)
make run

# Or build first, then run
make build
make run
```

## Configuration

The CLI reads configuration from environment variables and `.env` files:

### Environment Variables

```bash
# Database Configuration
DATABASE_HOST=localhost          # PostgreSQL host (default: localhost)
DATABASE_PORT=5432              # PostgreSQL port (default: 5432)
DATABASE_NAME=meal_planner       # Database name
DATABASE_USER=postgres           # Database user
DATABASE_PASSWORD=password       # Database password

# Server Configuration
SERVER_PORT=3000                 # HTTP server port
SERVER_ENV=development           # Environment: development|production|test

# API Integration
TANDOOR_BASE_URL=http://localhost:8000  # Recipe management service
FATSECRET_CONSUMER_KEY=xxxxx     # FatSecret API credentials
FATSECRET_CONSUMER_SECRET=xxxxx
```

### .env File Setup

Create a `.env` file in the project root:

```bash
# Copy the example
cp .env.example .env

# Edit with your configuration
nano .env

# Load configuration on startup (automatic with dot_env library)
```

**Note**: The `.env` file is automatically loaded on application startup through the `dot_env` library.

## Usage

### Interactive TUI Mode

The interactive mode provides a full menu-driven interface:

```bash
# Start interactive TUI
gleam run

# This launches the Shore application with the main menu
```

#### Navigation

- **Arrow Keys**: Navigate menu options
- **Enter**: Select option
- **Escape/q**: Go back or quit
- **Ctrl+C**: Force exit

#### Main Menu Options

```
Main Menu
=========
1. FatSecret Domain
   - Food Search
   - Diary View
   - Exercise View
   - Favorites View
   - Saved Meals
   - Profile
   - Weight Tracking

2. Tandoor Domain
   - Recipe Management
   - Recipe Search

3. Database Domain
   - Search USDA Foods
   - Browse Categories
   - Nutrition Analysis

4. Meal Planning Domain
   - Generate Weekly Plans
   - View Existing Plans
   - Grocery List Generation

5. Nutrition Domain
   - Daily Recommendations
   - Weekly Trends
   - Macro Analysis

6. Scheduler Domain
   - View Scheduled Tasks
   - Schedule New Tasks
```

### Command-Line Mode

Direct command execution for scripts and automation:

```bash
# Search foods via FatSecret
gleam run -- fatsecret foods search --query "chicken breast"

# Get food details
gleam run -- fatsecret foods detail --id "12345"

# Show FatSecret help
gleam run -- fatsecret help

# Show general help
gleam run -- --help
```

#### Command Structure

```
meal-planner [domain] [action] [options]
             ^^^^^^   ^^^^^^   ^^^^^^^
             |        |        Optional flags
             |        Action to perform
             Domain/API to use
```

## Commands Reference

See [COMMANDS.md](COMMANDS.md) for a comprehensive reference of all available commands and flags.

### FatSecret Domain

#### Food Operations

```bash
# Search for foods
gleam run -- fatsecret foods search --query "apple"

# Get food details
gleam run -- fatsecret foods detail --id "FOOD_ID"

# List food brands
gleam run -- fatsecret foods brands --query "yogurt"

# Get recipes containing ingredient
gleam run -- fatsecret recipes search --ingredient "eggs"
```

#### Diary Management

```bash
# View daily food log
gleam run -- fatsecret diary view --date "2024-12-19"

# Add food to diary
gleam run -- fatsecret diary add --food-id "ID" --quantity 100 --date "2024-12-19"

# Remove food from diary
gleam run -- fatsecret diary remove --entry-id "ENTRY_ID"

# List daily summary
gleam run -- fatsecret diary summary --date "2024-12-19"
```

#### Exercise Tracking

```bash
# Log exercise
gleam run -- fatsecret exercise log --name "Running" --duration 30 --calories 300

# View exercise history
gleam run -- fatsecret exercise history --days 7

# Get exercise details
gleam run -- fatsecret exercise detail --id "EXERCISE_ID"
```

#### Profile & Weight

```bash
# View user profile
gleam run -- fatsecret profile view

# Update profile
gleam run -- fatsecret profile update --activity-level 1.5

# Log weight
gleam run -- fatsecret weight log --value 75.5 --date "2024-12-19"

# View weight history
gleam run -- fatsecret weight history --days 30
```

### Tandoor Domain

```bash
# Search Tandoor recipes
gleam run -- tandoor recipes search --query "pasta"

# Get recipe details
gleam run -- tandoor recipes detail --id "RECIPE_ID"

# Create new recipe
gleam run -- tandoor recipes create --name "My Recipe" --servings 4

# List user recipes
gleam run -- tandoor recipes list --limit 20
```

### Meal Planning Domain

```bash
# Generate weekly meal plan
gleam run -- meal-plan generate --users 1 --start-date "2024-12-16"

# View existing plan
gleam run -- meal-plan view --id "PLAN_ID"

# Generate grocery list
gleam run -- meal-plan grocery --plan-id "PLAN_ID" --format json

# Get plan recommendations
gleam run -- meal-plan recommendations --user-id "USER_ID"
```

## Output Formats

The CLI supports multiple output formats:

### Table Format (Default)

Human-readable table output for terminal display:

```
Food Results
============
ID     | Name                | Calories | Protein
-------|---------------------|----------|--------
12345  | Chicken Breast      | 165      | 31g
12346  | Chicken Thigh       | 209      | 26g
12347  | Chicken Wing        | 203      | 30g
```

### JSON Format

Machine-readable JSON for scripting and integration:

```bash
gleam run -- fatsecret foods search --query "apple" --format json
```

```json
{
  "data": [
    {
      "id": "12345",
      "name": "Apple, with skin",
      "calories": 52,
      "protein": 0.3,
      "carbs": 13.8,
      "fat": 0.2
    }
  ],
  "pagination": {
    "offset": 0,
    "limit": 20,
    "total": 450
  }
}
```

## Examples

### Example 1: Search and Log Food

```bash
# Search for a food
gleam run -- fatsecret foods search --query "Greek yogurt"

# Add it to your diary
gleam run -- fatsecret diary add --food-id "12345" --quantity 150 --date today

# View your daily summary
gleam run -- fatsecret diary summary --date today
```

### Example 2: Generate Weekly Meal Plan

```bash
# Generate a plan for the upcoming week
gleam run -- meal-plan generate \
  --start-date "2024-12-22" \
  --users 2 \
  --dietary-preference "balanced"

# View the generated plan
gleam run -- meal-plan view --id "PLAN_ID"

# Generate grocery list from the plan
gleam run -- meal-plan grocery --plan-id "PLAN_ID" --format json > grocery.json
```

### Example 3: Batch Food Import

```bash
# Script to import foods from a list
#!/bin/bash

while IFS= read -r food_name; do
  gleam run -- fatsecret foods search --query "$food_name" --format json
done < foods.txt
```

## Troubleshooting

### Connection Issues

**Problem**: `Database connection failed`

```bash
# Check PostgreSQL is running
psql -h localhost -U postgres -c "SELECT 1"

# Verify environment variables
echo $DATABASE_HOST
echo $DATABASE_NAME

# Test connection string
psql -h $DATABASE_HOST -U $DATABASE_USER -d $DATABASE_NAME -c "SELECT 1"
```

### Missing Configuration

**Problem**: `Missing required environment variable: DATABASE_USER`

```bash
# Check current configuration
env | grep DATABASE

# Load .env file
source .env

# Verify Gleam loads it
gleam run
```

### API Authentication

**Problem**: `FatSecret API authentication failed`

```bash
# Verify credentials are set
echo $FATSECRET_CONSUMER_KEY
echo $FATSECRET_CONSUMER_SECRET

# Check for spaces or special characters that need escaping
# Update .env file with correct values
```

### Terminal Rendering Issues

**Problem**: TUI display is garbled

```bash
# Try with a modern terminal
export TERM=xterm-256color

# Or use a specific terminal emulator
alacritty -e gleam run

# Check terminal size (should be >= 80x24)
stty size
```

## Advanced Usage

### Automation & Scripting

Using the CLI with shell scripts:

```bash
#!/bin/bash
# daily_checkin.sh - Log daily nutrition

FOOD_IDS=("12345" "67890" "11111")
QUANTITIES=(150 100 200)

for i in "${!FOOD_IDS[@]}"; do
  gleam run -- fatsecret diary add \
    --food-id "${FOOD_IDS[$i]}" \
    --quantity "${QUANTITIES[$i]}" \
    --date "$(date +%Y-%m-%d)"
done

# View summary
gleam run -- fatsecret diary summary --date "$(date +%Y-%m-%d)" --format json
```

### Integration with External Tools

Using JSON output for integration:

```bash
# Export daily nutrition data for analysis
gleam run -- fatsecret diary summary --date today --format json | \
  jq '.data | {date, calories: .totals.calories, protein: .totals.protein}'

# Feed into other tools
gleam run -- meal-plan generate --format json | \
  curl -X POST https://api.example.com/plans -d @-
```

### Pagination

Handling large result sets:

```bash
# Get first 20 results
gleam run -- fatsecret foods search --query "apple" --limit 20

# Get next 20 results
gleam run -- fatsecret foods search --query "apple" --limit 20 --offset 20

# Get all results with loop
for i in {0..100..20}; do
  gleam run -- fatsecret foods search \
    --query "apple" \
    --offset $i \
    --limit 20
done
```

## Performance Tips

1. **Use JSON format for large result sets**: Faster parsing and processing
2. **Limit queries**: Always use `--limit` for large datasets
3. **Cache results**: Store JSON responses locally to avoid repeated API calls
4. **Batch operations**: Group multiple commands together when possible
5. **Use appropriate offsets**: For pagination, calculate offsets to skip already-processed items

## Environment-Specific Behavior

### Development Mode

```bash
export SERVER_ENV=development
gleam run

# Features:
# - More verbose logging
# - Detailed error messages
# - No request throttling
# - Dev-friendly defaults
```

### Production Mode

```bash
export SERVER_ENV=production
gleam run

# Features:
# - Minimal logging (errors only)
# - User-friendly error messages
# - Rate limiting enabled
# - Stricter validation
```

## See Also

- [COMMANDS.md](COMMANDS.md) - Complete command reference
- [CLI-ARCHITECTURE.md](CLI-ARCHITECTURE.md) - Architecture and extensibility
- [DEVELOPMENT.md](DEVELOPMENT.md) - Development guide for contributors
- [README.md](../README.md) - Main project documentation
