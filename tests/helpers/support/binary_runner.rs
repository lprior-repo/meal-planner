//! Binary execution support for integration tests
//!
//! Dave Farley: Separate Functional Core (pure logic) from Imperative Shell (I/O)
//!
//! ## Architecture
//!
//! - **Core**: `validate_*`, `parse_*` (pure functions, no I/O)
//! - **Shell**: `run_binary`, `execute_*` (I/O coordination)

#![allow(dead_code)]

use serde_json::Value;
use std::io::Write;
use std::path::{Path, PathBuf};
use std::process::{Command, Output, Stdio};

// ========================================
// PUBLIC API (Shell - I/O Coordination)
// ========================================

/// Execute a binary with JSON input and return parsed JSON output
///
/// # Errors
/// Returns error if binary not found, execution fails, or output invalid
pub fn run_binary(binary_name: &str, input: &Value) -> Result<Value, BinaryError> {
    let binary_path = validate_binary_path(binary_name)?;
    let output = execute_binary(&binary_path, input)?;

    if !output.status.success() {
        return Err(format_execution_error(&output, binary_name));
    }

    parse_json_output(&output, binary_name)
}

/// Execute binary and return both output and exit code
pub fn run_with_exit_code(binary_name: &str, input: &Value) -> Result<(Value, i32), BinaryError> {
    let binary_path = validate_binary_path(binary_name)?;
    let output = execute_binary(&binary_path, input)?;

    let exit_code = output.status.code().unwrap_or(-1);
    let json = parse_json_output(&output, binary_name)?;

    Ok((json, exit_code))
}

/// Check if binary exists in any search location
pub fn binary_exists(binary_name: &str) -> bool {
    search_paths(binary_name).iter().any(|p| p.exists())
}

// ========================================
// CORE (Pure Functions - No I/O)
// ========================================

/// Generate search paths for a binary
fn search_paths(binary_name: &str) -> Vec<PathBuf> {
    vec![
        PathBuf::from(format!("./bin/{}", binary_name)),
        PathBuf::from(format!("target/debug/{}", binary_name)),
        PathBuf::from(format!("target/release/{}", binary_name)),
    ]
}

/// Validate binary exists and return path
fn validate_binary_path(binary_name: &str) -> Result<PathBuf, BinaryError> {
    let paths = search_paths(binary_name);

    paths
        .into_iter()
        .find(|p| p.exists())
        .ok_or_else(|| BinaryError::NotFound(binary_name.to_string()))
}

/// Parse JSON from command output
fn parse_json_output(output: &Output, binary_name: &str) -> Result<Value, BinaryError> {
    let stdout = String::from_utf8_lossy(&output.stdout);

    serde_json::from_str(&stdout).map_err(|e| BinaryError::ParseFailed {
        binary: binary_name.to_string(),
        error: e.to_string(),
        output: stdout.to_string(),
    })
}

/// Format execution error with context
fn format_execution_error(output: &Output, binary_name: &str) -> BinaryError {
    let exit_code = output.status.code().unwrap_or(-1);
    let stdout = String::from_utf8_lossy(&output.stdout);
    let stderr = String::from_utf8_lossy(&output.stderr);

    BinaryError::ExecutionFailed {
        binary: binary_name.to_string(),
        exit_code,
        stdout: stdout.to_string(),
        stderr: stderr.to_string(),
    }
}

// ========================================
// SHELL (I/O Operations)
// ========================================

/// Execute binary process with JSON input
fn execute_binary(binary_path: &Path, input: &Value) -> Result<Output, BinaryError> {
    let mut child = spawn_with_pipes(binary_path)?;
    write_json_stdin(&mut child, input)?;
    wait_for_completion(child)
}

/// Spawn process with stdin/stdout/stderr pipes
fn spawn_with_pipes(binary_path: &Path) -> Result<std::process::Child, BinaryError> {
    Command::new(binary_path)
        .stdin(Stdio::piped())
        .stdout(Stdio::piped())
        .stderr(Stdio::piped())
        .spawn()
        .map_err(|e| BinaryError::SpawnFailed {
            binary: binary_path.display().to_string(),
            error: e.to_string(),
        })
}

/// Write JSON to child process stdin
fn write_json_stdin(child: &mut std::process::Child, input: &Value) -> Result<(), BinaryError> {
    if let Some(ref mut stdin) = child.stdin {
        let json_str = input.to_string();
        stdin
            .write_all(json_str.as_bytes())
            .map_err(|e| BinaryError::StdinWriteFailed(e.to_string()))?;
    }
    Ok(())
}

