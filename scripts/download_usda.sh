#!/bin/bash
# Download USDA FoodData Central dataset
# Source: https://fdc.nal.usda.gov/download-datasets/

set -e

# USDA FoodData Central CSV URL (April 2025 release)
USDA_URL="https://fdc.nal.usda.gov/fdc-datasets/FoodData_Central_csv_2025-04-24.zip"
USDA_ZIP="FoodData_Central_csv_2025-04-24.zip"
USDA_DIR="FoodData_Central_csv_2025-04-24"

# Determine cache directory (XDG standard)
if [ -n "$XDG_DATA_HOME" ]; then
    DATA_DIR="$XDG_DATA_HOME/meal-planner"
else
    DATA_DIR="$HOME/.local/share/meal-planner"
fi

CACHE_DIR="$DATA_DIR/usda-cache"

echo "=== USDA FoodData Central Downloader ==="
echo "Cache directory: $CACHE_DIR"

# Create directories
mkdir -p "$CACHE_DIR"
cd "$CACHE_DIR"

# Check if already extracted
if [ -d "$USDA_DIR" ] && [ -f "$USDA_DIR/food.csv" ]; then
    echo "USDA data already downloaded and extracted!"
    echo "Location: $CACHE_DIR/$USDA_DIR"
    echo ""
    echo "Files:"
    ls -lh "$USDA_DIR"/*.csv 2>/dev/null | head -10
    exit 0
fi

# Download if not present
if [ ! -f "$USDA_ZIP" ]; then
    echo "Downloading USDA FoodData Central (~200MB)..."
    echo "URL: $USDA_URL"

    if command -v curl &> /dev/null; then
        curl -L -o "$USDA_ZIP" "$USDA_URL" --progress-bar
    elif command -v wget &> /dev/null; then
        wget -O "$USDA_ZIP" "$USDA_URL"
    else
        echo "Error: Neither curl nor wget found. Please install one of them."
        exit 1
    fi

    echo "Download complete!"
else
    echo "ZIP file already exists, skipping download."
fi

# Extract
echo "Extracting..."
if command -v unzip &> /dev/null; then
    unzip -o "$USDA_ZIP"
else
    echo "Error: unzip not found. Please install it."
    exit 1
fi

# Clean up zip to save space
echo "Cleaning up..."
rm -f "$USDA_ZIP"

echo ""
echo "=== Download Complete ==="
echo "Location: $CACHE_DIR/$USDA_DIR"
echo ""
echo "Files downloaded:"
ls -lh "$USDA_DIR"/*.csv 2>/dev/null | head -10
echo ""
echo "Next step: Run 'gleam run' from the gleam/ directory to import data."
