//! BEAD-002: Foundation Binary --help Flag Tests
//!
//! Test that foundation binaries (generate_encryption_key, validate_encryption,
//! tandoor_test_connection) properly handle --help, -h, and help flags.
//!
//! Test-Driven Development approach:
//! 1. Write tests first (this file)
//! 2. Implement --help functionality in each binary
//! 3. Verify all tests pass
//!
//! ## Test Coverage
//! - All three flags (--help, -h, help) work identically
//! - Output is human-readable text, not JSON
//! - Exit code is 0
//! - Required sections present: USAGE, INPUT SCHEMA, OUTPUT SCHEMA, EXAMPLES, EXIT CODES, NOTES
//! - No JSON output when help flags are used
//! - Normal JSON operation still works (stdin without help flags)

#![allow(clippy::unwrap_used, clippy::expect_used)]

use std::io::Write;
use std::process::{Command, Stdio};

/// Check if a binary exists in any of the standard locations
fn binary_exists(binary_name: &str) -> bool {
    let paths = [
        format!("./bin/{}", binary_name),
        format!("target/debug/{}", binary_name),
        format!("target/release/{}", binary_name),
    ];
    paths.iter().any(|p| std::path::Path::new(p).exists())
}

/// Find the path to a binary
fn find_binary_path(binary_name: &str) -> Option<String> {
    let paths = [
        format!("./bin/{}", binary_name),
        format!("target/debug/{}", binary_name),
        format!("target/release/{}", binary_name),
    ];
    paths
        .iter()
        .find(|p| std::path::Path::new(p).exists())
        .map(|s| s.to_string())
}

/// Run binary with command-line arguments (not stdin)
fn run_binary_with_args(binary_name: &str, args: &[&str]) -> (String, String, i32) {
    let binary_path = find_binary_path(binary_name).expect("Binary not found");

    let output = Command::new(&binary_path)
        .args(args)
        .output()
        .expect("Failed to execute binary");

    let stdout = String::from_utf8_lossy(&output.stdout).to_string();
    let stderr = String::from_utf8_lossy(&output.stderr).to_string();
    let exit_code = output.status.code().unwrap_or(-1);

    (stdout, stderr, exit_code)
}

/// Run binary with JSON stdin (normal operation)
fn run_binary_with_stdin(binary_name: &str, input: &str) -> (String, String, i32) {
    let binary_path = find_binary_path(binary_name).expect("Binary not found");

    let mut child = Command::new(&binary_path)
        .stdin(Stdio::piped())
        .stdout(Stdio::piped())
        .stderr(Stdio::piped())
        .spawn()
        .expect("Failed to spawn binary");

    if let Some(ref mut stdin) = child.stdin {
        stdin
            .write_all(input.as_bytes())
            .expect("Failed to write stdin");
    }

    let output = child.wait_with_output().expect("Failed to wait for binary");
    let stdout = String::from_utf8_lossy(&output.stdout).to_string();
    let stderr = String::from_utf8_lossy(&output.stderr).to_string();
    let exit_code = output.status.code().unwrap_or(-1);

    (stdout, stderr, exit_code)
}

/// Verify help output contains all required sections
fn verify_help_sections(help_text: &str, binary_name: &str) {
    let required_sections = [
        "USAGE",
        "INPUT SCHEMA",
        "OUTPUT SCHEMA",
        "EXAMPLES",
        "EXIT CODES",
        "NOTES",
    ];

    for section in &required_sections {
        assert!(
            help_text.contains(section),
            "{} help output missing required section: {}",
            binary_name,
            section
        );
    }
}

/// Verify output is NOT JSON
fn verify_not_json(output: &str, binary_name: &str) {
    // Help text should not start with { or [ (JSON indicators)
    let trimmed = output.trim();
    assert!(
        !trimmed.starts_with('{') && !trimmed.starts_with('['),
        "{} help output should be text, not JSON. Got: {}",
        binary_name,
        &trimmed[..trimmed.len().min(100)]
    );
}

