#!/usr/bin/env bash
# Download USDA FoodData Central CSV data
# Downloads the Foundation Foods dataset (~300k foods, 4.5M nutrients)

set -euo pipefail

# Configuration
USDA_DATA_URL="https://fdc.nal.usda.gov/fdc-datasets/FoodData_Central_csv_2024-10-31.zip"
DATA_DIR="$(dirname "$0")/../data/usda"
DOWNLOAD_DIR="${DATA_DIR}/raw"
EXTRACT_DIR="${DATA_DIR}/extracted"
ZIP_FILE="${DOWNLOAD_DIR}/FoodData_Central.zip"

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

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

check_dependencies() {
    log_info "Checking dependencies..."

    if ! command -v wget &> /dev/null && ! command -v curl &> /dev/null; then
        log_error "Neither wget nor curl found. Please install one of them."
        exit 1
    fi

    if ! command -v unzip &> /dev/null; then
        log_error "unzip not found. Please install unzip."
        exit 1
    fi

    log_success "All dependencies found"
}

create_directories() {
    log_info "Creating directory structure..."
    mkdir -p "${DOWNLOAD_DIR}"
    mkdir -p "${EXTRACT_DIR}"
    log_success "Directories created: ${DATA_DIR}"
}

download_data() {
    log_info "Downloading USDA FoodData Central CSV data..."
    log_info "URL: ${USDA_DATA_URL}"
    log_info "Destination: ${ZIP_FILE}"

    if [ -f "${ZIP_FILE}" ]; then
        log_warn "ZIP file already exists. Skipping download."
        log_warn "Delete ${ZIP_FILE} to re-download."
        return 0
    fi

    # Use wget or curl based on availability
    if command -v wget &> /dev/null; then
        wget --progress=bar:force:noscroll -O "${ZIP_FILE}" "${USDA_DATA_URL}" || {
            log_error "Download failed with wget"
            exit 1
        }
    else
        curl -# -L -o "${ZIP_FILE}" "${USDA_DATA_URL}" || {
            log_error "Download failed with curl"
            exit 1
        }
    fi

    log_success "Download complete"
}

extract_data() {
    log_info "Extracting CSV files..."

    # Extract to temporary directory first
    local temp_extract="${EXTRACT_DIR}.tmp"
    mkdir -p "${temp_extract}"

    unzip -q "${ZIP_FILE}" -d "${temp_extract}" || {
        log_error "Extraction failed"
        rm -rf "${temp_extract}"
        exit 1
    }

    # Move CSV files to extract directory
    # The ZIP contains a subdirectory, find and move the CSVs
    find "${temp_extract}" -name "*.csv" -exec mv {} "${EXTRACT_DIR}/" \;

    # Cleanup
    rm -rf "${temp_extract}"

    log_success "Extraction complete: ${EXTRACT_DIR}"
}

verify_files() {
    log_info "Verifying extracted files..."

    local required_files=(
        "food.csv"
        "nutrient.csv"
        "food_nutrient.csv"
    )

    local all_found=true
    for file in "${required_files[@]}"; do
        if [ -f "${EXTRACT_DIR}/${file}" ]; then
            local size=$(du -h "${EXTRACT_DIR}/${file}" | cut -f1)
            local lines=$(wc -l < "${EXTRACT_DIR}/${file}")
            log_success "Found ${file} (${size}, ${lines} lines)"
        else
            log_error "Missing required file: ${file}"
            all_found=false
        fi
    done

    if [ "${all_found}" = false ]; then
        log_error "Some required files are missing"
        exit 1
    fi

    log_success "All required files present"
}

show_summary() {
    log_info "Download Summary:"
    echo ""
    echo "  Data Directory: ${DATA_DIR}"
    echo "  ZIP File:       ${ZIP_FILE}"
    echo "  CSV Files:      ${EXTRACT_DIR}"
    echo ""
    log_info "Next steps:"
    echo "  1. Run: ./import-usda-data.sh"
    echo "  2. Monitor progress in logs"
    echo ""
}

main() {
    log_info "USDA FoodData Central Download Script"
    echo ""

    check_dependencies
    create_directories
    download_data
    extract_data
    verify_files
    show_summary

    log_success "Download complete! Ready for import."
}

main "$@"
