#!/bin/bash

# Simple binary converter for Rust functional style
# Usage: ./convert_one.sh <binary_name>

set -e

if [ $# -eq 0 ]; then
	echo "Usage: $0 <binary_name>"
	echo ""
	echo "Available binaries:"
	find src/bin -name "*.rs" -exec basename {} \; | sort
	exit 1
fi

BINARY_NAME="$1"
SRC_FILE="src/bin/${BINARY_NAME}.rs"

if [ ! -f "$SRC_FILE" ]; then
	echo "Error: Source file not found: $SRC_FILE"
	exit 1
fi

echo "=== Converting binary: $BINARY_NAME ==="
echo ""

# Create backup
cp "$SRC_FILE" "${SRC_FILE}.backup"
echo "Created backup: ${SRC_FILE}.backup"

echo "=== Conversion Instructions ==="
echo ""
echo "1. Remove the #[tokio::main] attribute from the file"
echo "2. Change main() function to async fn main() that calls run().await"
echo "3. Extract all logic into a separate async run() function that returns Result<Output, Box<dyn std::error::Error>>"
echo "4. Move error handling to use proper Result propagation instead of direct exit calls"
echo "5. Make input/output processing more explicit and functional"
echo ""
echo "=== Example pattern ==="
echo "Before:"
echo "  #[tokio::main]"
echo "  async fn main() { ... }"
echo ""
echo "After:"
echo "  #[tokio::main]"
echo "  async fn main() {"
echo "      match run().await { ... }"
echo "  }"
echo ""
echo "  async fn run() -> Result<Output, Box<dyn std::error::Error>> { ... }"
echo ""
echo "=== Manual conversion required ==="
echo "Please manually convert $SRC_FILE according to the instructions above."
echo "The original file is backed up as ${SRC_FILE}.backup"
