#!/bin/bash

# Script to fix unwrap_used violations in binary files
# This script will:
# 1. Remove the allow(clippy::unwrap_used, clippy::expect_used) attributes
# 2. Replace unwrap() calls with expect() calls with meaningful messages

set -e

# Find all binary files with unwrap_used allowance
FILES=$(rg "allow.*unwrap_used" src/bin --type rust -l)

for file in $FILES; do
	echo "Processing $file..."

	# Remove the allow attributes
	sed -i '/#![allow(clippy::exit, clippy::unwrap_used, clippy::expect_used)]/c\
// CLI binaries: exit is acceptable at the top level' "$file"

	sed -i '/#![allow(clippy::exit, clippy::unwrap_used)]/c\
// CLI binaries: exit is acceptable at the top level' "$file"

	# Replace unwrap() calls with expect() for JSON serialization
	sed -i 's/serde_json::to_string(&output)\.unwrap()/serde_json::to_string(&output).expect("Failed to serialize output JSON")/g' "$file"
	sed -i 's/serde_json::to_string(&error)\.unwrap()/serde_json::to_string(&error).expect("Failed to serialize error JSON")/g' "$file"
	sed -i 's/serde_json::to_string(&json)\.unwrap()/serde_json::to_string(&json).expect("Failed to serialize JSON")/g' "$file"

	# Replace unwrap() calls with expect() for JSON parsing in tests
	sed -i 's/serde_json::from_str(json)\.unwrap()/serde_json::from_str(json).expect("Failed to parse test JSON")/g' "$file"
	sed -i 's/serde_json::from_str(&arg)\.unwrap()/serde_json::from_str(&arg).expect("Failed to parse argument JSON")/g' "$file"
	sed -i 's/serde_json::from_str(&input_str)\.unwrap()/serde_json::from_str(&input_str).expect("Failed to parse input JSON")/g' "$file"
	sed -i 's/serde_json::from_str(&json)\.unwrap()/serde_json::from_str(&json).expect("Failed to parse JSON")/g' "$file"

	# Replace first().unwrap() calls with expect()
	sed -i 's/\.first()\.unwrap()/\.first().expect("Expected at least one element")/g' "$file"

	# Replace any remaining unwrap calls with expect
	sed -i 's/\.unwrap()/\.expect("Unexpected None value")/g' "$file"

	echo "Fixed $file"
done

echo "All files processed!"
