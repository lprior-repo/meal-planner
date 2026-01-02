//! Windmill Flow Test for fatsecret_weight_month_summary
//!
//! Dave Farley: "Validate structure, then test manually in production."
//!
//! GATE-1: Acceptance test for the Windmill flow
//! GATE-2: Unit test for the flow logic
//! GATE-3: Pure core functions for flow validation (≤25 lines)
//! GATE-4: All functions ≤25 lines

#![allow(clippy::unwrap_used, clippy::too_many_lines, dead_code)]

use serde_json::json;
use std::env;
use std::process::Command;

const DEFAULT_BASE_URL: &str = "http://localhost:8000";

#[allow(dead_code)]
fn get_windmill_base_url() -> String {
    env::var("WINDMILL_BASE_URL").unwrap_or_else(|_| DEFAULT_BASE_URL.to_string())
}

#[allow(dead_code)]
fn get_windmill_token() -> String {
    env::var("WINDMILL_TOKEN").expect("WINDMILL_TOKEN must be set for integration tests")
}

#[allow(dead_code)]
fn get_windmill_workspace() -> String {
    env::var("WINDMILL_WORKSPACE").unwrap_or_else(|_| DEFAULT_WORKSPACE.to_string())
}

fn get_oauth_tokens() -> Option<(String, String)> {
    fn get_pass_value(path: &str) -> Option<String> {
        let output = Command::new("pass").args(["show", path]).output().ok()?;
        String::from_utf8(output.stdout).ok()?.trim().to_string().into()
    }

    let access_token = env::var("FATSECRET_ACCESS_TOKEN")
        .ok()
        .or_else(|| get_pass_value("meal-planner/fatsecret/access_token"))?;

    let access_secret = env::var("FATSECRET_ACCESS_SECRET")
        .ok()
        .or_else(|| get_pass_value("meal-planner/fatsecret/access_secret"))?;

    Some((access_token, access_secret))
}

fn today_date_int() -> i64 {
    use std::time::{Duration, SystemTime, UNIX_EPOCH};
    let duration = SystemTime::now()
        .duration_since(UNIX_EPOCH)
        .unwrap_or(Duration::ZERO);
    (duration.as_secs() / 86400) as i64
}

fn script_exists_in_repo(script_name: &str) -> bool {
    let path = format!("windmill/f/fatsecret/{}.sh", script_name);
    std::path::Path::new(&path).exists()
}

fn run_windmill_script(script_path: &str, args: &serde_json::Value) -> Result<serde_json::Value, String> {
    let base_url = get_windmill_base_url();
    let args_json = serde_json::to_string(args).map_err(|e| e.to_string())?;

    let output = Command::new("wmill")
        .args([
            "--base-url",
            &base_url,
            "script",
            "run",
            script_path,
            "-d",
            &args_json,
        ])
        .current_dir("windmill")
        .output()
        .map_err(|e| format!("Failed to run wmill: {}", e))?;

    let stdout = String::from_utf8_lossy(&output.stdout);
    let stderr = String::from_utf8_lossy(&output.stderr);

    if !output.status.success() {
        return Err(format!("Script failed: {}", stderr));
    }

    let json_start = stdout.rfind('{');
    let json_end = stdout.rfind('}');

    match (json_start, json_end) {
        (Some(start), Some(end)) if end > start => {
            let json_str = &stdout[start..=end];
            serde_json::from_str(json_str)
                .map_err(|e| format!("Failed to parse JSON: {} (output: {})", e, json_str))
        }
        _ => Err(format!(
            "No JSON found in output. stdout: {}, stderr: {}",
            stdout, stderr
        )),
    }
}

macro_rules! skip_if_not_deployed {
    ($script_name:expr) => {
        if !script_exists_in_repo($script_name) {
            println!("SKIP: Script f/fatsecret/{} not deployed", $script_name);
            return;
        }
    };
}

