#!/usr/bin/env bash
# Import USDA FoodData Central CSV data into PostgreSQL
# Handles ~300k foods and 4.5M nutrient records with progress tracking

set -euo pipefail

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DATA_DIR="${SCRIPT_DIR}/../data/usda/extracted"
LOG_DIR="${SCRIPT_DIR}/../logs"
LOG_FILE="${LOG_DIR}/usda-import-$(date +%Y%m%d-%H%M%S).log"

# Database connection (override with environment variables)
DB_HOST="${DB_HOST:-localhost}"
DB_PORT="${DB_PORT:-5432}"
DB_NAME="${DB_NAME:-meal_planner}"
DB_USER="${DB_USER:-postgres}"

# Import settings
BATCH_SIZE=10000
NUTRIENT_BATCH_SIZE=50000

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

# Ensure log directory exists
mkdir -p "${LOG_DIR}"

log_info() {
    echo -e "${BLUE}[INFO]${NC} $*" | tee -a "${LOG_FILE}"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $*" | tee -a "${LOG_FILE}"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $*" | tee -a "${LOG_FILE}"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $*" | tee -a "${LOG_FILE}"
}

log_progress() {
    local current=$1
    local total=$2
    local desc=$3
    local percent=$((current * 100 / total))
    echo -ne "\r${BLUE}[PROGRESS]${NC} ${desc}: ${current}/${total} (${percent}%)  " | tee -a "${LOG_FILE}"
}

check_prerequisites() {
    log_info "Checking prerequisites..."

    # Check psql
    if ! command -v psql &> /dev/null; then
        log_error "psql not found. Please install PostgreSQL client."
        exit 1
    fi

    # Check CSV files
    local required_files=(
        "food.csv"
        "nutrient.csv"
        "food_nutrient.csv"
    )

    for file in "${required_files[@]}"; do
        if [ ! -f "${DATA_DIR}/${file}" ]; then
            log_error "Required file not found: ${DATA_DIR}/${file}"
            log_error "Run ./download-usda-data.sh first"
            exit 1
        fi
    done

    # Test database connection
    if ! PGPASSWORD="${DB_PASSWORD:-}" psql -h "${DB_HOST}" -p "${DB_PORT}" -U "${DB_USER}" -d "${DB_NAME}" -c "SELECT 1;" &> /dev/null; then
        log_error "Cannot connect to database. Check connection settings:"
        log_error "  Host: ${DB_HOST}:${DB_PORT}"
        log_error "  Database: ${DB_NAME}"
        log_error "  User: ${DB_USER}"
        exit 1
    fi

    log_success "All prerequisites met"
}

execute_sql() {
    local sql="$1"
    PGPASSWORD="${DB_PASSWORD:-}" psql -h "${DB_HOST}" -p "${DB_PORT}" -U "${DB_USER}" -d "${DB_NAME}" -c "${sql}" 2>&1 | tee -a "${LOG_FILE}"
}

execute_sql_file() {
    local file="$1"
    PGPASSWORD="${DB_PASSWORD:-}" psql -h "${DB_HOST}" -p "${DB_PORT}" -U "${DB_USER}" -d "${DB_NAME}" -f "${file}" 2>&1 | tee -a "${LOG_FILE}"
}

get_row_count() {
    local table="$1"
    PGPASSWORD="${DB_PASSWORD:-}" psql -h "${DB_HOST}" -p "${DB_PORT}" -U "${DB_USER}" -d "${DB_NAME}" -t -c "SELECT COUNT(*) FROM ${table};" 2>/dev/null | xargs || echo "0"
}

prepare_csv_files() {
    log_info "Preparing CSV files for import..."

    # Create temporary directory for processed CSVs
    local temp_dir="${DATA_DIR}/processed"
    mkdir -p "${temp_dir}"

    # Clean and prepare food.csv
    log_info "Processing food.csv..."
    tail -n +2 "${DATA_DIR}/food.csv" > "${temp_dir}/food_clean.csv"

    # Clean and prepare nutrient.csv
    log_info "Processing nutrient.csv..."
    tail -n +2 "${DATA_DIR}/nutrient.csv" > "${temp_dir}/nutrient_clean.csv"

    # Clean and prepare food_nutrient.csv
    log_info "Processing food_nutrient.csv..."
    tail -n +2 "${DATA_DIR}/food_nutrient.csv" > "${temp_dir}/food_nutrient_clean.csv"

    log_success "CSV files prepared in ${temp_dir}"
}

