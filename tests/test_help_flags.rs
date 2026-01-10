//! BEAD-008: Test Suite for --help Flags
//!
//! This test suite validates that all foundation binaries properly implement --help flags.
//!
//! Test Cases:
//! 1. All binaries support --help → exit 0, output is text (not JSON)
//! 2. --help output contains "USAGE" section
//! 3. --help output contains "EXAMPLES" section
//! 4. --help is not JSON (jq parse should fail)
//! 5. -h flag works identically to --help
//! 6. help flag works identically to --help
//!
//! Binaries Tested:
//! - generate_encryption_key
//! - validate_encryption
//! - tandoor_test_connection
//! - sync_meal_plan
//! - log_recipe_to_fatsecret
//! - analyze_nutrition
//! - track_exercise_balance
//!
//! Run with: cargo test --test test_help_flags

#![allow(clippy::unwrap_used, clippy::indexing_slicing, clippy::panic)]

use std::path::PathBuf;
use std::process::{Command, Output};

/// Foundation binaries that must implement --help flags
const FOUNDATION_BINARIES: &[&str] = &[
    "generate_encryption_key",
    "validate_encryption",
    "tandoor_test_connection",
    "sync_meal_plan",
    "log_recipe_to_fatsecret",
    "analyze_nutrition",
    "track_exercise_balance",
];

// ========================================
// Helper Functions
// ========================================

/// Get all search paths for a binary
fn get_binary_paths(binary_name: &str) -> Vec<PathBuf> {
    vec![
        PathBuf::from(format!("./bin/{}", binary_name)),
        PathBuf::from(format!("target/debug/{}", binary_name)),
        PathBuf::from(format!("target/release/{}", binary_name)),
    ]
}

/// Find the first existing binary path
fn find_binary(binary_name: &str) -> Option<PathBuf> {
    get_binary_paths(binary_name)
        .into_iter()
        .find(|p| p.exists())
}

/// Execute binary with a specific flag
fn run_with_flag(binary_path: &PathBuf, flag: &str) -> Output {
    Command::new(binary_path)
        .arg(flag)
        .output()
        .expect("Failed to execute binary")
}

/// Check if output is valid JSON
fn is_valid_json(output: &str) -> bool {
    serde_json::from_str::<serde_json::Value>(output).is_ok()
}

/// Check if output contains a section (case-insensitive)
fn contains_section(output: &str, section: &str) -> bool {
    output.to_uppercase().contains(&section.to_uppercase())
}

// ========================================
// Test 1: Binary Existence
// ========================================

#[test]
fn test_all_foundation_binaries_exist() {
    let mut missing = Vec::new();

    for binary in FOUNDATION_BINARIES {
        if find_binary(binary).is_none() {
            missing.push(*binary);
        }
    }

    assert!(
        missing.is_empty(),
        "Missing foundation binaries: {:?}\nRun 'cargo build' to build them.",
        missing
    );
}

// ========================================
// Test 2: --help Flag Support
// ========================================

#[test]
fn test_help_flag_exits_zero() {
    for binary in FOUNDATION_BINARIES {
        let path = find_binary(binary)
            .unwrap_or_else(|| panic!("Binary {} not found. Run 'cargo build'", binary));

        let output = run_with_flag(&path, "--help");

        assert!(
            output.status.success(),
            "Binary {} --help should exit with code 0, got: {:?}",
            binary,
            output.status.code()
        );
    }
}

#[test]
fn test_help_output_is_text_not_json() {
    for binary in FOUNDATION_BINARIES {
        let path = find_binary(binary)
            .unwrap_or_else(|| panic!("Binary {} not found. Run 'cargo build'", binary));

        let output = run_with_flag(&path, "--help");
        let stdout = String::from_utf8_lossy(&output.stdout);

        assert!(
            !is_valid_json(&stdout),
            "Binary {} --help output should be text, not JSON. Output:\n{}",
            binary,
            stdout
        );
    }
}

// ========================================
// Test 3: USAGE Section Present
// ========================================

#[test]
fn test_help_contains_usage_section() {
    for binary in FOUNDATION_BINARIES {
        let path = find_binary(binary)
            .unwrap_or_else(|| panic!("Binary {} not found. Run 'cargo build'", binary));

        let output = run_with_flag(&path, "--help");
        let stdout = String::from_utf8_lossy(&output.stdout);

        assert!(
            contains_section(&stdout, "USAGE"),
            "Binary {} --help output should contain 'USAGE' section. Output:\n{}",
            binary,
            stdout
        );
    }
}

