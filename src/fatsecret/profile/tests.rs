//! Unit tests for the `FatSecret` Profile domain

#![allow(clippy::unwrap_used)]
#![allow(clippy::expect_used)]
#![allow(clippy::panic)]

use super::types::*;
use serde_json;

// =============================================================================
// Profile Tests
// =============================================================================

#[test]
fn test_profile_deserialize_full() {
    let json = r#"{
        "profile": {
            "goal_weight_kg": "70.0",
            "last_weight_kg": "75.5",
            "last_weight_date_int": "19723",
            "last_weight_comment": "Morning weigh-in",
            "calorie_goal": "2000",
            "height_cm": "175.0",
            "weight_measure": "kg",
            "height_measure": "cm"
        }
    }"#;
    let response: ProfileResponse = serde_json::from_str(json).expect("should deserialize");
    let profile = &response.profile;

    assert_eq!(profile.goal_weight_kg, Some(70.0));
    assert_eq!(profile.last_weight_kg, Some(75.5));
    assert_eq!(profile.last_weight_date_int, Some(19723));
    assert_eq!(profile.last_weight_comment, Some("Morning weigh-in".to_string()));
    assert_eq!(profile.calorie_goal, Some(2000));
    assert_eq!(profile.height_cm, Some(175.0));
}

#[test]
fn test_profile_deserialize_empty() {
    let json = r#"{"profile": {}}"#;
    let response: ProfileResponse = serde_json::from_str(json).expect("should deserialize");
    let profile = &response.profile;

    assert_eq!(profile.goal_weight_kg, None);
    assert_eq!(profile.last_weight_kg, None);
    assert_eq!(profile.calorie_goal, None);
}

#[test]
fn test_profile_numeric_values() {
    let json = r#"{
        "profile": {
            "goal_weight_kg": 70.0,
            "last_weight_kg": 75.5,
            "last_weight_date_int": 19723,
            "calorie_goal": 2000,
            "height_cm": 175.0
        }
    }"#;
    let response: ProfileResponse = serde_json::from_str(json).expect("should deserialize");
    let profile = &response.profile;

    assert_eq!(profile.goal_weight_kg, Some(70.0));
    assert_eq!(profile.last_weight_date_int, Some(19723));
}

#[test]
fn test_profile_missing_fields() {
    let json = r#"{
        "profile": {
            "goal_weight_kg": 70.0
        }
    }"#;
    let response: ProfileResponse = serde_json::from_str(json).expect("should deserialize");
    let profile = &response.profile;

    assert_eq!(profile.goal_weight_kg, Some(70.0));
    assert_eq!(profile.last_weight_kg, None);
    assert_eq!(profile.height_cm, None);
}

#[test]
fn test_profile_null_fields() {
    let json = r#"{
        "profile": {
            "goal_weight_kg": null,
            "last_weight_kg": null,
            "calorie_goal": null
        }
    }"#;
    let response: ProfileResponse = serde_json::from_str(json).expect("should deserialize");
    let profile = &response.profile;

    assert_eq!(profile.goal_weight_kg, None);
    assert_eq!(profile.last_weight_kg, None);
    assert_eq!(profile.calorie_goal, None);
}

// =============================================================================
// ProfileAuth Tests
// =============================================================================

#[test]
fn test_profile_auth_deserialize() {
    let json = r#"{
        "profile": {
            "auth_token": "token123",
            "auth_secret": "secret456"
        }
    }"#;
    let response: ProfileAuthResponse = serde_json::from_str(json).expect("should deserialize");
    let auth = &response.profile;

    assert_eq!(auth.auth_token, "token123");
    assert_eq!(auth.auth_secret, "secret456");
}

#[test]
fn test_profile_auth_to_access_token() {
    let auth = ProfileAuth {
        auth_token: "token123".to_string(),
        auth_secret: "secret456".to_string(),
    };

    let token = auth.to_access_token();
    assert_eq!(token.token, "token123");
    assert_eq!(token.secret, "secret456");
}