import_nutrients() {
    log_info "Importing nutrients..."

    local csv_file="${DATA_DIR}/processed/nutrient_clean.csv"
    local total_lines=$(wc -l < "${csv_file}")

    # Truncate existing nutrients
    execute_sql "TRUNCATE TABLE nutrients CASCADE;" > /dev/null

    # Import using COPY
    local copy_sql="COPY nutrients (id, name, unit_name, nutrient_nbr, rank)
                    FROM '${csv_file}'
                    WITH (FORMAT csv, DELIMITER ',', NULL '', QUOTE '\"');"

    log_info "Importing ${total_lines} nutrients..."
    PGPASSWORD="${DB_PASSWORD:-}" psql -h "${DB_HOST}" -p "${DB_PORT}" -U "${DB_USER}" -d "${DB_NAME}" -c "${copy_sql}" 2>&1 | tee -a "${LOG_FILE}"

    local count=$(get_row_count "nutrients")
    log_success "Imported ${count} nutrients"
}

import_foods() {
    log_info "Importing foods..."

    local csv_file="${DATA_DIR}/processed/food_clean.csv"
    local total_lines=$(wc -l < "${csv_file}")

    # Truncate existing foods
    execute_sql "TRUNCATE TABLE foods CASCADE;" > /dev/null

    # Disable indexes temporarily for faster import
    log_info "Dropping indexes for faster import..."
    execute_sql "DROP INDEX IF EXISTS idx_foods_description_gin;" > /dev/null
    execute_sql "DROP INDEX IF EXISTS idx_foods_data_type;" > /dev/null
    execute_sql "DROP INDEX IF EXISTS idx_foods_category;" > /dev/null

    # Import using COPY
    local copy_sql="COPY foods (fdc_id, data_type, description, food_category, publication_date)
                    FROM '${csv_file}'
                    WITH (FORMAT csv, DELIMITER ',', NULL '', QUOTE '\"');"

    log_info "Importing ${total_lines} foods..."
    PGPASSWORD="${DB_PASSWORD:-}" psql -h "${DB_HOST}" -p "${DB_PORT}" -U "${DB_USER}" -d "${DB_NAME}" -c "${copy_sql}" 2>&1 | tee -a "${LOG_FILE}"

    # Recreate indexes
    log_info "Recreating indexes..."
    execute_sql "CREATE INDEX idx_foods_description_gin ON foods USING gin(to_tsvector('english', description));" > /dev/null
    execute_sql "CREATE INDEX idx_foods_data_type ON foods(data_type);" > /dev/null
    execute_sql "CREATE INDEX idx_foods_category ON foods(food_category);" > /dev/null

    local count=$(get_row_count "foods")
    log_success "Imported ${count} foods"
}