// ========================================
// Test 4: EXAMPLES Section Present
// ========================================

#[test]
fn test_help_contains_examples_section() {
    for binary in FOUNDATION_BINARIES {
        let path = find_binary(binary)
            .unwrap_or_else(|| panic!("Binary {} not found. Run 'cargo build'", binary));

        let output = run_with_flag(&path, "--help");
        let stdout = String::from_utf8_lossy(&output.stdout);

        assert!(
            contains_section(&stdout, "EXAMPLES"),
            "Binary {} --help output should contain 'EXAMPLES' section. Output:\n{}",
            binary,
            stdout
        );
    }
}

// ========================================
// Test 5: -h Flag Works
// ========================================

#[test]
fn test_h_flag_exits_zero() {
    for binary in FOUNDATION_BINARIES {
        let path = find_binary(binary)
            .unwrap_or_else(|| panic!("Binary {} not found. Run 'cargo build'", binary));

        let output = run_with_flag(&path, "-h");

        assert!(
            output.status.success(),
            "Binary {} -h should exit with code 0, got: {:?}",
            binary,
            output.status.code()
        );
    }
}

#[test]
fn test_h_flag_identical_to_help() {
    for binary in FOUNDATION_BINARIES {
        let path = find_binary(binary)
            .unwrap_or_else(|| panic!("Binary {} not found. Run 'cargo build'", binary));

        let help_output = run_with_flag(&path, "--help");
        let h_output = run_with_flag(&path, "-h");

        let help_stdout = String::from_utf8_lossy(&help_output.stdout);
        let h_stdout = String::from_utf8_lossy(&h_output.stdout);

        assert_eq!(
            help_stdout, h_stdout,
            "Binary {} -h and --help should produce identical output",
            binary
        );

        assert_eq!(
            help_output.status.code(),
            h_output.status.code(),
            "Binary {} -h and --help should have same exit code",
            binary
        );
    }
}

// ========================================
// Test 6: help Flag Works
// ========================================

#[test]
fn test_help_word_exits_zero() {
    for binary in FOUNDATION_BINARIES {
        let path = find_binary(binary)
            .unwrap_or_else(|| panic!("Binary {} not found. Run 'cargo build'", binary));

        let output = run_with_flag(&path, "help");

        assert!(
            output.status.success(),
            "Binary {} help should exit with code 0, got: {:?}",
            binary,
            output.status.code()
        );
    }
}

#[test]
fn test_help_word_identical_to_help_flag() {
    for binary in FOUNDATION_BINARIES {
        let path = find_binary(binary)
            .unwrap_or_else(|| panic!("Binary {} not found. Run 'cargo build'", binary));

        let help_flag_output = run_with_flag(&path, "--help");
        let help_word_output = run_with_flag(&path, "help");

        let help_flag_stdout = String::from_utf8_lossy(&help_flag_output.stdout);
        let help_word_stdout = String::from_utf8_lossy(&help_word_output.stdout);

        assert_eq!(
            help_flag_stdout, help_word_stdout,
            "Binary {} help and --help should produce identical output",
            binary
        );

        assert_eq!(
            help_flag_output.status.code(),
            help_word_output.status.code(),
            "Binary {} help and --help should have same exit code",
            binary
        );
    }
}

// ========================================
// Test 7: Help Output Format Validation
// ========================================

#[test]
fn test_help_output_is_non_empty() {
    for binary in FOUNDATION_BINARIES {
        let path = find_binary(binary)
            .unwrap_or_else(|| panic!("Binary {} not found. Run 'cargo build'", binary));

        let output = run_with_flag(&path, "--help");
        let stdout = String::from_utf8_lossy(&output.stdout);

        assert!(
            !stdout.trim().is_empty(),
            "Binary {} --help output should not be empty",
            binary
        );

        assert!(
            stdout.len() > 100,
            "Binary {} --help output should be substantial (>100 chars), got {} chars",
            binary,
            stdout.len()
        );
    }
}

#[test]
fn test_help_output_not_json_parseable() {
    for binary in FOUNDATION_BINARIES {
        let path = find_binary(binary)
            .unwrap_or_else(|| panic!("Binary {} not found. Run 'cargo build'", binary));

        let output = run_with_flag(&path, "--help");
        let stdout = String::from_utf8_lossy(&output.stdout);

        // Try parsing as JSON - it should fail
        let parse_result = serde_json::from_str::<serde_json::Value>(&stdout);

        assert!(
            parse_result.is_err(),
            "Binary {} --help output should not be valid JSON. It should be plain text help.",
            binary
        );
    }
}

