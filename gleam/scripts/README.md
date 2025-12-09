# USDA FoodData Central Import Scripts

This directory contains scripts to download and import the USDA FoodData Central database into PostgreSQL.

## Overview

The USDA FoodData Central database contains:
- **~300,000 food items** from various sources (Foundation Foods, SR Legacy, Survey Foods, etc.)
- **~150 nutrients** (vitamins, minerals, macronutrients, etc.)
- **~4,500,000 nutrient values** (relationships between foods and their nutrient content)

## Prerequisites

### System Requirements
- **Disk Space**: At least 5GB free space
- **RAM**: 2GB minimum, 4GB recommended
- **Network**: Stable internet connection for ~2GB download

### Software Requirements
- PostgreSQL 12+ (with psql client)
- wget or curl
- unzip
- Bash 4.0+

### Database Setup
Ensure the database schema is initialized:
```bash
cd /home/lewis/src/meal-planner/gleam
gleam run -m meal_planner/storage/migrations
```

This creates the required tables:
- `nutrients` - Nutrient definitions
- `foods` - Food items
- `food_nutrients` - Nutrient values for each food
- `food_nutrients_staging` - Temporary table for bulk loading

## Quick Start

### Option 1: Full Setup (Recommended)
Download and import in one command:

```bash
cd /home/lewis/src/meal-planner/gleam/scripts
./setup-usda-database.sh
```

You will be prompted for the database password if `DB_PASSWORD` is not set.

### Option 2: Step-by-Step
Run download and import separately:

```bash
# Step 1: Download data
./download-usda-data.sh

# Step 2: Import to database
./import-usda-data.sh
```

## Scripts

### `setup-usda-database.sh` (Main Orchestrator)
The primary entry point that coordinates the entire process.

**Usage:**
```bash
./setup-usda-database.sh [OPTIONS]

Options:
  --download-only    Only download data, skip import
  --import-only      Only import data, skip download
  --help             Show help message
```

**Environment Variables:**
```bash
DB_HOST=localhost       # PostgreSQL host (default: localhost)
DB_PORT=5432           # PostgreSQL port (default: 5432)
DB_NAME=meal_planner   # Database name (default: meal_planner)
DB_USER=postgres       # Database user (default: postgres)
DB_PASSWORD=secret     # Database password (will prompt if not set)
```

**Example:**
```bash
# With environment variables
export DB_HOST=localhost
export DB_PASSWORD=mypassword
./setup-usda-database.sh

# Or inline
DB_HOST=localhost DB_PASSWORD=mypass ./setup-usda-database.sh
```

**What it does:**
1. Validates environment and prerequisites
2. Checks available disk space (>5GB required)
3. Downloads USDA data (~2GB ZIP file)
4. Extracts CSV files
5. Imports data to PostgreSQL
6. Verifies import success
7. Tests search functionality

### `download-usda-data.sh`
Downloads and extracts USDA FoodData Central CSV data.

**Source:** https://fdc.nal.usda.gov/fdc-datasets/FoodData_Central_csv_2024-10-31.zip

**Output:**
- Downloads ZIP to: `../data/usda/raw/FoodData_Central.zip`
- Extracts CSVs to: `../data/usda/extracted/`

**Required Files:**
- `food.csv` - Food items (~300k records)
- `nutrient.csv` - Nutrient definitions (~150 records)
- `food_nutrient.csv` - Nutrient values (~4.5M records)

**Note:** If the ZIP file already exists, download will be skipped. Delete it to re-download.

### `import-usda-data.sh`
Imports CSV data into PostgreSQL with optimizations.

**What it does:**
1. Validates CSV files exist
2. Tests database connection
3. Prepares CSV files (removes headers)
4. Imports nutrients (COPY command)
5. Imports foods (COPY command)
   - Temporarily drops indexes for speed
   - Recreates indexes after import
6. Imports food nutrients
   - Uses staging table (UNLOGGED for speed)
   - Validates foreign keys
   - Transfers to main table
   - Creates indexes
