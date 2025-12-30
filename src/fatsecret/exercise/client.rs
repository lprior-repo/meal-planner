//! FatSecret SDK Exercise API client

use crate::fatsecret::core::config::FatSecretConfig;
use crate::fatsecret::core::errors::FatSecretError;
use crate::fatsecret::core::http::{make_api_request, make_authenticated_request};
use crate::fatsecret::core::oauth::AccessToken;
use crate::fatsecret::exercise::types::{
    Exercise, ExerciseEntriesResponse, ExerciseEntry, ExerciseEntryId, ExerciseEntryInput,
    ExerciseEntryUpdate, ExerciseId, ExerciseMonthSummary, ExerciseMonthSummaryResponse,
    ExerciseResponse, SingleExerciseEntryResponse,
};
use std::collections::HashMap;

/// Get exercise details by ID (exercises.get.v2 - 2-legged)
pub async fn get_exercise(
    config: &FatSecretConfig,
    exercise_id: &ExerciseId,
) -> Result<Exercise, FatSecretError> {
    let mut params = HashMap::new();
    params.insert("exercise_id".to_string(), exercise_id.as_str().to_string());

    let body = make_api_request(config, "exercises.get.v2", params).await?;

    let response: ExerciseResponse = serde_json::from_str(&body).map_err(|e| {
        FatSecretError::ParseError(format!(
            "Failed to parse exercise response: {}. Body: {}",
            e, body
        ))
    })?;

    Ok(response.exercise)
}

/// Get user's exercise entries for a specific date (exercise_entries.get.v2 - 3-legged)
pub async fn get_exercise_entries(
    config: &FatSecretConfig,
    access_token: &AccessToken,
    date_int: i32,
) -> Result<Vec<ExerciseEntry>, FatSecretError> {
    let mut params = HashMap::new();
    params.insert("date".to_string(), date_int.to_string());

    let body =
        make_authenticated_request(config, access_token, "exercise_entries.get.v2", params).await?;

    let response: ExerciseEntriesResponse = serde_json::from_str(&body).map_err(|e| {
        FatSecretError::ParseError(format!(
            "Failed to parse exercise entries response: {}. Body: {}",
            e, body
        ))
    })?;

    Ok(response.exercise_entries)
}

/// Create a new exercise entry
pub async fn create_exercise_entry(
    config: &FatSecretConfig,
    access_token: &AccessToken,
    input: ExerciseEntryInput,
) -> Result<ExerciseEntryId, FatSecretError> {
    let mut params = HashMap::new();
    params.insert(
        "exercise_id".to_string(),
        input.exercise_id.as_str().to_string(),
    );
    params.insert("duration_min".to_string(), input.duration_min.to_string());
    params.insert("date".to_string(), input.date_int.to_string());

    // NOTE: FatSecret uses exercise_entry.edit for BOTH create and update operations.
    let body =
        make_authenticated_request(config, access_token, "exercise_entry.edit", params).await?;

    let response: SingleExerciseEntryResponse = serde_json::from_str(&body).map_err(|e| {
        FatSecretError::ParseError(format!(
            "Failed to parse create exercise entry response: {}. Body: {}",
            e, body
        ))
    })?;

    Ok(response.exercise_entry.exercise_entry_id)
}

/// Edit an existing exercise entry
pub async fn edit_exercise_entry(
    config: &FatSecretConfig,
    access_token: &AccessToken,
    entry_id: &ExerciseEntryId,
    update: ExerciseEntryUpdate,
) -> Result<(), FatSecretError> {
    let mut params = HashMap::new();
    params.insert(
        "exercise_entry_id".to_string(),
        entry_id.as_str().to_string(),
    );

    if let Some(id) = update.exercise_id {
        params.insert("exercise_id".to_string(), id.as_str().to_string());
    }

    if let Some(duration) = update.duration_min {
        params.insert("duration_min".to_string(), duration.to_string());
    }

    make_authenticated_request(config, access_token, "exercise_entry.edit", params).await?;

    Ok(())
}

/// Get monthly exercise summary (exercise_entries.get_month.v2 - 3-legged)
pub async fn get_exercise_month_summary(
    config: &FatSecretConfig,
    access_token: &AccessToken,
    year: i32,
    month: i32,
) -> Result<ExerciseMonthSummary, FatSecretError> {
    let mut params = HashMap::new();
    params.insert("date".to_string(), format!("{}-{}", year, month));

    let body = make_authenticated_request(
        config,
        access_token,
        "exercise_entries.get_month.v2",
        params,
    )
    .await?;

    let response: ExerciseMonthSummaryResponse = serde_json::from_str(&body).map_err(|e| {
        FatSecretError::ParseError(format!(
            "Failed to parse exercise month summary: {}. Body: {}",
            e, body
        ))
    })?;

    Ok(response.exercise_month)
}

/// Delete an exercise entry
pub async fn delete_exercise_entry(
    config: &FatSecretConfig,
    access_token: &AccessToken,
    entry_id: &ExerciseEntryId,
) -> Result<(), FatSecretError> {
    let mut params = HashMap::new();
    params.insert(
        "exercise_entry_id".to_string(),
        entry_id.as_str().to_string(),
    );

    make_authenticated_request(config, access_token, "exercise_entry.delete", params).await?;

    Ok(())
}
