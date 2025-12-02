# Download USDA FoodData Central dataset
# Source: https://fdc.nal.usda.gov/download-datasets/

$ErrorActionPreference = "Stop"

# USDA FoodData Central CSV URL (April 2025 release)
$USDA_URL = "https://fdc.nal.usda.gov/fdc-datasets/FoodData_Central_csv_2025-04-24.zip"
$USDA_ZIP = "FoodData_Central_csv_2025-04-24.zip"
$USDA_DIR = "FoodData_Central_csv_2025-04-24"

# Determine cache directory
$DATA_DIR = Join-Path $env:LOCALAPPDATA "meal-planner"
$CACHE_DIR = Join-Path $DATA_DIR "usda-cache"

Write-Host "=== USDA FoodData Central Downloader ===" -ForegroundColor Cyan
Write-Host "Cache directory: $CACHE_DIR"
Write-Host ""

# Create directories
New-Item -ItemType Directory -Force -Path $CACHE_DIR | Out-Null
Set-Location $CACHE_DIR

$USDA_FULL_DIR = Join-Path $CACHE_DIR $USDA_DIR
$FOOD_CSV = Join-Path $USDA_FULL_DIR "food.csv"

# Check if already extracted
if ((Test-Path $USDA_FULL_DIR) -and (Test-Path $FOOD_CSV)) {
    Write-Host "USDA data already downloaded and extracted!" -ForegroundColor Green
    Write-Host "Location: $USDA_FULL_DIR"
    Write-Host ""
    Write-Host "Files:"
    Get-ChildItem $USDA_FULL_DIR -Filter "*.csv" | Select-Object Name, @{N='Size';E={"{0:N2} MB" -f ($_.Length / 1MB)}} | Format-Table
    exit 0
}

$ZIP_PATH = Join-Path $CACHE_DIR $USDA_ZIP

# Download if not present
if (-not (Test-Path $ZIP_PATH)) {
    Write-Host "Downloading USDA FoodData Central (~200MB)..." -ForegroundColor Yellow
    Write-Host "URL: $USDA_URL"
    Write-Host ""

    # Use faster download with progress
    $ProgressPreference = 'SilentlyContinue'  # Makes download much faster
    try {
        Invoke-WebRequest -Uri $USDA_URL -OutFile $ZIP_PATH -UseBasicParsing
    }
    finally {
        $ProgressPreference = 'Continue'
    }

    Write-Host "Download complete!" -ForegroundColor Green
}
else {
    Write-Host "ZIP file already exists, skipping download."
}

# Extract
Write-Host "Extracting..." -ForegroundColor Yellow
Expand-Archive -Path $ZIP_PATH -DestinationPath $CACHE_DIR -Force

# Clean up zip to save space
Write-Host "Cleaning up..."
Remove-Item $ZIP_PATH -Force

Write-Host ""
Write-Host "=== Download Complete ===" -ForegroundColor Green
Write-Host "Location: $USDA_FULL_DIR"
Write-Host ""
Write-Host "Files downloaded:"
Get-ChildItem $USDA_FULL_DIR -Filter "*.csv" | Select-Object Name, @{N='Size';E={"{0:N2} MB" -f ($_.Length / 1MB)}} | Format-Table
Write-Host ""
Write-Host "Next step: Run the following from the gleam/ directory:" -ForegroundColor Cyan
Write-Host "  gleam run -m scripts/init_db"
