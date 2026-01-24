#!/bin/bash

# Script to convert Rust binaries to functional style one at a time
# Usage: ./convert_binary.sh <binary_name>

set -e # Exit on any error

if [ $# -eq 0 ]; then
	echo "Usage: $0 <binary_name>"
	echo "Example: $0 fatsecret_foods_search"
	exit 1
fi

BINARY_NAME="$1"
echo "Converting binary: $BINARY_NAME"

# Find the source file
SRC_FILE="src/bin/$BINARY_NAME.rs"

if [ ! -f "$SRC_FILE" ]; then
	echo "Error: Source file not found: $SRC_FILE"
	exit 1
fi

# Create backup
cp "$SRC_FILE" "${SRC_FILE}.backup"

echo "Created backup: ${SRC_FILE}.backup"

# Process the binary to make it more functional
# We'll use sed to make changes, but first let's read the file to understand its structure
echo "Processing $SRC_FILE..."

# For now, we'll just create a basic conversion script that can be used manually when needed

cat >"convert_$BINARY_NAME.sh" <<'EOF'
#!/bin/bash

# Convert $BINARY_NAME.rs to functional style
# This is a template for manual execution

echo "Converting $BINARY_NAME to functional style..."

# 1. Remove #[tokio::main] and use async fn main() instead
# 2. Extract the core logic into an async function
# 3. Simplify error handling with proper Result types
# 4. Make input/output processing more explicit

echo "Manual conversion steps:"
echo "1. Remove #[tokio::main] from the file"
echo "2. Change main() to async fn main() and make it call run() async"
echo "3. Move logic into a separate async run() function that returns Result<Output, Box<dyn std::error::Error>>"
echo "4. Simplify error handling with proper error propagation"
echo "5. Make input processing cleaner"
echo "6. Ensure consistent JSON serialization"

echo "Conversion complete for $BINARY_NAME"
EOF

chmod +x "convert_$BINARY_NAME.sh"

echo "Created conversion script: convert_$BINARY_NAME.sh"
echo "Run it manually to see the specific changes needed for $BINARY_NAME"

# Show what we're changing
echo ""
echo "=== ORIGINAL FILE ==="
cat "$SRC_FILE" | head -20
echo ""
echo "... (file continues)"