7. Runs ANALYZE for query optimization
8. Creates detailed log file

**Performance:**
- Typical import time: 5-15 minutes
- Uses PostgreSQL COPY for bulk loading
- Temporary index removal for faster inserts
- UNLOGGED staging table for nutrient values

**Logs:**
All import logs are saved to: `../logs/usda-import-YYYYMMDD-HHMMSS.log`

## File Structure

```
gleam/
├── scripts/
│   ├── README.md                    # This file
│   ├── setup-usda-database.sh      # Main orchestrator
│   ├── download-usda-data.sh       # Download script
│   └── import-usda-data.sh         # Import script
├── data/
│   └── usda/
│       ├── raw/
│       │   └── FoodData_Central.zip     # Downloaded ZIP
│       ├── extracted/
│       │   ├── food.csv                 # Extracted CSVs
│       │   ├── nutrient.csv
│       │   └── food_nutrient.csv
│       └── processed/                   # Temporary (auto-deleted)
└── logs/
    └── usda-import-*.log               # Import logs
```

## Troubleshooting

### Issue: Download fails
**Solution:**
- Check internet connection
- Verify URL is accessible: https://fdc.nal.usda.gov/fdc-datasets/
- Try manual download and place ZIP in `../data/usda/raw/`

### Issue: Import fails with "cannot connect to database"
**Solution:**
- Verify PostgreSQL is running: `systemctl status postgresql` or `pg_ctl status`
- Check connection: `psql -h localhost -U postgres -d meal_planner`
- Verify credentials match environment variables

### Issue: "Insufficient disk space"
**Solution:**
- Free up at least 5GB of disk space
- Check space: `df -h`
- Consider mounting additional storage

### Issue: Import is very slow
**Expected behavior:**
- Downloads: 5-10 minutes (depends on connection)
- Import: 5-15 minutes (depends on hardware)
- Index creation takes the longest (2-5 minutes)

**To speed up:**
- Increase PostgreSQL `work_mem` and `maintenance_work_mem`
- Use SSD storage instead of HDD
- Ensure PostgreSQL has adequate resources

### Issue: "File not found" errors during import
**Solution:**
- Run `download-usda-data.sh` first
- Verify files exist in `../data/usda/extracted/`
- Check file permissions

### Issue: Foreign key violations
**Solution:**
- Ensure database schema is up to date
- Run migrations: `gleam run -m meal_planner/storage/migrations`
- Check that `foods` and `nutrients` tables exist

## Database Schema

### `nutrients` table
```sql
CREATE TABLE nutrients (
    id INTEGER PRIMARY KEY,           -- Nutrient ID (e.g., 1003)
    name TEXT NOT NULL,              -- Nutrient name (e.g., "Protein")
    unit_name TEXT NOT NULL,         -- Unit (e.g., "g", "mg")
    nutrient_nbr TEXT,               -- USDA nutrient number
    rank INTEGER                     -- Display order
);
```

### `foods` table
```sql
CREATE TABLE foods (
    fdc_id INTEGER PRIMARY KEY,      -- FoodData Central ID
    data_type TEXT NOT NULL,         -- Type: foundation, sr_legacy, survey, etc.
    description TEXT NOT NULL,       -- Food name/description
    food_category TEXT,              -- Category (e.g., "Dairy")
    publication_date TEXT            -- When published
);
```

### `food_nutrients` table
```sql
CREATE TABLE food_nutrients (
    id INTEGER PRIMARY KEY,
    fdc_id INTEGER NOT NULL,         -- References foods(fdc_id)
    nutrient_id INTEGER NOT NULL,    -- References nutrients(id)
    amount REAL                      -- Amount in nutrient's unit
);
```

### Indexes
- **Full-text search:** GIN index on `foods.description` for fast search
- **Filtering:** B-tree indexes on `data_type`, `food_category`
- **Lookups:** B-tree indexes on foreign keys in `food_nutrients`