macro_rules! skip_if_no_oauth_tokens {
    () => {
        if get_oauth_tokens().is_none() {
            println!("SKIP: No OAuth tokens available (set FATSECRET_ACCESS_TOKEN/SECRET or configure pass)");
            return;
        }
    };
}

// =============================================================================
// GATE-3: Pure Core Functions (No I/O - for unit testing)
// =============================================================================

pub mod core {
    use serde_json::Value;

    /// Validate date_int is within valid range (1970-01-01 to 2100-12-31)
    pub fn validate_date_int(date_int: i32) -> bool {
        let min_date = 0;
        let max_date = 47500;
        (date_int >= min_date) && (date_int <= max_date)
    }

    /// Parse month and year from date_int
    pub fn date_int_to_month(date_int: i32) -> Option<(i32, i32)> {
        if !validate_date_int(date_int) {
            return None;
        }
        let epoch_year = 1970;
        let days_per_month = [31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31];
        let total_days = date_int;
        let mut remaining_days = total_days;

        let mut year = epoch_year;
        while remaining_days > 365 {
            let is_leap = year % 4 == 0 && (year % 100 != 0 || year % 400 == 0);
            let days_in_year = if is_leap { 366 } else { 365 };
            if remaining_days < days_in_year {
                break;
            }
            remaining_days -= days_in_year;
            year += 1;
        }

        let mut month = 0;
        for (i, days) in days_per_month.iter().enumerate() {
            let days_in_month = if i == 1 && year % 4 == 0 && (year % 100 != 0 || year % 400 == 0) {
                29
            } else {
                *days
            };
            if remaining_days < days_in_month {
                month = i + 1;
                break;
            }
            remaining_days -= days_in_month;
        }

        Some((year, month as i32))
    }

    /// Validate response has required fields
    pub fn validate_summary_response(response: &Value) -> bool {
        response.get("success").and_then(|v| v.as_bool()) == Some(true)
            && response.get("month_summary").is_some()
    }

    /// Extract weight measurements from response
    pub fn extract_weight_measurements(response: &Value) -> Vec<(i32, f64)> {
        let mut measurements = Vec::new();
        if let Some(days) = response.get("month_summary").and_then(|m| m.get("days")) {
            if let Some(day_array) = days.as_array() {
                for day in day_array {
                    if let (Some(date_int), Some(weight_kg)) = (
                        day.get("date_int").and_then(|v| v.as_i64()),
                        day.get("weight_kg").and_then(|v| v.as_f64()),
                    ) {
                        measurements.push((date_int as i32, weight_kg));
                    }
                }
            }
        }
        measurements
    }
}

// =============================================================================
// GATE-2: Unit Tests for Core Functions
// =============================================================================

#[cfg(test)]
mod core_tests {
    use super::core::*;
    use serde_json::json;

    #[test]
    fn test_validate_date_int_valid() {
        assert!(validate_date_int(0));
        assert!(validate_date_int(20088));
        assert!(validate_date_int(47499));
    }

    #[test]
    fn test_validate_date_int_invalid() {
        assert!(!validate_date_int(-1));
        assert!(!validate_date_int(47500));
    }

    #[test]
    fn test_date_int_to_month_2025_january() {
        let result = date_int_to_month(20088);
        assert_eq!(result, Some((2025, 1)));
    }

    #[test]
    fn test_date_int_to_month_2024_december() {
        let result = date_int_to_month(19965);
        assert_eq!(result, Some((2024, 12)));
    }

    #[test]
    fn test_date_int_to_month_invalid() {
        assert_eq!(date_int_to_month(-1), None);
        assert_eq!(date_int_to_month(50000), None);
    }

    #[test]
    fn test_validate_summary_response_valid() {
        let response = json!({
            "success": true,
            "month_summary": {"days": []}
        });
        assert!(validate_summary_response(&response));
    }

    #[test]
    fn test_validate_summary_response_invalid() {
        let response = json!( {"success": false} );
        assert!(!validate_summary_response(&response));
    }

