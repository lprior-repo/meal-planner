#!/usr/bin/env python3

"""
Binary converter for Rust functional style
This script helps convert Rust binary files to a more functional style
"""

import os
import sys
import re
from pathlib import Path


def convert_binary_to_functional(filepath):
    """Convert a single binary file to functional style"""
    with open(filepath, "r") as f:
        content = f.read()

    filename = os.path.basename(filepath)
    print(f"Converting {filename}...")

    # Create backup
    backup_path = filepath.with_suffix(".rs.backup")
    with open(backup_path, "w") as f:
        f.write(content)
    print(f"Created backup: {backup_path}")

    # Convert to functional style
    new_content = convert_to_functional(content)

    # Write the converted file
    with open(filepath, "w") as f:
        f.write(new_content)

    print(f"Converted {filename} successfully")
    return True


def convert_to_functional(content):
    """Apply functional style conversion to content"""
    lines = content.split("\n")
    new_lines = []

    # Track if we're inside main function
    in_main = False
    main_indent = 0

    # Process each line
    for i, line in enumerate(lines):
        # Check if this is a main function definition
        if re.match(r"^\s*fn\s+main\s*\(\)", line) or re.match(
            r"^\s*\[tokio::main\]", line
        ):
            new_lines.append("// Functional style conversion applied")
            new_lines.append("use serde::{Deserialize, Serialize};")
            new_lines.append("")

            # Add the async version of main
            new_lines.append("#[tokio::main]")
            new_lines.append("async fn main() {")
            new_lines.append("    match run().await {")
            new_lines.append("        Ok(output) => {")
            new_lines.append(
                '            println!("{}", serde_json::to_string(&output).expect("Failed to serialize output JSON"));'
            )
            new_lines.append("        }")
            new_lines.append("        Err(e) => {")
            new_lines.append(
                '            eprintln!("{}", serde_json::to_string(&ErrorOutput { success: false, error: e.to_string() }).expect("Failed to serialize error JSON"));'
            )
            new_lines.append("            std::process::exit(1);")
            new_lines.append("        }")
            new_lines.append("    }")
            new_lines.append("}")
            new_lines.append("")

            # Add the run function
            new_lines.append(
                "async fn run() -> Result<Output, Box<dyn std::error::Error>> {"
            )
            continue

        # Skip lines that are part of main function body (we'll add them to run function)
        if in_main:
            # Look for closing brace to end main function
            if line.strip() == "}":
                in_main = False
                # Add the rest of the content after main
                new_lines.append("    Ok(Output { success: true })")
                new_lines.append("}")
                continue
            else:
                continue  # Skip lines inside main function

        # For now, just preserve most of the content but make it more functional
        new_lines.append(line)

    return "\n".join(new_lines)


def list_binaries():
    """List all binary files"""
    binaries = []
    for root, dirs, files in os.walk("src/bin"):
        for file in files:
            if file.endswith(".rs"):
                binaries.append(os.path.join(root, file))
    return binaries


if __name__ == "__main__":
    if len(sys.argv) < 2:
        print("Usage: python3 convert_binary.py <binary_name>")
        print("Or use --list to see all binaries")
        sys.exit(1)

    action = sys.argv[1]

    if action == "--list":
        binaries = list_binaries()
        print("Available binaries:")
        for binary in binaries:
            print(f"  {os.path.basename(binary)}")
    elif action == "--all":
        binaries = list_binaries()
        for binary in binaries:
            try:
                convert_binary_to_functional(Path(binary))
            except Exception as e:
                print(f"Error converting {binary}: {e}")
    else:
        binary_name = action
        # Find the binary file
        binary_path = f"src/bin/{binary_name}.rs"
        if os.path.exists(binary_path):
            convert_binary_to_functional(Path(binary_path))
        else:
            print(f"Binary not found: {binary_path}")
