//! Common test utilities for integration tests
//!
//! ## Credentials Management
//!
//! Credentials are loaded in this order:
//! 1. Environment variables (`FATSECRET_CONSUMER_KEY`, etc.)
//! 2. `pass` password manager (`meal-planner/fatsecret/consumer_key`, etc.)
//! 3. `pass` password manager (`meal-planner/tandoor/api_token`)

use serde_json::{json, Value};
use std::env;
use std::process::{Command, Stdio};
use std::io::Write;

#[allow(dead_code)]
pub struct FatSecretCredentials {
    pub consumer_key: String,
    pub consumer_secret: String,
}

#[allow(dead_code)]
pub struct OAuthTokens {
    pub access_token: String,
    pub access_secret: String,
}

#[allow(dead_code)]
pub struct TandoorCredentials {
    pub base_url: String,
    pub api_token: String,
}

#[allow(dead_code)]
pub fn get_pass_value(path: &str) -> Option<String> {
    let output = Command::new("pass")
        .args(["show", path])
        .output()
        .ok()?;
    String::from_utf8(output.stdout).ok()?.trim().to_string().into()
}

#[allow(dead_code)]
pub fn get_fatsecret_credentials() -> Option<FatSecretCredentials> {
    let consumer_key = env::var("FATSECRET_CONSUMER_KEY")
        .ok()
        .or_else(|| get_pass_value("meal-planner/fatsecret/consumer_key"))?;

    let consumer_secret = env::var("FATSECRET_CONSUMER_SECRET")
        .ok()
        .or_else(|| get_pass_value("meal-planner/fatsecret/consumer_secret"))?;

    Some(FatSecretCredentials {
        consumer_key,
        consumer_secret,
    })
}

#[allow(dead_code)]
pub fn get_oauth_tokens() -> Option<OAuthTokens> {
    let access_token = env::var("FATSECRET_ACCESS_TOKEN")
        .ok()
        .or_else(|| get_pass_value("meal-planner/fatsecret/access_token"))?;

    let access_secret = env::var("FATSECRET_ACCESS_SECRET")
        .ok()
        .or_else(|| get_pass_value("meal-planner/fatsecret/access_secret"))?;

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

    let api_token = env::var("TANDOOR_API_TOKEN")
        .ok()
        .or_else(|| get_pass_value("meal-planner/tandoor/api_token"))?;

    Some(TandoorCredentials {
        base_url,
        api_token,
    })
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

#[allow(dead_code)]
pub fn run_binary(binary_name: &str, input: &Value) -> Result<Value, String> {
    let binary_path = format!("./target/debug/{}", binary_name);
    if !std::path::Path::new(&binary_path).exists() {
        return Err(format!("Binary not found: {}", binary_path));
    }

    let mut child = Command::new(&binary_path)
        .stdin(Stdio::piped())
        .stdout(Stdio::piped())
        .stderr(Stdio::piped())
        .spawn()
        .map_err(|e| format!("Failed to spawn {}: {}", binary_name, e))?;

    if let Some(ref mut stdin) = child.stdin {
        stdin.write_all(input.to_string().as_bytes())
            .map_err(|e| format!("Failed to write stdin: {}", e))?;
    }

    let output = child.wait_with_output()
        .map_err(|e| format!("Failed to wait for {}: {}", binary_name, e))?;

    let exit_code = output.status.code().unwrap_or(-1);
    let stdout = String::from_utf8_lossy(&output.stdout);

    if !output.status.success() {
        return Err(format!("Binary {} exited with {}: {}", binary_name, exit_code, stdout));
    }

    serde_json::from_str(&stdout)
        .map_err(|e| format!("Failed to parse JSON from {}: {} (output: {})", binary_name, e, stdout))
}

#[allow(dead_code)]
pub fn expect_success(binary_name: &str, input: &Value) -> Value {
    let result = run_binary(binary_name, input);
    assert!(result.is_ok(), "Binary {} should succeed: {:?}", binary_name, result);
    let value = result.unwrap();
    assert!(
        value.get("success").and_then(|v| v.as_bool()).unwrap_or(false),
        "Binary {} should return success: {}",
        binary_name,
        value
    );
    value
}

#[allow(dead_code)]
pub fn expect_failure(binary_name: &str, input: &Value) {
    let result = run_binary(binary_name, input);
    assert!(result.is_ok(), "Binary {} should fail gracefully", binary_name);
}

#[allow(dead_code)]
pub fn skip_if_no_credentials() {
    if get_fatsecret_credentials().is_none() && get_tandoor_credentials().is_none() {
        println!("Skipping: No credentials available (set env vars or configure pass)");
    }
}

#[allow(dead_code)]
pub fn binary_exists(binary_name: &str) -> bool {
    let paths = [
        format!("./bin/{}", binary_name),
        format!("target/debug/{}", binary_name),
        format!("target/release/{}", binary_name),
    ];
    paths.iter().any(|p| std::path::Path::new(p).exists())
}

#[allow(dead_code)]
pub fn run_binary_with_exit_code(binary_name: &str, input: &Value) -> Result<(Value, i32), String> {
    let binary_path = format!("./bin/{}", binary_name);
    if !std::path::Path::new(&binary_path).exists() {
        return Err(format!("Binary not found: {}", binary_path));
    }

    let mut child = Command::new(&binary_path)
        .stdin(Stdio::piped())
        .stdout(Stdio::piped())
        .stderr(Stdio::piped())
        .spawn()
        .map_err(|e| format!("Failed to spawn {}: {}", binary_name, e))?;

    if let Some(ref mut stdin) = child.stdin {
        stdin.write_all(input.to_string().as_bytes())
            .map_err(|e| format!("Failed to write stdin: {}", e))?;
    }

    let output = child.wait_with_output()
        .map_err(|e| format!("Failed to wait for {}: {}", binary_name, e))?;

    let exit_code = output.status.code().unwrap_or(-1);
    let stdout = String::from_utf8_lossy(&output.stdout);

    let json_output: Value = serde_json::from_str(&stdout)
        .map_err(|e| format!("Failed to parse JSON from {}: {} (output: {})", binary_name, e, stdout))?;

    Ok((json_output, exit_code))
}