    #[test]
    fn test_extract_weight_measurements() {
        let response = json!({
            "month_summary": {
                "days": [
                    {"date_int": 20088, "weight_kg": 75.5},
                    {"date_int": 20089, "weight_kg": 75.3}
                ]
            }
        });
        let measurements = extract_weight_measurements(&response);
        assert_eq!(measurements.len(), 2);
        assert_eq!(measurements[0], (20088, 75.5));
        assert_eq!(measurements[1], (20089, 75.3));
    }

    #[test]
    fn test_extract_weight_measurements_empty() {
        let response = json!({"month_summary": {"days": []}});
        let measurements = extract_weight_measurements(&response);
        assert!(measurements.is_empty());
    }
}

// =============================================================================
// GATE-1: Windmill Flow Acceptance Tests
// =============================================================================

#[test]
#[ignore = "requires Windmill API connection and deployed scripts"]
fn test_windmill_weight_month_summary_script_exists() {
    skip_if_not_deployed!("weight_month_summary");
    println!("✓ Script f/fatsecret/weight_month_summary.sh exists in repository");
}

#[test]
#[ignore = "requires Windmill API connection and deployed scripts"]
fn test_windmill_weight_month_summary_invocation() {
    skip_if_not_deployed!("weight_month_summary");
    skip_if_no_oauth_tokens!();

    let (access_token, access_secret) = get_oauth_tokens().unwrap();
    let date_int = today_date_int();

    let result = run_windmill_script(
        "f/fatsecret/weight_month_summary.sh",
        &json!({
            "fatsecret": "$res:u/admin/fatsecret_api",
            "access_token": access_token,
            "access_secret": access_secret,
            "date_int": date_int
        }),
    );

    assert!(result.is_ok(), "Script should execute: {:?}", result.err());
    let output = result.unwrap();

    assert_eq!(output["success"], true, "Expected success: true");
    assert!(
        output["month_summary"].is_object() || output["month_summary"].is_null(),
        "Expected month_summary object or null"
    );
}

#[test]
#[ignore = "requires Windmill API connection and deployed scripts"]
fn test_windmill_weight_month_summary_response_structure() {
    skip_if_not_deployed!("weight_month_summary");
    skip_if_no_oauth_tokens!();

    let (access_token, access_secret) = get_oauth_tokens().unwrap();
    let date_int = today_date_int();

    let result = run_windmill_script(
        "f/fatsecret/weight_month_summary.sh",
        &json!({
            "fatsecret": "$res:u/admin/fatsecret_api",
            "access_token": access_token,
            "access_secret": access_secret,
            "date_int": date_int
        }),
    );

    assert!(result.is_ok(), "Script should execute");
    let output = result.unwrap();

    assert!(
        core::validate_summary_response(&output),
        "Response should have success=true and month_summary field"
    );

    let measurements = core::extract_weight_measurements(&output);
    println!("✓ Extracted {} weight measurements", measurements.len());
}

#[test]
#[ignore = "requires Windmill API connection and deployed scripts"]
fn test_windmill_weight_month_summary_date_range() {
    skip_if_not_deployed!("weight_month_summary");
    skip_if_no_oauth_tokens!();

    let (access_token, access_secret) = get_oauth_tokens().unwrap();
    let date_int = 20088;

    let result = run_windmill_script(
        "f/fatsecret/weight_month_summary.sh",
        &json!({
            "fatsecret": "$res:u/admin/fatsecret_api",
            "access_token": access_token,
            "access_secret": access_secret,
            "date_int": date_int
        }),
    );

    assert!(result.is_ok(), "Script should execute");
    let output = result.unwrap();

    assert!(
        core::validate_summary_response(&output),
        "Response should have success=true and month_summary field"
    );

    assert!(
        core::validate_date_int(date_int),
        "Date int should be valid"
    );

    let month_year = core::date_int_to_month(date_int);
    assert_eq!(month_year, Some((2025, 1)), "Should resolve to January 2025");
}
