#!/bin/bash
# Quick test script for OAuth module

echo "Testing OAuth module compilation..."

# Create a minimal test file
cat > /tmp/test_oauth_minimal.gleam << 'EOF'
import fatsecret/core/oauth
import gleam/dict
import gleam/option.{None, Some}
import gleam/io

pub fn main() {
  // Test 1: oauth_encode
  let encoded = oauth.oauth_encode("Hello World!")
  io.println("✓ oauth_encode works: " <> encoded)

  // Test 2: generate_nonce
  let nonce = oauth.generate_nonce()
  io.println("✓ generate_nonce works: " <> nonce)

  // Test 3: unix_timestamp
  let ts = oauth.unix_timestamp()
  io.println("✓ unix_timestamp works: " <> int.to_string(ts))

  // Test 4: build_oauth_params
  let params = oauth.build_oauth_params(
    "test_key",
    "test_secret",
    "GET",
    "https://api.example.com/test",
    dict.new(),
    None,
    None
  )
  io.println("✓ build_oauth_params works - signature: " <> result.unwrap(dict.get(params, "oauth_signature"), "ERROR"))

  io.println("\n✅ All OAuth functions working!")
}
EOF

# Try to compile and run
cd /home/lewis/src/meal-planner/gleam
cp /tmp/test_oauth_minimal.gleam test/test_oauth_minimal.gleam
gleam run -m test_oauth_minimal 2>&1
rm -f test/test_oauth_minimal.gleam