## Performance Optimization

### PostgreSQL Configuration
For optimal import performance, consider these `postgresql.conf` settings:

```ini
# Increase for bulk operations
maintenance_work_mem = 1GB
work_mem = 256MB

# Faster writes during import
synchronous_commit = off          # Restore to 'on' after import
wal_buffers = 16MB
checkpoint_timeout = 30min
max_wal_size = 2GB

# More aggressive autovacuum after import
autovacuum_naptime = 10s
```

**Important:** Restore `synchronous_commit = on` after import for data safety.

### Import Optimizations Used
1. **Temporary index removal:** Indexes dropped before bulk insert, recreated after
2. **UNLOGGED staging table:** No WAL logging for initial load
3. **PostgreSQL COPY:** Native bulk loading (faster than INSERT)
4. **Batch validation:** Foreign key validation during staging→main transfer
5. **ANALYZE:** Update statistics after import for query optimization

## Data Sources

### USDA FoodData Central
- **Website:** https://fdc.nal.usda.gov/
- **Dataset:** FoodData Central CSV (Foundation Foods)
- **License:** Public Domain (US Government work)
- **Update Frequency:** Quarterly

### Dataset Types
- **Foundation Foods:** High-quality data on common foods
- **SR Legacy:** USDA National Nutrient Database for Standard Reference
- **Survey Foods:** Foods from FNDDS (What We Eat In America)
- **Branded Foods:** Commercial food products
- **Experimental Foods:** Research data

## Maintenance

### Updating the Database
USDA releases new datasets quarterly. To update:

```bash
# 1. Download latest dataset
# Update USDA_DATA_URL in download-usda-data.sh to latest version

# 2. Backup current database
pg_dump meal_planner > backup_$(date +%Y%m%d).sql

# 3. Run import
./setup-usda-database.sh

# 4. Verify
psql -d meal_planner -c "SELECT COUNT(*) FROM foods;"
```

### Cleanup Old Data
To remove downloaded files after successful import:

```bash
# Remove ZIP and extracted files (keeps database)
rm -rf ../data/usda/raw
rm -rf ../data/usda/extracted

# This saves ~2-3GB of disk space
```

### Database Maintenance
After import, run maintenance commands:

```bash
# Update statistics
psql -d meal_planner -c "ANALYZE foods;"
psql -d meal_planner -c "ANALYZE food_nutrients;"

# Cleanup
psql -d meal_planner -c "VACUUM ANALYZE;"
```

## Integration with Meal Planner

### Search Foods
```gleam
import meal_planner/storage

pub fn search_foods(query: String) {
  let conn = storage.start_pool(storage.default_config())
  storage.search_foods(conn, query, 50)
}
```

### Get Food Details with Nutrients
```gleam
pub fn get_food_details(fdc_id: Int) {
  let conn = storage.start_pool(storage.default_config())
  let food = storage.get_food_by_id(conn, fdc_id)
  let nutrients = storage.get_food_nutrients(conn, fdc_id)
  #(food, nutrients)
}
```

## Support

### Logs
Check import logs for detailed information:
```bash
tail -f ../logs/usda-import-*.log
```

### Database Queries
Verify import success:
```sql
-- Count records
SELECT
  (SELECT COUNT(*) FROM foods) as food_count,
  (SELECT COUNT(*) FROM nutrients) as nutrient_count,
  (SELECT COUNT(*) FROM food_nutrients) as food_nutrient_count;

-- Test search
SELECT * FROM foods
WHERE to_tsvector('english', description) @@ plainto_tsquery('english', 'chicken')
LIMIT 10;

-- Database size
SELECT pg_size_pretty(pg_database_size('meal_planner'));
```

## License

These scripts are part of the Meal Planner project. The USDA FoodData Central database is in the public domain as a work of the US Government.

## Credits

- **USDA FoodData Central:** https://fdc.nal.usda.gov/
- **Meal Planner Project:** https://github.com/yourusername/meal-planner
