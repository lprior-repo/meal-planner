# Meal Planner CLI Commands Reference

Complete reference of all available CLI commands, flags, and options.

## Table of Contents

1. [Command Structure](#command-structure)
2. [Global Flags](#global-flags)
3. [FatSecret Domain](#fatsecret-domain)
4. [Tandoor Domain](#tandoor-domain)
5. [Meal Planning Domain](#meal-planning-domain)
6. [Nutrition Domain](#nutrition-domain)
7. [Scheduler Domain](#scheduler-domain)
8. [Exit Codes](#exit-codes)

## Command Structure

```
gleam run -- [global-flags] [domain] [action] [options]
                            ^^^^^^^^ ^^^^^^   ^^^^^^^
                            Required Optional Required
```

### Parts

- **domain**: API/module to target (fatsecret, tandoor, meal-plan, nutrition, scheduler)
- **action**: Operation to perform (search, view, create, delete, update, etc.)
- **options**: Command-specific flags and arguments

## Global Flags

Available on all commands:

```bash
--help, -h          Show help for command
--version, -v       Show CLI version
--format FORMAT     Output format: json | table | csv (default: table)
--verbose           Enable verbose logging
--quiet             Suppress non-error output
--debug             Enable debug mode (detailed tracing)
--config PATH       Path to custom config file
```

### Global Flag Examples

```bash
# Show help for a command
gleam run -- fatsecret foods search --help

# Use JSON output format
gleam run -- fatsecret foods search --query "apple" --format json

# Enable debug logging
gleam run -- --debug fatsecret foods search --query "apple"

# Quiet mode (only show results, no status messages)
gleam run -- --quiet fatsecret diary summary --date today
```

## FatSecret Domain

FatSecret API operations for food, diary, exercise, and profile management.

### Foods

#### search

Search for foods by name or keyword.

```bash
gleam run -- fatsecret foods search [options]
```

**Options:**

```
--query, -q QUERY          Search query (required)
--limit N                  Results per page (default: 20, max: 100)
--offset N                 Pagination offset (default: 0)
--food-type TYPE           Filter by type: food | recipe | branded | generic (optional)
--nutrition               Include full nutrition data (default: false)
--sort-by FIELD           Sort by: relevance | calories | protein | name (default: relevance)
```

**Examples:**

```bash
# Basic search
gleam run -- fatsecret foods search --query "chicken"

# Search with full nutrition data
gleam run -- fatsecret foods search --query "banana" --nutrition

# Sort by calories
gleam run -- fatsecret foods search --query "fruit" --sort-by calories --limit 50

# Branded foods only
gleam run -- fatsecret foods search --query "yogurt" --food-type branded

# Paginate through results
gleam run -- fatsecret foods search --query "bread" --offset 20 --limit 20
```

#### detail

Get detailed information about a specific food.

```bash
gleam run -- fatsecret foods detail [options]
```

**Options:**

```
--id ID                    Food ID (required)
--include-servings         Include serving size options (default: true)
--include-recipes          Include recipes using this food (default: false)
--include-nutrition        Include detailed nutrition (default: true)
```

**Examples:**

```bash
# Get food details
gleam run -- fatsecret foods detail --id "12345"

# Include recipe suggestions
gleam run -- fatsecret foods detail --id "12345" --include-recipes

# Get as JSON
gleam run -- fatsecret foods detail --id "12345" --format json
```

#### brands

List food brands.

```bash
gleam run -- fatsecret foods brands [options]
```

**Options:**

```
--query, -q QUERY         Search brand names (optional)
--limit N                 Results per page (default: 20)
--offset N                Pagination offset (default: 0)
```

**Examples:**

```bash
# List all brands
gleam run -- fatsecret foods brands

# Search for specific brand
gleam run -- fatsecret foods brands --query "Dannon"

# Get paginated results
gleam run -- fatsecret foods brands --offset 20 --limit 50
```

### Diary

#### view

Display diary entries for a specific date.

```bash
gleam run -- fatsecret diary view [options]
```

**Options:**

```
--date DATE               Date (default: today, format: YYYY-MM-DD or 'today')
--include-totals          Include macro totals (default: true)
--meal-type TYPE          Filter by meal: breakfast | lunch | dinner | snack (optional)
```

**Examples:**

```bash
# View today's diary
gleam run -- fatsecret diary view

# View specific date
gleam run -- fatsecret diary view --date "2024-12-19"

# View breakfast only
gleam run -- fatsecret diary view --meal-type breakfast

# Get as JSON
gleam run -- fatsecret diary view --date today --format json
```

#### add

Add a food entry to the diary.

```bash
gleam run -- fatsecret diary add [options]
```

**Options:**

```
--food-id ID              Food ID (required)
--quantity N              Quantity in grams (required)
--date DATE               Date (default: today, format: YYYY-MM-DD)
--meal-type TYPE          Meal type: breakfast | lunch | dinner | snack (required)
--notes TEXT              Add notes to entry (optional)
```

**Examples:**

```bash
# Add food to today's diary
gleam run -- fatsecret diary add \
  --food-id "12345" \
  --quantity 150 \
  --meal-type breakfast

# Add to specific date
gleam run -- fatsecret diary add \
  --food-id "67890" \
  --quantity 200 \
  --date "2024-12-19" \
  --meal-type lunch \
  --notes "Grilled chicken with salad"

# Batch add from JSON
cat foods.json | jq -r '.[]' | xargs -I {} \
  gleam run -- fatsecret diary add \
    --food-id {} \
    --quantity 100 \
    --meal-type lunch
```

#### remove

Remove an entry from the diary.

```bash
gleam run -- fatsecret diary remove [options]
```

**Options:**

```
--entry-id ID             Entry ID (required)
--date DATE               Date of entry (optional, for confirmation)
--force                   Skip confirmation (default: false)
```

**Examples:**

```bash
# Remove an entry
gleam run -- fatsecret diary remove --entry-id "ENTRY_123"

# Remove without confirmation
gleam run -- fatsecret diary remove --entry-id "ENTRY_123" --force

# Remove with date confirmation
gleam run -- fatsecret diary remove --entry-id "ENTRY_123" --date "2024-12-19"
```

#### summary

Get daily nutrition summary.

```bash
gleam run -- fatsecret diary summary [options]
```

**Options:**

```
--date DATE               Date (default: today)
--include-goals           Include nutrition goals (default: true)
--include-variance        Include variance from goals (default: true)
--macro-breakdown         Show macronutrient breakdown (default: true)
```

**Examples:**

```bash
# Get today's summary
gleam run -- fatsecret diary summary

# Get specific date summary
gleam run -- fatsecret diary summary --date "2024-12-19"

# Get as JSON
gleam run -- fatsecret diary summary --date today --format json

# Get with goal variance
gleam run -- fatsecret diary summary --date today --include-variance
```

#### history

View diary history over a time period.

```bash
gleam run -- fatsecret diary history [options]
```

**Options:**

```
--days N                  Number of days (default: 7)
--start-date DATE         Start date (format: YYYY-MM-DD)
--end-date DATE           End date (format: YYYY-MM-DD)
--aggregate               Show daily averages (default: false)
--metric METRIC           Focus on metric: calories | protein | carbs | fat (optional)
```

**Examples:**

```bash
# Last 7 days
gleam run -- fatsecret diary history

# Last 30 days
gleam run -- fatsecret diary history --days 30

# Date range
gleam run -- fatsecret diary history --start-date "2024-12-01" --end-date "2024-12-19"

# Weekly averages
gleam run -- fatsecret diary history --days 7 --aggregate

# Track protein over 30 days
gleam run -- fatsecret diary history --days 30 --metric protein
```

### Exercise

#### log

Log an exercise activity.

```bash
gleam run -- fatsecret exercise log [options]
```

**Options:**

```
--activity NAME           Activity name (required)
--duration MINUTES        Duration in minutes (required)
--date DATE               Date (default: today)
--calories N              Calories burned (optional, calculated if omitted)
--intensity LEVEL         Intensity: light | moderate | vigorous (optional)
--notes TEXT              Activity notes (optional)
```

**Examples:**

```bash
# Log running
gleam run -- fatsecret exercise log \
  --activity "Running" \
  --duration 30

# Log with specific calories
gleam run -- fatsecret exercise log \
  --activity "Cycling" \
  --duration 45 \
  --calories 400

# Log with intensity
gleam run -- fatsecret exercise log \
  --activity "Swimming" \
  --duration 60 \
  --intensity vigorous \
  --notes "Freestyle laps"
```

#### history

View exercise history.

```bash
gleam run -- fatsecret exercise history [options]
```

**Options:**

```
--days N                  Number of days (default: 7)
--start-date DATE         Start date (format: YYYY-MM-DD)
--end-date DATE           End date (format: YYYY-MM-DD)
--activity-type TYPE      Filter by type (optional)
--aggregate               Show daily totals (default: false)
```

**Examples:**

```bash
# Last week's exercises
gleam run -- fatsecret exercise history

# Last 30 days
gleam run -- fatsecret exercise history --days 30

# Specific activity type
gleam run -- fatsecret exercise history --activity-type "Running"

# Daily totals
gleam run -- fatsecret exercise history --days 7 --aggregate --format json
```

#### detail

Get details about a logged exercise.

```bash
gleam run -- fatsecret exercise detail [options]
```

**Options:**

```
--id ID                   Exercise entry ID (required)
--include-related         Include related activities (default: false)
```

**Examples:**

```bash
# Get exercise details
gleam run -- fatsecret exercise detail --id "EXERCISE_123"

# Include related activities
gleam run -- fatsecret exercise detail --id "EXERCISE_123" --include-related
```

### Profile

#### view

View user profile information.

```bash
gleam run -- fatsecret profile view [options]
```

**Options:**

```
--include-goals           Include nutrition goals (default: true)
--include-preferences     Include dietary preferences (default: true)
--include-history         Include activity history (default: false)
```

**Examples:**

```bash
# View profile
gleam run -- fatsecret profile view

# Get as JSON
gleam run -- fatsecret profile view --format json

# Include full history
gleam run -- fatsecret profile view --include-history
```

#### update

Update profile settings.

```bash
gleam run -- fatsecret profile update [options]
```

**Options:**

```
--activity-level LEVEL    1.2 | 1.375 | 1.55 | 1.725 | 1.9 (required)
--goal GOAL               Goal: lose_weight | maintain | gain_weight (optional)
--goal-calories N         Target daily calories (optional)
--goal-protein N          Target daily protein (grams) (optional)
--goal-carbs N            Target daily carbs (grams) (optional)
--goal-fat N              Target daily fat (grams) (optional)
```

**Examples:**

```bash
# Update activity level
gleam run -- fatsecret profile update --activity-level 1.55

# Set all nutrition goals
gleam run -- fatsecret profile update \
  --activity-level 1.55 \
  --goal lose_weight \
  --goal-calories 2000 \
  --goal-protein 150 \
  --goal-carbs 200 \
  --goal-fat 65

# Update just one goal
gleam run -- fatsecret profile update --goal-protein 160
```

### Weight

#### log

Log a weight entry.

```bash
gleam run -- fatsecret weight log [options]
```

**Options:**

```
--value N                 Weight value (required)
--unit UNIT               Unit: kg | lbs (default: kg)
--date DATE               Date (default: today)
--notes TEXT              Notes (optional)
```

**Examples:**

```bash
# Log weight in kg
gleam run -- fatsecret weight log --value 75.5

# Log weight in pounds
gleam run -- fatsecret weight log --value 166 --unit lbs

# Log for specific date
gleam run -- fatsecret weight log --value 75.5 --date "2024-12-19"
```

#### history

View weight history.

```bash
gleam run -- fatsecret weight history [options]
```

**Options:**

```
--days N                  Number of days (default: 30)
--start-date DATE         Start date (format: YYYY-MM-DD)
--end-date DATE           End date (format: YYYY-MM-DD)
--unit UNIT               Display unit: kg | lbs (default: kg)
--include-trend           Include trend analysis (default: true)
```

**Examples:**

```bash
# Last 30 days
gleam run -- fatsecret weight history

# Last 90 days in pounds
gleam run -- fatsecret weight history --days 90 --unit lbs

# Date range with trend
gleam run -- fatsecret weight history \
  --start-date "2024-10-01" \
  --end-date "2024-12-19" \
  --include-trend

# As JSON for analysis
gleam run -- fatsecret weight history --days 30 --format json
```

### Favorites

#### list

List favorite foods.

```bash
gleam run -- fatsecret favorites list [options]
```

**Options:**

```
--limit N                 Results per page (default: 20)
--offset N                Pagination offset (default: 0)
--sort-by FIELD           Sort by: name | date_added | frequency (default: frequency)
```

**Examples:**

```bash
# List favorites
gleam run -- fatsecret favorites list

# Get as JSON
gleam run -- fatsecret favorites list --format json

# Most recently added
gleam run -- fatsecret favorites list --sort-by date_added --limit 50
```

#### add

Add a food to favorites.

```bash
gleam run -- fatsecret favorites add [options]
```

**Options:**

```
--food-id ID              Food ID (required)
--category NAME           Category name (optional)
```

**Examples:**

```bash
# Add to favorites
gleam run -- fatsecret favorites add --food-id "12345"

# Add with category
gleam run -- fatsecret favorites add --food-id "12345" --category "Proteins"
```

#### remove

Remove from favorites.

```bash
gleam run -- fatsecret favorites remove [options]
```

**Options:**

```
--food-id ID              Food ID (required)
--force                   Skip confirmation (default: false)
```

**Examples:**

```bash
# Remove from favorites
gleam run -- fatsecret favorites remove --food-id "12345"

# Force remove
gleam run -- fatsecret favorites remove --food-id "12345" --force
```

### Saved Meals

#### list

List saved meal combinations.

```bash
gleam run -- fatsecret saved-meals list [options]
```

**Options:**

```
--limit N                 Results per page (default: 20)
--offset N                Pagination offset (default: 0)
--sort-by FIELD           Sort by: name | date_created | frequency (default: frequency)
```

#### create

Save a custom meal combination.

```bash
gleam run -- fatsecret saved-meals create [options]
```

**Options:**

```
--name NAME               Meal name (required)
--foods FOOD_IDS          Comma-separated food IDs (required)
--quantities QTYS         Comma-separated quantities (required)
--servings N              Servings (default: 1)
```

**Examples:**

```bash
# Create saved meal
gleam run -- fatsecret saved-meals create \
  --name "Breakfast Bowl" \
  --foods "123,456,789" \
  --quantities "100,150,50"
```

#### delete

Delete a saved meal.

```bash
gleam run -- fatsecret saved-meals delete [options]
```

**Options:**

```
--meal-id ID              Meal ID (required)
--force                   Skip confirmation (default: false)
```

## Tandoor Domain

Recipe management operations via Tandoor integration.

### recipes

#### search

Search Tandoor recipes.

```bash
gleam run -- tandoor recipes search [options]
```

**Options:**

```
--query, -q QUERY         Search query (required)
--limit N                 Results per page (default: 20)
--offset N                Pagination offset (default: 0)
--tags TAGS               Filter by tags (comma-separated) (optional)
--author AUTHOR           Filter by author (optional)
--sort-by FIELD           Sort by: name | rating | date (default: relevance)
```

**Examples:**

```bash
# Search recipes
gleam run -- tandoor recipes search --query "pasta"

# Filter by tags
gleam run -- tandoor recipes search --query "chicken" --tags "quick,healthy"

# Sort by rating
gleam run -- tandoor recipes search --query "dinner" --sort-by rating --limit 50
```

#### detail

Get recipe details.

```bash
gleam run -- tandoor recipes detail [options]
```

**Options:**

```
--id ID                   Recipe ID (required)
--include-instructions    Include step-by-step instructions (default: true)
--include-nutrition       Include nutrition data (default: true)
--include-comments        Include user comments (default: false)
```

**Examples:**

```bash
# Get recipe details
gleam run -- tandoor recipes detail --id "RECIPE_123"

# Get as JSON with full data
gleam run -- tandoor recipes detail --id "RECIPE_123" --format json
```

#### list

List user's recipes.

```bash
gleam run -- tandoor recipes list [options]
```

**Options:**

```
--limit N                 Results per page (default: 20)
--offset N                Pagination offset (default: 0)
--created-by USER         Filter by creator (optional)
--sort-by FIELD           Sort by: name | date | rating (default: date)
```

#### create

Create a new recipe.

```bash
gleam run -- tandoor recipes create [options]
```

**Options:**

```
--name NAME               Recipe name (required)
--servings N              Servings (required)
--prep-time MINUTES       Prep time (optional)
--cook-time MINUTES       Cook time (optional)
--instructions TEXT       Instructions (optional)
--ingredients JSON        Ingredients as JSON (optional)
```

## Meal Planning Domain

### meal-plan

#### generate

Generate a weekly meal plan.

```bash
gleam run -- meal-plan generate [options]
```

**Options:**

```
--start-date DATE         Plan start date (required, format: YYYY-MM-DD)
--days N                  Number of days (default: 7)
--users N                 Number of users (default: 1)
--dietary-preference PREF Preference: balanced | high-protein | low-carb | vegetarian (optional)
--budget-tier TIER        Budget: economy | standard | premium (optional)
--constraints JSON        Dietary constraints as JSON (optional)
```

**Examples:**

```bash
# Generate basic plan
gleam run -- meal-plan generate --start-date "2024-12-22"

# High-protein plan for 2 users
gleam run -- meal-plan generate \
  --start-date "2024-12-22" \
  --users 2 \
  --dietary-preference high-protein

# With budget constraints
gleam run -- meal-plan generate \
  --start-date "2024-12-22" \
  --budget-tier economy
```

#### view

View an existing meal plan.

```bash
gleam run -- meal-plan view [options]
```

**Options:**

```
--id ID                   Plan ID (required)
--include-recipes         Include full recipe details (default: false)
--include-shopping        Include shopping list (default: true)
--include-nutrition       Include nutrition analysis (default: true)
```

**Examples:**

```bash
# View plan
gleam run -- meal-plan view --id "PLAN_123"

# Get JSON format
gleam run -- meal-plan view --id "PLAN_123" --format json
```

#### grocery

Generate grocery list from plan.

```bash
gleam run -- meal-plan grocery [options]
```

**Options:**

```
--plan-id ID              Plan ID (required)
--unit-preference UNIT    Unit: metric | imperial (default: metric)
--group-by FIELD          Group by: category | recipe | none (default: category)
--include-prices          Include estimated prices (default: false)
```

**Examples:**

```bash
# Generate grocery list
gleam run -- meal-plan grocery --plan-id "PLAN_123"

# As JSON
gleam run -- meal-plan grocery --plan-id "PLAN_123" --format json

# Grouped by recipe
gleam run -- meal-plan grocery \
  --plan-id "PLAN_123" \
  --group-by recipe \
  --unit-preference imperial
```

#### update

Update an existing meal plan.

```bash
gleam run -- meal-plan update [options]
```

**Options:**

```
--plan-id ID              Plan ID (required)
--day N                   Day to update (1-7) (optional)
--meal MEAL               Meal to replace (breakfast|lunch|dinner) (optional)
--recipe-id ID            New recipe ID (optional)
--notes TEXT              Plan notes (optional)
```

#### delete

Delete a meal plan.

```bash
gleam run -- meal-plan delete [options]
```

**Options:**

```
--plan-id ID              Plan ID (required)
--force                   Skip confirmation (default: false)
```

## Nutrition Domain

### nutrition

#### analyze

Analyze nutrition of a food or meal.

```bash
gleam run -- nutrition analyze [options]
```

**Options:**

```
--food-id ID              Single food ID (optional)
--meal-id ID              Saved meal ID (optional)
--recipe-id ID            Recipe ID (optional)
--include-micros          Include micronutrients (default: false)
--include-allergens       Include allergen info (default: true)
```

**Examples:**

```bash
# Analyze single food
gleam run -- nutrition analyze --food-id "12345"

# Analyze meal with micronutrients
gleam run -- nutrition analyze --meal-id "MEAL_456" --include-micros
```

#### daily-recommendations

Get daily nutrition recommendations.

```bash
gleam run -- nutrition daily-recommendations [options]
```

**Options:**

```
--age N                   Age (optional)
--gender GENDER           Gender: male | female (optional)
--activity-level LEVEL    Activity level (optional)
--goal GOAL               Goal: lose | maintain | gain (optional)
```

#### weekly-trends

View weekly nutrition trends.

```bash
gleam run -- nutrition weekly-trends [options]
```

**Options:**

```
--weeks N                 Number of weeks (default: 4)
--metric METRIC           Metric: calories | protein | carbs | fat (optional)
--compare-goals           Compare vs goals (default: true)
```

## Scheduler Domain

### scheduler

#### list

List scheduled tasks.

```bash
gleam run -- scheduler list [options]
```

**Options:**

```
--status STATUS           Status: pending | running | completed | failed (optional)
--limit N                 Results per page (default: 20)
```

#### view

View details of a scheduled task.

```bash
gleam run -- scheduler view [options]
```

**Options:**

```
--task-id ID              Task ID (required)
--include-logs            Include execution logs (default: false)
```

#### schedule

Create a scheduled task.

```bash
gleam run -- scheduler schedule [options]
```

**Options:**

```
--action ACTION           Action to schedule (required)
--cron EXPRESSION         Cron expression (required)
--name NAME               Task name (optional)
--description TEXT        Task description (optional)
```

**Examples:**

```bash
# Daily meal plan generation
gleam run -- scheduler schedule \
  --action "generate_meal_plan" \
  --cron "0 9 * * 0" \
  --name "Weekly Meal Plan" \
  --description "Generate meal plan every Sunday at 9 AM"
```

## Exit Codes

| Code | Meaning |
|------|---------|
| 0 | Success |
| 1 | General error |
| 2 | Command not found |
| 3 | Invalid arguments |
| 4 | Missing required option |
| 5 | Configuration error |
| 6 | Database connection error |
| 7 | API error |
| 8 | Authentication error |
| 9 | Authorization error (permission denied) |
| 10 | Timeout |

## Tips

- Use `--help` on any command for detailed usage information
- Use `--format json` for scripting and automation
- Use `--quiet` flag to suppress status messages in scripts
- Combine `--verbose` and `--debug` flags for troubleshooting
- Most commands that modify data (`create`, `delete`, `update`) require confirmation unless `--force` is specified