// ============================================================================
// generate_encryption_key Tests
// ============================================================================

#[test]
fn generate_encryption_key_help_flag() {
    if !binary_exists("generate_encryption_key") {
        eprintln!("Skipping: generate_encryption_key binary not found");
        return;
    }

    let (stdout, _stderr, exit_code) = run_binary_with_args("generate_encryption_key", &["--help"]);

    assert_eq!(exit_code, 0, "Exit code should be 0 for --help");
    verify_not_json(&stdout, "generate_encryption_key");
    verify_help_sections(&stdout, "generate_encryption_key");
}

#[test]
fn generate_encryption_key_h_flag() {
    if !binary_exists("generate_encryption_key") {
        eprintln!("Skipping: generate_encryption_key binary not found");
        return;
    }

    let (stdout_help, _, _) = run_binary_with_args("generate_encryption_key", &["--help"]);
    let (stdout_h, _stderr, exit_code) = run_binary_with_args("generate_encryption_key", &["-h"]);

    assert_eq!(exit_code, 0, "Exit code should be 0 for -h");
    assert_eq!(
        stdout_help, stdout_h,
        "-h output should be identical to --help"
    );
}

#[test]
fn generate_encryption_key_help_argument() {
    if !binary_exists("generate_encryption_key") {
        eprintln!("Skipping: generate_encryption_key binary not found");
        return;
    }

    let (stdout_help, _, _) = run_binary_with_args("generate_encryption_key", &["--help"]);
    let (stdout_arg, _stderr, exit_code) = run_binary_with_args("generate_encryption_key", &["help"]);

    assert_eq!(exit_code, 0, "Exit code should be 0 for help argument");
    assert_eq!(
        stdout_help, stdout_arg,
        "help argument output should be identical to --help"
    );
}

#[test]
fn generate_encryption_key_normal_json_operation() {
    if !binary_exists("generate_encryption_key") {
        eprintln!("Skipping: generate_encryption_key binary not found");
        return;
    }

    // Normal operation with no arguments should produce JSON
    let (stdout, _stderr, exit_code) = run_binary_with_stdin("generate_encryption_key", "{}");

    // Should succeed
    assert_eq!(exit_code, 0, "Normal operation should succeed");

    // Output should be valid JSON
    let json_result: Result<serde_json::Value, _> = serde_json::from_str(&stdout);
    assert!(
        json_result.is_ok(),
        "Normal operation should return JSON, got: {}",
        stdout
    );
}

// ============================================================================
// validate_encryption Tests
// ============================================================================

#[test]
fn validate_encryption_help_flag() {
    if !binary_exists("validate_encryption") {
        eprintln!("Skipping: validate_encryption binary not found");
        return;
    }

    let (stdout, _stderr, exit_code) = run_binary_with_args("validate_encryption", &["--help"]);

    assert_eq!(exit_code, 0, "Exit code should be 0 for --help");
    verify_not_json(&stdout, "validate_encryption");
    verify_help_sections(&stdout, "validate_encryption");
}

#[test]
fn validate_encryption_h_flag() {
    if !binary_exists("validate_encryption") {
        eprintln!("Skipping: validate_encryption binary not found");
        return;
    }

    let (stdout_help, _, _) = run_binary_with_args("validate_encryption", &["--help"]);
    let (stdout_h, _stderr, exit_code) = run_binary_with_args("validate_encryption", &["-h"]);

    assert_eq!(exit_code, 0, "Exit code should be 0 for -h");
    assert_eq!(
        stdout_help, stdout_h,
        "-h output should be identical to --help"
    );
}

#[test]
fn validate_encryption_help_argument() {
    if !binary_exists("validate_encryption") {
        eprintln!("Skipping: validate_encryption binary not found");
        return;
    }

    let (stdout_help, _, _) = run_binary_with_args("validate_encryption", &["--help"]);
    let (stdout_arg, _stderr, exit_code) = run_binary_with_args("validate_encryption", &["help"]);

    assert_eq!(exit_code, 0, "Exit code should be 0 for help argument");
    assert_eq!(
        stdout_help, stdout_arg,
        "help argument output should be identical to --help"
    );
}

