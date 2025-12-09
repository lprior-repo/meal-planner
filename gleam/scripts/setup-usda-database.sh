#!/usr/bin/env bash
# Main orchestrator script for USDA FoodData Central database setup
# Combines download and import with validation and error handling

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BOLD='\033[1m'
NC='\033[0m'

log_info() {
    echo -e "${BLUE}[INFO]${NC} $*"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $*"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $*"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $*"
}

print_banner() {
    echo -e "${BOLD}"
    echo "╔════════════════════════════════════════════════════════════════╗"
    echo "║        USDA FoodData Central Database Setup Script            ║"
    echo "║                                                                ║"
    echo "║  This script will:                                            ║"
    echo "║  1. Download USDA FoodData Central CSV data (~2GB)            ║"
    echo "║  2. Extract and prepare CSV files                             ║"
    echo "║  3. Import into PostgreSQL database                           ║"
    echo "║     - ~300,000 food items                                     ║"
    echo "║     - ~4,500,000 nutrient values                              ║"
    echo "║                                                                ║"
    echo "║  Estimated time: 10-30 minutes                                ║"
    echo "║  Disk space required: ~3GB                                    ║"
    echo "╚════════════════════════════════════════════════════════════════╝"
    echo -e "${NC}"
}

check_environment() {
    log_info "Checking environment..."

    # Check required environment variables
    if [ -z "${DB_HOST:-}" ]; then
        export DB_HOST="localhost"
        log_warn "DB_HOST not set, using default: localhost"
    fi

    if [ -z "${DB_PORT:-}" ]; then
        export DB_PORT="5432"
        log_warn "DB_PORT not set, using default: 5432"
    fi

    if [ -z "${DB_NAME:-}" ]; then
        export DB_NAME="meal_planner"
        log_warn "DB_NAME not set, using default: meal_planner"
    fi

    if [ -z "${DB_USER:-}" ]; then
        export DB_USER="postgres"
        log_warn "DB_USER not set, using default: postgres"
    fi

    # Prompt for password if not set
    if [ -z "${DB_PASSWORD:-}" ]; then
        log_warn "DB_PASSWORD not set in environment"
        read -sp "Enter PostgreSQL password for ${DB_USER}: " DB_PASSWORD
        echo ""
        export DB_PASSWORD
    fi

    log_success "Environment configured"
    echo ""
    echo "  Database: ${DB_HOST}:${DB_PORT}/${DB_NAME}"
    echo "  User:     ${DB_USER}"
    echo ""
}

check_disk_space() {
    log_info "Checking available disk space..."

    local data_dir="${SCRIPT_DIR}/../data/usda"
    local parent_dir=$(dirname "${data_dir}")

    # Create parent directory if it doesn't exist
    mkdir -p "${parent_dir}"

    # Get available space in GB
    local available_space=$(df -BG "${parent_dir}" | awk 'NR==2 {print $4}' | sed 's/G//')

    if [ "${available_space}" -lt 5 ]; then
        log_error "Insufficient disk space. Need at least 5GB, have ${available_space}GB"
        exit 1
    fi

    log_success "Disk space OK (${available_space}GB available)"
}

run_download() {
    log_info "Running download script..."
    echo ""

    if ! bash "${SCRIPT_DIR}/download-usda-data.sh"; then
        log_error "Download failed. Check the error messages above."
        exit 1
    fi

    log_success "Download complete"
    echo ""
}

run_import() {
    log_info "Running import script..."
    echo ""

    if ! bash "${SCRIPT_DIR}/import-usda-data.sh"; then
        log_error "Import failed. Check the error messages above."
        log_error "Check logs in: ${SCRIPT_DIR}/../logs/"
        exit 1
    fi

    log_success "Import complete"
    echo ""
}