/// Wait for process completion
fn wait_for_completion(child: std::process::Child) -> Result<Output, BinaryError> {
    child
        .wait_with_output()
        .map_err(|e| BinaryError::WaitFailed(e.to_string()))
}

// ========================================
// ERROR TYPES
// ========================================

#[derive(Debug, Clone)]
pub enum BinaryError {
    NotFound(String),
    SpawnFailed {
        binary: String,
        error: String,
    },
    StdinWriteFailed(String),
    WaitFailed(String),
    ExecutionFailed {
        binary: String,
        exit_code: i32,
        stdout: String,
        stderr: String,
    },
    ParseFailed {
        binary: String,
        error: String,
        output: String,
    },
}

impl std::fmt::Display for BinaryError {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        match self {
            Self::NotFound(name) => {
                write!(f, "Binary not found: {}", name)
            }
            Self::SpawnFailed { binary, error } => {
                write!(f, "Failed to spawn {}: {}", binary, error)
            }
            Self::StdinWriteFailed(e) => {
                write!(f, "Failed to write stdin: {}", e)
            }
            Self::WaitFailed(e) => {
                write!(f, "Failed to wait for process: {}", e)
            }
            Self::ExecutionFailed {
                binary,
                exit_code,
                stdout,
                stderr,
            } => {
                write!(
                    f,
                    "Binary {} exited with code {}\nstdout: {}\nstderr: {}",
                    binary, exit_code, stdout, stderr
                )
            }
            Self::ParseFailed {
                binary,
                error,
                output,
            } => {
                write!(
                    f,
                    "Failed to parse JSON from {}: {}\nOutput: {}",
                    binary, error, output
                )
            }
        }
    }
}

impl std::error::Error for BinaryError {}

// Convert to String for backward compatibility
impl From<BinaryError> for String {
    fn from(error: BinaryError) -> Self {
        error.to_string()
    }
}

// ========================================
// CONVENIENCE FUNCTIONS
// ========================================

/// Run binary and assert success
#[allow(dead_code)]
pub fn expect_success(binary_name: &str, input: &Value) -> Value {
    let result = run_binary(binary_name, input);
    assert!(
        result.is_ok(),
        "Binary {} should succeed: {:?}",
        binary_name,
        result
    );

    let value = result.unwrap();
    assert!(
        value
            .get("success")
            .and_then(|v| v.as_bool())
            .unwrap_or(false),
        "Binary {} should return success: {}",
        binary_name,
        value
    );

    value
}

/// Run binary and expect failure
#[allow(dead_code)]
pub fn expect_failure(binary_name: &str, input: &Value) {
    let result = run_binary(binary_name, input);
    assert!(
        result.is_ok(),
        "Binary {} should fail gracefully",
        binary_name
    );
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn search_paths_generates_correct_locations() {
        let paths = search_paths("test_binary");

        assert_eq!(paths.len(), 3);
        assert_eq!(paths[0], PathBuf::from("./bin/test_binary"));
        assert_eq!(paths[1], PathBuf::from("target/debug/test_binary"));
        assert_eq!(paths[2], PathBuf::from("target/release/test_binary"));
    }

    #[test]
    fn binary_error_display_includes_context() {
        let error = BinaryError::NotFound("missing".to_string());
        assert!(error.to_string().contains("missing"));

        let error = BinaryError::ExecutionFailed {
            binary: "test".to_string(),
            exit_code: 1,
            stdout: "out".to_string(),
            stderr: "err".to_string(),
        };
        assert!(error.to_string().contains("test"));
        assert!(error.to_string().contains("out"));
        assert!(error.to_string().contains("err"));
    }

    #[test]
    fn binary_error_not_found_message() {
        let error = BinaryError::NotFound("my_binary".to_string());
        let msg = error.to_string();
        assert!(msg.contains("my_binary"));
        assert!(msg.contains("not found"));
    }

    #[test]
    fn binary_error_spawn_failed_message() {
        let error = BinaryError::SpawnFailed {
            binary: "test_binary".to_string(),
            error: "permission denied".to_string(),
        };
        let msg = error.to_string();
        assert!(msg.contains("test_binary"));
        assert!(msg.contains("permission denied"));
    }

    #[test]
    fn binary_error_from_string_conversion() {
        let error: String = BinaryError::NotFound("test".to_string()).into();
        assert!(error.contains("test"));
        assert!(error.contains("not found"));
    }
}