#[test]
fn validate_encryption_normal_json_operation() {
    if !binary_exists("validate_encryption") {
        eprintln!("Skipping: validate_encryption binary not found");
        return;
    }

    // Normal operation with JSON input
    let (stdout, _stderr, _exit_code) = run_binary_with_stdin("validate_encryption", r#"{"detailed": false}"#);

    // Output should be valid JSON (might fail due to missing env var, but should be JSON)
    let json_result: Result<serde_json::Value, _> = serde_json::from_str(&stdout);
    if json_result.is_err() {
        // Check stderr for JSON error message
        let (_stdout2, stderr2, _) = run_binary_with_stdin("validate_encryption", r#"{"detailed": false}"#);
        let stderr_json: Result<serde_json::Value, _> = serde_json::from_str(&stderr2);
        assert!(
            stderr_json.is_ok(),
            "Normal operation should return JSON (stdout or stderr), got stdout: {}, stderr: {}",
            stdout,
            stderr2
        );
    }
}

// ============================================================================
// tandoor_test_connection Tests
// ============================================================================

#[test]
fn tandoor_test_connection_help_flag() {
    if !binary_exists("tandoor_test_connection") {
        eprintln!("Skipping: tandoor_test_connection binary not found");
        return;
    }

    let (stdout, _stderr, exit_code) = run_binary_with_args("tandoor_test_connection", &["--help"]);

    assert_eq!(exit_code, 0, "Exit code should be 0 for --help");
    verify_not_json(&stdout, "tandoor_test_connection");
    verify_help_sections(&stdout, "tandoor_test_connection");
}

#[test]
fn tandoor_test_connection_h_flag() {
    if !binary_exists("tandoor_test_connection") {
        eprintln!("Skipping: tandoor_test_connection binary not found");
        return;
    }

    let (stdout_help, _, _) = run_binary_with_args("tandoor_test_connection", &["--help"]);
    let (stdout_h, _stderr, exit_code) = run_binary_with_args("tandoor_test_connection", &["-h"]);

    assert_eq!(exit_code, 0, "Exit code should be 0 for -h");
    assert_eq!(
        stdout_help, stdout_h,
        "-h output should be identical to --help"
    );
}

#[test]
fn tandoor_test_connection_help_argument() {
    if !binary_exists("tandoor_test_connection") {
        eprintln!("Skipping: tandoor_test_connection binary not found");
        return;
    }

    let (stdout_help, _, _) = run_binary_with_args("tandoor_test_connection", &["--help"]);
    let (stdout_arg, _stderr, exit_code) = run_binary_with_args("tandoor_test_connection", &["help"]);

    assert_eq!(exit_code, 0, "Exit code should be 0 for help argument");
    assert_eq!(
        stdout_help, stdout_arg,
        "help argument output should be identical to --help"
    );
}

#[test]
fn tandoor_test_connection_normal_json_operation() {
    if !binary_exists("tandoor_test_connection") {
        eprintln!("Skipping: tandoor_test_connection binary not found");
        return;
    }

    // Normal operation with JSON input (will fail due to missing credentials, but should return JSON error)
    let (stdout, stderr, _exit_code) = run_binary_with_stdin("tandoor_test_connection", "{}");

    // Should get JSON error response
    let json_result: Result<serde_json::Value, _> = serde_json::from_str(&stdout);
    if json_result.is_err() {
        // Try stderr
        let stderr_json: Result<serde_json::Value, _> = serde_json::from_str(&stderr);
        assert!(
            stderr_json.is_ok() || stdout.contains("success") || stderr.contains("success"),
            "Normal operation should return JSON error, got stdout: {}, stderr: {}",
            stdout,
            stderr
        );
    }
}