verify_import() {
    log_info "Verifying import..."

    # Count records
    local food_count=$(PGPASSWORD="${DB_PASSWORD}" psql -h "${DB_HOST}" -p "${DB_PORT}" -U "${DB_USER}" -d "${DB_NAME}" -t -c "SELECT COUNT(*) FROM foods;" 2>/dev/null | xargs || echo "0")
    local nutrient_count=$(PGPASSWORD="${DB_PASSWORD}" psql -h "${DB_HOST}" -p "${DB_PORT}" -U "${DB_USER}" -d "${DB_NAME}" -t -c "SELECT COUNT(*) FROM nutrients;" 2>/dev/null | xargs || echo "0")
    local food_nutrient_count=$(PGPASSWORD="${DB_PASSWORD}" psql -h "${DB_HOST}" -p "${DB_PORT}" -U "${DB_USER}" -d "${DB_NAME}" -t -c "SELECT COUNT(*) FROM food_nutrients;" 2>/dev/null | xargs || echo "0")

    if [ "${food_count}" -eq 0 ] || [ "${nutrient_count}" -eq 0 ] || [ "${food_nutrient_count}" -eq 0 ]; then
        log_error "Import verification failed. Some tables are empty:"
        echo "  Foods: ${food_count}"
        echo "  Nutrients: ${nutrient_count}"
        echo "  Food Nutrients: ${food_nutrient_count}"
        exit 1
    fi

    log_success "Import verified successfully"
    echo ""
    echo "  Foods:           ${food_count}"
    echo "  Nutrients:       ${nutrient_count}"
    echo "  Food Nutrients:  ${food_nutrient_count}"
    echo ""
}

test_search() {
    log_info "Testing search functionality..."

    # Test a simple search
    local test_query="chicken breast"
    local result=$(PGPASSWORD="${DB_PASSWORD}" psql -h "${DB_HOST}" -p "${DB_PORT}" -U "${DB_USER}" -d "${DB_NAME}" -t -c "
        SELECT COUNT(*) FROM foods
        WHERE to_tsvector('english', description) @@ plainto_tsquery('english', '${test_query}');
    " 2>/dev/null | xargs || echo "0")

    if [ "${result}" -gt 0 ]; then
        log_success "Search test passed (found ${result} results for '${test_query}')"
    else
        log_warn "Search test returned no results (this may be normal for some datasets)"
    fi
}

print_completion() {
    echo -e "${BOLD}${GREEN}"
    echo "╔════════════════════════════════════════════════════════════════╗"
    echo "║                     Setup Complete! ✓                          ║"
    echo "╚════════════════════════════════════════════════════════════════╝"
    echo -e "${NC}"
    echo ""
    log_info "The USDA FoodData Central database is now ready to use!"
    echo ""
    log_info "Next steps:"
    echo "  1. Start your application"
    echo "  2. Test food search functionality"
    echo "  3. Check logs in: ${SCRIPT_DIR}/../logs/"
    echo ""
}

show_usage() {
    echo "Usage: $0 [OPTIONS]"
    echo ""
    echo "Options:"
    echo "  --download-only    Only download data, skip import"
    echo "  --import-only      Only import data, skip download"
    echo "  --help             Show this help message"
    echo ""
    echo "Environment Variables:"
    echo "  DB_HOST            PostgreSQL host (default: localhost)"
    echo "  DB_PORT            PostgreSQL port (default: 5432)"
    echo "  DB_NAME            Database name (default: meal_planner)"
    echo "  DB_USER            Database user (default: postgres)"
    echo "  DB_PASSWORD        Database password (will prompt if not set)"
    echo ""
    echo "Example:"
    echo "  DB_HOST=localhost DB_PASSWORD=mypass $0"
    echo ""
}

main() {
    local download_only=false
    local import_only=false

    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            --download-only)
                download_only=true
                shift
                ;;
            --import-only)
                import_only=true
                shift
                ;;
            --help)
                show_usage
                exit 0
                ;;
            *)
                log_error "Unknown option: $1"
                show_usage
                exit 1
                ;;
        esac
    done

    print_banner
    check_environment
    check_disk_space

    if [ "${import_only}" = false ]; then
        run_download
    fi

    if [ "${download_only}" = false ]; then
        run_import
        verify_import
        test_search
        print_completion
    fi
}

# Handle interrupts gracefully
trap 'log_error "Setup interrupted by user"; exit 130' INT TERM

main "$@"