#[test]
fn test_profile_auth_display() {
    let auth = ProfileAuth {
        auth_token: "short".to_string(),
        auth_secret: "secret".to_string(),
    };
    let display = format!("{}", auth);
    assert!(display.contains("ProfileAuth"));
}

// =============================================================================
// ProfileCreateInput Tests
// =============================================================================

#[test]
fn test_profile_create_input() {
    let input = ProfileCreateInput {
        user_id: "user123".to_string(),
    };
    assert_eq!(input.user_id, "user123");
}

#[test]
fn test_profile_create_input_serialize() {
    let input = ProfileCreateInput {
        user_id: "user123".to_string(),
    };
    let json = serde_json::to_string(&input).expect("should serialize");
    assert!(json.contains("user123"));
}

#[test]
fn test_profile_create_input_deserialize() {
    let json = r#"{"user_id": "new_user"}"#;
    let input: ProfileCreateInput = serde_json::from_str(json).expect("should deserialize");
    assert_eq!(input.user_id, "new_user");
}

// =============================================================================
// Clone and Debug Tests
// =============================================================================

#[test]
fn test_profile_clone() {
    let response: ProfileResponse = serde_json::from_str(r#"{"profile": {"goal_weight_kg": 70.0}}"#).expect("should deserialize");
    let cloned = response.profile.clone();
    assert_eq!(response.profile.goal_weight_kg, cloned.goal_weight_kg);
}

#[test]
fn test_profile_auth_clone() {
    let auth = ProfileAuth {
        auth_token: "token".to_string(),
        auth_secret: "secret".to_string(),
    };
    let cloned = auth.clone();
    assert_eq!(auth.auth_token, cloned.auth_token);
    assert_eq!(auth.auth_secret, cloned.auth_secret);
}

#[test]
fn test_profile_debug_format() {
    let response: ProfileResponse = serde_json::from_str(r#"{"profile": {"goal_weight_kg": 70.0}}"#).expect("should deserialize");
    let debug = format!("{:?}", response.profile);
    assert!(debug.contains("Profile"));
}

// =============================================================================
// Edge Cases
// =============================================================================

#[test]
fn test_profile_weight_goal_progress() {
    let profile = Profile {
        goal_weight_kg: Some(70.0),
        last_weight_kg: Some(75.5),
        last_weight_date_int: Some(19723),
        last_weight_comment: None,
        calorie_goal: Some(2000.0),
        height_cm: Some(175.0),
        weight_measure: None,
        height_measure: None,
    };

    if let (Some(goal), Some(current)) = (profile.goal_weight_kg, profile.last_weight_kg) {
        let remaining = goal - current;
        assert!((remaining - (-5.5)).abs() < f64::EPSILON); // 70 - 75.5 = -5.5
    }
}

#[test]
fn test_profile_empty_user_id() {
    let input = ProfileCreateInput {
        user_id: "".to_string(),
    };
    assert!(input.user_id.is_empty());
}

#[test]
fn test_profile_large_values() {
    let json = r#"{
        "profile": {
            "goal_weight_kg": 500.0,
            "calorie_goal": 10000,
            "height_cm": 300.0
        }
    }"#;
    let response: ProfileResponse = serde_json::from_str(json).expect("should deserialize");
    assert_eq!(response.profile.goal_weight_kg, Some(500.0));
}

#[test]
fn test_profile_decimal_values() {
    let json = r#"{
        "profile": {
            "goal_weight_kg": "70.5",
            "last_weight_kg": "75.123"
        }
    }"#;
    let response: ProfileResponse = serde_json::from_str(json).expect("should deserialize");
    assert!((response.profile.goal_weight_kg.unwrap() - 70.5).abs() < f64::EPSILON);
    assert!((response.profile.last_weight_kg.unwrap() - 75.123).abs() < 0.001);
}

// =============================================================================
// Error Cases
// =============================================================================

#[test]
fn test_profile_missing_profile_wrapper() {
    let json = r#"{"goal_weight_kg": 70.0}"#;
    let result: Result<ProfileResponse, _> = serde_json::from_str(json);
    assert!(result.is_err());
}