// ========================================
// Test 8: Help Content Quality
// ========================================

#[test]
fn test_help_contains_binary_name() {
    for binary in FOUNDATION_BINARIES {
        let path = find_binary(binary)
            .unwrap_or_else(|| panic!("Binary {} not found. Run 'cargo build'", binary));

        let output = run_with_flag(&path, "--help");
        let stdout = String::from_utf8_lossy(&output.stdout);

        assert!(
            stdout.contains(binary),
            "Binary {} --help should mention the binary name. Output:\n{}",
            binary,
            stdout
        );
    }
}

#[test]
fn test_help_contains_common_sections() {
    let expected_sections = vec!["USAGE", "EXAMPLES", "INPUT", "OUTPUT"];

    for binary in FOUNDATION_BINARIES {
        let path = find_binary(binary)
            .unwrap_or_else(|| panic!("Binary {} not found. Run 'cargo build'", binary));

        let output = run_with_flag(&path, "--help");
        let stdout = String::from_utf8_lossy(&output.stdout).to_uppercase();

        let mut found_sections = Vec::new();
        let mut missing_sections = Vec::new();

        for section in &expected_sections {
            if stdout.contains(section) {
                found_sections.push(*section);
            } else {
                missing_sections.push(*section);
            }
        }

        // Must have at least USAGE and EXAMPLES
        assert!(
            stdout.contains("USAGE"),
            "Binary {} --help must contain USAGE section",
            binary
        );
        assert!(
            stdout.contains("EXAMPLES"),
            "Binary {} --help must contain EXAMPLES section",
            binary
        );

        // At least one of INPUT/OUTPUT should be present
        assert!(
            stdout.contains("INPUT") || stdout.contains("OUTPUT"),
            "Binary {} --help should contain INPUT or OUTPUT section",
            binary
        );
    }
}

// ========================================
// Test 9: Consistency Checks
// ========================================

#[test]
fn test_all_help_flags_consistent_for_each_binary() {
    for binary in FOUNDATION_BINARIES {
        let path = find_binary(binary)
            .unwrap_or_else(|| panic!("Binary {} not found. Run 'cargo build'", binary));

        let help_output = run_with_flag(&path, "--help");
        let h_output = run_with_flag(&path, "-h");
        let help_word_output = run_with_flag(&path, "help");

        // All should succeed
        assert!(
            help_output.status.success(),
            "Binary {} --help failed",
            binary
        );
        assert!(h_output.status.success(), "Binary {} -h failed", binary);
        assert!(
            help_word_output.status.success(),
            "Binary {} help failed",
            binary
        );

        // All should produce identical output
        let help_stdout = String::from_utf8_lossy(&help_output.stdout);
        let h_stdout = String::from_utf8_lossy(&h_output.stdout);
        let help_word_stdout = String::from_utf8_lossy(&help_word_output.stdout);

        assert_eq!(
            help_stdout, h_stdout,
            "Binary {} --help and -h output mismatch",
            binary
        );
        assert_eq!(
            help_stdout, help_word_stdout,
            "Binary {} --help and help output mismatch",
            binary
        );

        // All should be text, not JSON
        assert!(
            !is_valid_json(&help_stdout),
            "Binary {} help output should be text, not JSON",
            binary
        );
    }
}

// ========================================
// Test 10: Regression Tests
// ========================================

/// Test that binaries with existing --help don't regress
#[test]
fn test_existing_help_implementations() {
    let binaries_with_help = &["generate_encryption_key", "validate_encryption"];

    for binary in binaries_with_help {
        let path = find_binary(binary)
            .unwrap_or_else(|| panic!("Binary {} not found. Run 'cargo build'", binary));

        let output = run_with_flag(&path, "--help");
        assert!(output.status.success(), "Binary {} --help failed", binary);

        let stdout = String::from_utf8_lossy(&output.stdout);

        // These binaries already have comprehensive help
        assert!(
            stdout.len() > 500,
            "Binary {} help should be comprehensive",
            binary
        );
        assert!(
            stdout.contains("USAGE"),
            "Binary {} should have USAGE section",
            binary
        );
        assert!(
            stdout.contains("EXAMPLES"),
            "Binary {} should have EXAMPLES section",
            binary
        );
        assert!(
            stdout.contains("EXIT CODES") || stdout.contains("NOTES"),
            "Binary {} should have additional sections",
            binary
        );
    }
}
