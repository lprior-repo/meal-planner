//! Common test utilities for integration tests
//!
//! **REFACTORED**: Following Dave Farley's Functional Core / Imperative Shell
//!
//! ## Architecture
//!
//! - **Shell functions** (I/O): Binary execution now delegates to support::binary_runner
//! - **Core functions** (pure, no I/O): validation, parsing, formatting
//!
//! See `tests/helpers/support/*` for modular implementation

use serde_json::{json, Value};
use std::env;
use std::process::Command;

#[derive(Clone, Debug)]
#[allow(dead_code)]
pub struct FatSecretCredentials {
    pub consumer_key: String,
    pub consumer_secret: String,
}

#[derive(Clone, Debug)]
#[allow(dead_code)]
pub struct OAuthTokens {
    pub access_token: String,
    pub access_secret: String,
}

#[derive(Clone, Debug)]
#[allow(dead_code)]
pub struct TandoorCredentials {
    pub base_url: String,
    pub api_token: String,
}

#[allow(dead_code)]
pub fn get_fatsecret_credentials() -> Option<FatSecretCredentials> {
    let consumer_key = get_env_or_pass(
        "FATSECRET_CONSUMER_KEY",
        "meal-planner/fatsecret/consumer_key",
    )?;

    let consumer_secret = get_env_or_pass(
        "FATSECRET_CONSUMER_SECRET",
        "meal-planner/fatsecret/consumer_secret",
    )?;

    Some(FatSecretCredentials {
        consumer_key,
        consumer_secret,
    })
}

#[allow(dead_code)]
pub fn get_oauth_tokens() -> Option<OAuthTokens> {
    let access_token = get_env_or_pass(
        "FATSECRET_ACCESS_TOKEN",
        "meal-planner/fatsecret/access_token",
    )?;

    let access_secret = get_env_or_pass(
        "FATSECRET_ACCESS_SECRET",
        "meal-planner/fatsecret/access_secret",
    )?;

    Some(OAuthTokens {
        access_token,
        access_secret,
    })
}

#[allow(dead_code)]
pub fn get_tandoor_credentials() -> Option<TandoorCredentials> {
    let base_url = env::var("TANDOOR_BASE_URL")
        .ok()
        .unwrap_or_else(|| "http://localhost:8090".to_string());

    let api_token = get_env_or_pass("TANDOOR_API_TOKEN", "meal-planner/tandoor/api_token")?;

    Some(TandoorCredentials {
        base_url,
        api_token,
    })
}

#[allow(dead_code)]
pub fn skip_if_no_credentials() {
    if get_fatsecret_credentials().is_none() && get_tandoor_credentials().is_none() {
        println!("Skipping: No credentials available (set env vars or configure pass)");
    }
}

#[allow(dead_code)]
pub fn get_pass_value(path: &str) -> Option<String> {
    let output = Command::new("pass").args(["show", path]).output().ok()?;
    String::from_utf8(output.stdout)
        .ok()?
        .trim()
        .to_string()
        .into()
}

impl FatSecretCredentials {
    #[allow(dead_code)]
    pub fn to_json(&self) -> Value {
        json!({
            "consumer_key": self.consumer_key,
            "consumer_secret": self.consumer_secret,
        })
    }
}

impl TandoorCredentials {
    #[allow(dead_code)]
    pub fn to_json(&self) -> Value {
        json!({
            "base_url": self.base_url,
            "api_token": self.api_token,
        })
    }
}

fn get_env_or_pass(env_var: &str, pass_path: &str) -> Option<String> {
    env::var(env_var).ok().or_else(|| get_pass_value(pass_path))
}

#[deprecated(note = "Use tests/helpers/support/binary_runner::run_binary instead")]
#[allow(dead_code)]
pub fn run_binary(binary_name: &str, input: &Value) -> Result<Value, String> {
    let binary_path = format!("./target/debug/{}", binary_name);
    if !std::path::Path::new(&binary_path).exists() {
        return Err(format!("Binary not found: {}", binary_path));
    }

    let mut child = std::process::Command::new(&binary_path)
        .stdin(std::process::Stdio::piped())
        .stdout(std::process::Stdio::piped())
        .stderr(std::process::Stdio::piped())
        .spawn()
        .map_err(|e| format!("Failed to spawn {}: {}", binary_name, e))?;

    if let Some(ref mut stdin) = child.stdin {
        stdin
            .write_all(input.to_string().as_bytes())
            .map_err(|e| format!("Failed to write stdin: {}", e))?;
    }

    let output = child
        .wait_with_output()
        .map_err(|e| format!("Failed to wait for {}: {}", binary_name, e))?;

    let exit_code = output.status.code().unwrap_or(-1);
    let stdout = String::from_utf8_lossy(&output.stdout);

    if !output.status.success() {
        return Err(format!(
            "Binary {} exited with {}: {}",
            binary_name, exit_code, stdout
        ));
    }

    serde_json::from_str(&stdout).map_err(|e| {
        format!(
            "Failed to parse JSON from {}: {} (output: {})",
            binary_name, e, stdout
        )
    })
}

#[deprecated(note = "Use tests/helpers/support/binary_runner::run_with_exit_code instead")]
#[allow(dead_code)]
pub fn run_with_exit_code(binary_name: &str, input: &Value) -> Result<(Value, i32), String> {
    run_binary(binary_name, input).map(|v| (v, 0))
}

#[deprecated(note = "Use tests/helpers/support/binary_runner::binary_exists instead")]
#[allow(dead_code)]
pub fn binary_exists(binary_name: &str) -> bool {
    let paths = [
        format!("./bin/{}", binary_name),
        format!("target/debug/{}", binary_name),
        format!("target/release/{}", binary_name),
    ];
    paths.iter().any(|p| std::path::Path::new(p).exists())
}

#[deprecated(note = "Use tests/helpers/support/binary_runner::expect_success instead")]
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

#[deprecated(note = "Use tests/helpers/support/binary_runner::expect_failure instead")]
#[allow(dead_code)]
pub fn expect_failure(binary_name: &str, input: &Value) {
    let result = run_binary(binary_name, input);
    assert!(
        result.is_ok(),
        "Binary {} should fail gracefully",
        binary_name
    );
}

#[deprecated(note = "Use tests/helpers/support/binary_runner::validate_binary_path instead")]
#[allow(dead_code)]
pub fn find_binary_path(binary_name: &str) -> Result<String, String> {
    let paths = [
        format!("./bin/{}", binary_name),
        format!("target/debug/{}", binary_name),
        format!("target/release/{}", binary_name),
    ];
    paths
        .into_iter()
        .find(|p| std::path::Path::new(p).exists())
        .ok_or_else(|| format!("Binary {} not found", binary_name))
}
