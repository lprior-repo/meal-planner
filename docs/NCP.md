# Nutritional Control Plane (NCP)

NCP integrates with Cronometer to track your nutrition and suggest recipe adjustments to meet your macro goals.

## Setup

### 1. Cronometer Credentials

Set environment variables:

```bash
export CRONOMETER_USERNAME="your-email@example.com"
export CRONOMETER_PASSWORD="your-password"
```

Or add to `.env`:

```
CRONOMETER_USERNAME=your-email@example.com
CRONOMETER_PASSWORD=your-password
```

### 2. Nutrition Goals (Optional)

Customize daily targets via environment variables:

```bash
export NCP_DAILY_PROTEIN=180   # grams
export NCP_DAILY_FAT=60        # grams
export NCP_DAILY_CARBS=250     # grams
export NCP_DAILY_CALORIES=2500
```

Defaults: 180g protein, 60g fat, 250g carbs, 2500 calories.

## CLI Commands

### Sync Data

Fetch nutrition data from Cronometer:

```bash
./meal-planner --ncp-sync
./meal-planner --ncp-sync --ncp-days 14  # Last 14 days
```

### Check Status

View current nutrition vs goals:

```bash
./meal-planner --ncp-status
```

Output shows:
- Average consumption vs goals
- Deviation percentages
- Whether you're within tolerance (25%)

### Run Reconciliation

Get recipe suggestions to correct deviations:

```bash
./meal-planner --ncp-reconcile
```

Output includes:
- Status report
- Top recipe recommendations
- Adjustment plan

## Automated Daily Reconciliation

A GitHub Actions workflow runs daily at 7:00 AM CST:

1. Syncs last 7 days from Cronometer
2. Calculates deviation from goals
3. Suggests recipe adjustments

### GitHub Secrets Required

- `CRONOMETER_USERNAME` - Your Cronometer email
- `CRONOMETER_PASSWORD` - Your Cronometer password

### GitHub Variables (Optional)

- `NCP_DAILY_PROTEIN` - Target protein (default: 180)
- `NCP_DAILY_FAT` - Target fat (default: 60)
- `NCP_DAILY_CARBS` - Target carbs (default: 250)
- `NCP_DAILY_CALORIES` - Target calories (default: 2500)

## How It Works

1. **Sync**: Fetches daily nutrition totals from Cronometer API
2. **Calculate**: Computes average consumption over N days
3. **Compare**: Calculates percentage deviation from goals
4. **Score**: Ranks recipes by how well they address deficits
5. **Suggest**: Returns top recipes with reasons

### Scoring Algorithm

Recipes are scored based on:
- **Protein priority** (50% weight) - Addresses protein deficits first
- **Fat balance** (25% weight) - Considers healthy fat needs
- **Carb balance** (25% weight) - Addresses carb deficits

Scores range from 0.0 to 1.0. Higher = better match for your current needs.

## Data Storage

NCP stores synced data in `./ncp_data/` using BadgerDB. This enables:
- Offline status checks
- Historical trend analysis
- Reduced API calls

## Tolerance

Default tolerance is 25%. If all macros are within +/- 25% of goals, you're "within tolerance" and no adjustments are suggested.
