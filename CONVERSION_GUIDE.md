# Functional Rust Binary Conversion Guide

This document describes how to convert Rust binaries in this project to a more functional style.

## Current Pattern
Most binaries follow this structure:
```rust
#[tokio::main]
async fn main() {
    // Complex error handling with direct exits
    // Mixed logic for parsing, validation, and execution
}
```

## Desired Functional Pattern
Convert to this cleaner structure:
```rust
#[tokio::main]
async fn main() {
    match run().await {
        Ok(output) => println!("{}", serde_json::to_string(&output).expect("Serialization failed")),
        Err(e) => {
            eprintln!("{}", serde_json::to_string(&ErrorOutput { success: false, error: e.to_string() }).expect("Serialization failed"));
            std::process::exit(1);
        }
    }
}

async fn run() -> Result<Output, Box<dyn std::error::Error>> {
    // Pure functional logic here
    // All business logic separated from CLI handling
}
```

## Conversion Steps
1. Remove `#[tokio::main]` from the main function
2. Create a new async `run()` function that returns `Result<Output, Box<dyn std::error::Error>>`
3. Move all core logic to the `run()` function
4. Simplify the `main()` function to only handle CLI-specific concerns
5. Use proper error propagation instead of direct exits

## Files to Convert
The binaries in this project are located in `src/bin/` directory.

## Tools to Use
- `./convert_one.sh <binary_name>` - Generates conversion instructions for a specific binary
- `cargo run --bin <binary_name>` - Test the binary after conversion

## Testing
After conversion:
1. Run `cargo build --release` to ensure no compilation errors
2. Run `cargo test` to verify functionality
3. Test with actual Windmill flows if applicable