import_food_nutrients() {
    log_info "Importing food nutrients (this may take several minutes)..."

    local csv_file="${DATA_DIR}/processed/food_nutrient_clean.csv"
    local total_lines=$(wc -l < "${csv_file}")

    # Truncate existing data
    execute_sql "TRUNCATE TABLE food_nutrients CASCADE;" > /dev/null
    execute_sql "TRUNCATE TABLE food_nutrients_staging;" > /dev/null

    # Drop indexes temporarily
    log_info "Dropping indexes for faster import..."
    execute_sql "DROP INDEX IF EXISTS idx_food_nutrients_fdc_id;" > /dev/null
    execute_sql "DROP INDEX IF EXISTS idx_food_nutrients_nutrient_id;" > /dev/null

    # Import to staging table first (UNLOGGED for speed)
    log_info "Importing ${total_lines} food nutrient records to staging table..."
    local copy_sql="COPY food_nutrients_staging (id, fdc_id, nutrient_id, amount)
                    FROM '${csv_file}'
                    WITH (FORMAT csv, DELIMITER ',', NULL '', QUOTE '\"');"

    PGPASSWORD="${DB_PASSWORD:-}" psql -h "${DB_HOST}" -p "${DB_PORT}" -U "${DB_USER}" -d "${DB_NAME}" -c "${copy_sql}" 2>&1 | tee -a "${LOG_FILE}"

    # Transfer from staging to main table with validation
    log_info "Validating and transferring to main table..."
    local transfer_sql="
        INSERT INTO food_nutrients (id, fdc_id, nutrient_id, amount)
        SELECT s.id, s.fdc_id, s.nutrient_id, s.amount
        FROM food_nutrients_staging s
        WHERE EXISTS (SELECT 1 FROM foods f WHERE f.fdc_id = s.fdc_id)
          AND EXISTS (SELECT 1 FROM nutrients n WHERE n.id = s.nutrient_id);
    "
    execute_sql "${transfer_sql}" > /dev/null

    # Recreate indexes
    log_info "Recreating indexes (this will take a few minutes)..."
    execute_sql "CREATE INDEX idx_food_nutrients_fdc_id ON food_nutrients(fdc_id);" > /dev/null
    execute_sql "CREATE INDEX idx_food_nutrients_nutrient_id ON food_nutrients(nutrient_id);" > /dev/null

    # Cleanup staging
    execute_sql "TRUNCATE TABLE food_nutrients_staging;" > /dev/null

    # Analyze tables for query optimization
    log_info "Analyzing tables for query optimization..."
    execute_sql "ANALYZE foods;" > /dev/null
    execute_sql "ANALYZE nutrients;" > /dev/null
    execute_sql "ANALYZE food_nutrients;" > /dev/null

    local count=$(get_row_count "food_nutrients")
    log_success "Imported ${count} food nutrient records"
}

show_summary() {
    log_info "Import Summary:"
    echo "" | tee -a "${LOG_FILE}"

    local nutrient_count=$(get_row_count "nutrients")
    local food_count=$(get_row_count "foods")
    local nutrient_value_count=$(get_row_count "food_nutrients")

    echo "  Nutrients:       ${nutrient_count}" | tee -a "${LOG_FILE}"
    echo "  Foods:           ${food_count}" | tee -a "${LOG_FILE}"
    echo "  Nutrient Values: ${nutrient_value_count}" | tee -a "${LOG_FILE}"
    echo "" | tee -a "${LOG_FILE}"
    echo "  Log file: ${LOG_FILE}" | tee -a "${LOG_FILE}"
    echo "" | tee -a "${LOG_FILE}"

    # Database size
    local db_size=$(PGPASSWORD="${DB_PASSWORD:-}" psql -h "${DB_HOST}" -p "${DB_PORT}" -U "${DB_USER}" -d "${DB_NAME}" -t -c "SELECT pg_size_pretty(pg_database_size('${DB_NAME}'));" 2>/dev/null | xargs || echo "unknown")
    echo "  Database size: ${db_size}" | tee -a "${LOG_FILE}"
    echo "" | tee -a "${LOG_FILE}"
}

cleanup() {
    log_info "Cleaning up temporary files..."
    rm -rf "${DATA_DIR}/processed"
    log_success "Cleanup complete"
}

main() {
    log_info "USDA FoodData Central Import Script"
    log_info "Started at: $(date)"
    echo "" | tee -a "${LOG_FILE}"

    local start_time=$(date +%s)

    check_prerequisites
    prepare_csv_files
    import_nutrients
    import_foods
    import_food_nutrients
    show_summary
    cleanup

    local end_time=$(date +%s)
    local duration=$((end_time - start_time))
    local minutes=$((duration / 60))
    local seconds=$((duration % 60))

    log_success "Import complete in ${minutes}m ${seconds}s"
    log_info "Log file: ${LOG_FILE}"
}

# Handle interrupts gracefully
trap 'log_error "Import interrupted by user"; cleanup; exit 130' INT TERM

main "$@"
