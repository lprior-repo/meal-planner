//! FatSecret SDK Food Diary API client
//!
//! 3-legged authenticated API calls for food diary management.
//! All operations require user OAuth access token.

use std::collections::HashMap;

use crate::fatsecret::core::{AccessToken, FatSecretConfig, FatSecretError};

use super::types::{
    DaySummary, FoodEntry, FoodEntryId, FoodEntryInput, FoodEntryUpdate, MealType, MonthSummary,
};

// ============================================================================
// HTTP Client Module (internal)
// ============================================================================

mod http {
    use super::*;
    use base64::Engine;
    use ring::hmac;
    use std::time::{SystemTime, UNIX_EPOCH};

    /// Generate OAuth nonce (random hex string)
    fn generate_nonce() -> String {
        use ring::rand::{SecureRandom, SystemRandom};
        let rng = SystemRandom::new();
        let mut bytes = [0u8; 16];
        rng.fill(&mut bytes).expect("Failed to generate random bytes");
        hex::encode(bytes)
    }

    /// Get current Unix timestamp in seconds
    fn unix_timestamp() -> u64 {
        SystemTime::now()
            .duration_since(UNIX_EPOCH)
            .expect("Time went backwards")
            .as_secs()
    }

    /// RFC 3986 percent-encoding for OAuth 1.0a
    fn oauth_encode(s: &str) -> String {
        let mut result = String::new();
        for byte in s.bytes() {
            match byte {
                b'A'..=b'Z' | b'a'..=b'z' | b'0'..=b'9' | b'-' | b'.' | b'_' | b'~' => {
                    result.push(byte as char);
                }
                _ => {
                    result.push_str(&format!("%{:02X}", byte));
                }
            }
        }
        result
    }

    /// Create OAuth 1.0a signature base string
    fn create_signature_base_string(
        method: &str,
        url: &str,
        params: &HashMap<String, String>,
    ) -> String {
        let mut sorted_params: Vec<_> = params.iter().collect();
        sorted_params.sort_by(|a, b| a.0.cmp(b.0));

        let params_string: String = sorted_params
            .iter()
            .map(|(k, v)| format!("{}={}", oauth_encode(k), oauth_encode(v)))
            .collect::<Vec<_>>()
            .join("&");

        format!(
            "{}&{}&{}",
            method,
            oauth_encode(url),
            oauth_encode(&params_string)
        )
    }

    /// Create HMAC-SHA1 signature for OAuth 1.0a
    fn create_signature(
        base_string: &str,
        consumer_secret: &str,
        token_secret: Option<&str>,
    ) -> String {
        let signing_key = format!("{}&{}", consumer_secret, token_secret.unwrap_or(""));
        let key = hmac::Key::new(hmac::HMAC_SHA1_FOR_LEGACY_USE_ONLY, signing_key.as_bytes());
        let signature = hmac::sign(&key, base_string.as_bytes());
        base64::engine::general_purpose::STANDARD.encode(signature.as_ref())
    }

    /// Build complete OAuth 1.0a parameter set with signature
    fn build_oauth_params(
        consumer_key: &str,
        consumer_secret: &str,
        method: &str,
        url: &str,
        extra_params: &HashMap<String, String>,
        token: Option<&str>,
        token_secret: Option<&str>,
    ) -> HashMap<String, String> {
        let timestamp = unix_timestamp().to_string();
        let nonce = generate_nonce();

        let mut params = HashMap::new();
        params.insert("oauth_consumer_key".to_string(), consumer_key.to_string());
        params.insert("oauth_signature_method".to_string(), "HMAC-SHA1".to_string());
        params.insert("oauth_timestamp".to_string(), timestamp);
        params.insert("oauth_nonce".to_string(), nonce);
        params.insert("oauth_version".to_string(), "1.0".to_string());

        if let Some(t) = token {
            params.insert("oauth_token".to_string(), t.to_string());
        }

        for (k, v) in extra_params {
            params.insert(k.clone(), v.clone());
        }

        let base_string = create_signature_base_string(method, url, &params);
        let signature = create_signature(&base_string, consumer_secret, token_secret);
        params.insert("oauth_signature".to_string(), signature);

        params
    }

    /// Make 3-legged API request (user data, requires access token)
    pub async fn make_authenticated_request(
        config: &FatSecretConfig,
        access_token: &AccessToken,
        method_name: &str,
        params: HashMap<String, String>,
    ) -> Result<String, FatSecretError> {
        let mut api_params = params;
        api_params.insert("method".to_string(), method_name.to_string());
        api_params.insert("format".to_string(), "json".to_string());

        let url = format!("https://{}/rest/server.api", config.api_host());

        let oauth_params = build_oauth_params(
            &config.consumer_key,
            &config.consumer_secret,
            "POST",
            &url,
            &api_params,
            Some(&access_token.oauth_token),
            Some(&access_token.oauth_token_secret),
        );

        // Build form body
        let body: String = oauth_params
            .iter()
            .map(|(k, v)| format!("{}={}", oauth_encode(k), oauth_encode(v)))
            .collect::<Vec<_>>()
            .join("&");

        let client = reqwest::Client::new();
        let response = client
            .post(&url)
            .header("Content-Type", "application/x-www-form-urlencoded")
            .body(body)
            .send()
            .await
            .map_err(|e| FatSecretError::NetworkError(e.to_string()))?;

        let status = response.status();
        let body = response
            .text()
            .await
            .map_err(|e| FatSecretError::NetworkError(e.to_string()))?;

        if !status.is_success() {
            return Err(FatSecretError::RequestFailed {
                status: status.as_u16(),
                body,
            });
        }

        // Check for API error in response body
        if let Some(err) = crate::fatsecret::core::errors::parse_error_response(&body) {
            return Err(err);
        }

        Ok(body)
    }
}

// ============================================================================
// JSON Deserialization Helpers
// ============================================================================

mod decoders {
    use super::*;
    use serde::Deserialize;

    /// Helper to parse string to f64 (FatSecret returns numbers as strings)
    fn parse_float(s: &str) -> f64 {
        s.parse().unwrap_or(0.0)
    }

    /// Helper to parse string to i32
    fn parse_int(s: &str) -> i32 {
        s.parse().unwrap_or(0)
    }

    /// Raw food entry from API (all values are strings)
    #[derive(Debug, Deserialize)]
    pub(super) struct RawFoodEntry {
        food_entry_id: String,
        food_entry_name: String,
        food_entry_description: String,
        food_id: String,
        serving_id: String,
        number_of_units: String,
        meal: String,
        date_int: String,
        calories: String,
        carbohydrate: String,
        protein: String,
        fat: String,
        #[serde(default)]
        saturated_fat: Option<String>,
        #[serde(default)]
        polyunsaturated_fat: Option<String>,
        #[serde(default)]
        monounsaturated_fat: Option<String>,
        #[serde(default)]
        cholesterol: Option<String>,
        #[serde(default)]
        sodium: Option<String>,
        #[serde(default)]
        potassium: Option<String>,
        #[serde(default)]
        fiber: Option<String>,
        #[serde(default)]
        sugar: Option<String>,
    }

    impl From<RawFoodEntry> for FoodEntry {
        fn from(raw: RawFoodEntry) -> Self {
            FoodEntry {
                food_entry_id: FoodEntryId::new(raw.food_entry_id),
                food_entry_name: raw.food_entry_name,
                food_entry_description: raw.food_entry_description,
                food_id: raw.food_id,
                serving_id: raw.serving_id,
                number_of_units: parse_float(&raw.number_of_units),
                meal: MealType::from_api_string(&raw.meal).unwrap_or(MealType::Snack),
                date_int: parse_int(&raw.date_int),
                calories: parse_float(&raw.calories),
                carbohydrate: parse_float(&raw.carbohydrate),
                protein: parse_float(&raw.protein),
                fat: parse_float(&raw.fat),
                saturated_fat: raw.saturated_fat.as_deref().map(parse_float),
                polyunsaturated_fat: raw.polyunsaturated_fat.as_deref().map(parse_float),
                monounsaturated_fat: raw.monounsaturated_fat.as_deref().map(parse_float),
                cholesterol: raw.cholesterol.as_deref().map(parse_float),
                sodium: raw.sodium.as_deref().map(parse_float),
                potassium: raw.potassium.as_deref().map(parse_float),
                fiber: raw.fiber.as_deref().map(parse_float),
                sugar: raw.sugar.as_deref().map(parse_float),
            }
        }
    }

    /// Raw day summary from API
    #[derive(Debug, Deserialize)]
    pub(super) struct RawDaySummary {
        date_int: String,
        calories: String,
        carbohydrate: String,
        protein: String,
        fat: String,
    }

    impl From<RawDaySummary> for DaySummary {
        fn from(raw: RawDaySummary) -> Self {
            DaySummary {
                date_int: parse_int(&raw.date_int),
                calories: parse_float(&raw.calories),
                carbohydrate: parse_float(&raw.carbohydrate),
                protein: parse_float(&raw.protein),
                fat: parse_float(&raw.fat),
            }
        }
    }

    // Response wrappers
    #[derive(Debug, Deserialize)]
    pub struct FoodEntryResponse {
        pub food_entry: RawFoodEntry,
    }

    #[derive(Debug, Deserialize)]
    #[serde(untagged)]
    #[allow(clippy::large_enum_variant)]
    pub enum FoodEntriesInner {
        Array(Vec<RawFoodEntry>),
        Single(RawFoodEntry),
    }

    #[derive(Debug, Deserialize)]
    pub struct FoodEntriesWrapper {
        #[serde(default)]
        pub food_entry: Option<FoodEntriesInner>,
    }

    #[derive(Debug, Deserialize)]
    pub struct FoodEntriesResponse {
        pub food_entries: FoodEntriesWrapper,
    }

    #[derive(Debug, Deserialize)]
    pub struct FoodEntryIdValue {
        pub value: String,
    }

    #[derive(Debug, Deserialize)]
    pub struct CreateEntryResponse {
        pub food_entry_id: FoodEntryIdValue,
    }

    #[derive(Debug, Deserialize)]
    #[serde(untagged)]
    pub enum DaysInner {
        Array(Vec<RawDaySummary>),
        Single(RawDaySummary),
    }

    #[derive(Debug, Deserialize)]
    pub struct DaysWrapper {
        #[serde(default)]
        pub day: Option<DaysInner>,
    }

    #[derive(Debug, Deserialize)]
    pub struct RawMonthSummary {
        pub month: String,
        pub year: String,
        pub days: DaysWrapper,
    }

    #[derive(Debug, Deserialize)]
    pub struct MonthResponse {
        pub month: RawMonthSummary,
    }

    pub fn parse_food_entry(body: &str) -> Result<FoodEntry, FatSecretError> {
        let response: FoodEntryResponse = serde_json::from_str(body)
            .map_err(|e| FatSecretError::ParseError(format!("Failed to parse food entry: {}", e)))?;
        Ok(response.food_entry.into())
    }

    pub fn parse_food_entries(body: &str) -> Result<Vec<FoodEntry>, FatSecretError> {
        let response: FoodEntriesResponse = serde_json::from_str(body).map_err(|e| {
            FatSecretError::ParseError(format!("Failed to parse food entries: {}", e))
        })?;

        let entries = match response.food_entries.food_entry {
            Some(FoodEntriesInner::Array(entries)) => entries.into_iter().map(Into::into).collect(),
            Some(FoodEntriesInner::Single(entry)) => vec![entry.into()],
            None => vec![],
        };

        Ok(entries)
    }

    pub fn parse_create_response(body: &str) -> Result<FoodEntryId, FatSecretError> {
        let response: CreateEntryResponse = serde_json::from_str(body).map_err(|e| {
            FatSecretError::ParseError(format!("Failed to parse create response: {}", e))
        })?;
        Ok(FoodEntryId::new(response.food_entry_id.value))
    }

    pub fn parse_month_summary(body: &str) -> Result<MonthSummary, FatSecretError> {
        let response: MonthResponse = serde_json::from_str(body).map_err(|e| {
            FatSecretError::ParseError(format!("Failed to parse month summary: {}", e))
        })?;

        let days = match response.month.days.day {
            Some(DaysInner::Array(days)) => days.into_iter().map(Into::into).collect(),
            Some(DaysInner::Single(day)) => vec![day.into()],
            None => vec![],
        };

        Ok(MonthSummary {
            days,
            month: parse_int(&response.month.month),
            year: parse_int(&response.month.year),
        })
    }
}

// ============================================================================
// Public API Functions
// ============================================================================

/// Create a new food entry in the user's diary
///
/// # Arguments
/// * `config` - FatSecret API configuration
/// * `token` - User's OAuth access token
/// * `input` - Food entry input (FromFood or Custom)
///
/// # Returns
/// The ID of the newly created food entry
pub async fn create_food_entry(
    config: &FatSecretConfig,
    token: &AccessToken,
    input: FoodEntryInput,
) -> Result<FoodEntryId, FatSecretError> {
    let params = match input {
        FoodEntryInput::FromFood {
            food_id,
            food_entry_name,
            serving_id,
            number_of_units,
            meal,
            date_int,
        } => {
            let mut p = HashMap::new();
            p.insert("food_id".to_string(), food_id);
            p.insert("food_entry_name".to_string(), food_entry_name);
            p.insert("serving_id".to_string(), serving_id);
            p.insert("number_of_units".to_string(), number_of_units.to_string());
            p.insert("meal".to_string(), meal.to_api_string().to_string());
            p.insert("date_int".to_string(), date_int.to_string());
            p
        }
        FoodEntryInput::Custom {
            food_entry_name,
            serving_description,
            number_of_units,
            meal,
            date_int,
            calories,
            carbohydrate,
            protein,
            fat,
        } => {
            let mut p = HashMap::new();
            p.insert("food_entry_name".to_string(), food_entry_name);
            p.insert("serving_description".to_string(), serving_description);
            p.insert("number_of_units".to_string(), number_of_units.to_string());
            p.insert("meal".to_string(), meal.to_api_string().to_string());
            p.insert("date_int".to_string(), date_int.to_string());
            p.insert("calories".to_string(), calories.to_string());
            p.insert("carbohydrate".to_string(), carbohydrate.to_string());
            p.insert("protein".to_string(), protein.to_string());
            p.insert("fat".to_string(), fat.to_string());
            p
        }
    };

    let body = http::make_authenticated_request(config, token, "food_entry.create", params).await?;
    decoders::parse_create_response(&body)
}

/// Get a specific food entry by ID
///
/// # Arguments
/// * `config` - FatSecret API configuration
/// * `token` - User's OAuth access token
/// * `entry_id` - The food entry ID to retrieve
pub async fn get_food_entry(
    config: &FatSecretConfig,
    token: &AccessToken,
    entry_id: &FoodEntryId,
) -> Result<FoodEntry, FatSecretError> {
    let mut params = HashMap::new();
    params.insert("food_entry_id".to_string(), entry_id.as_str().to_string());

    let body = http::make_authenticated_request(config, token, "food_entry.get", params).await?;
    decoders::parse_food_entry(&body)
}

/// Get all food entries for a specific date
///
/// # Arguments
/// * `config` - FatSecret API configuration
/// * `token` - User's OAuth access token
/// * `date_int` - Date as days since Unix epoch (0 = 1970-01-01)
///
/// # Returns
/// List of food entries for that date (empty if none)
pub async fn get_food_entries(
    config: &FatSecretConfig,
    token: &AccessToken,
    date_int: i32,
) -> Result<Vec<FoodEntry>, FatSecretError> {
    let mut params = HashMap::new();
    params.insert("date_int".to_string(), date_int.to_string());

    let body = http::make_authenticated_request(config, token, "food_entries.get", params).await?;
    decoders::parse_food_entries(&body)
}

/// Edit an existing food entry
///
/// # Arguments
/// * `config` - FatSecret API configuration
/// * `token` - User's OAuth access token
/// * `entry_id` - The food entry ID to edit
/// * `update` - The fields to update (number_of_units and/or meal)
pub async fn edit_food_entry(
    config: &FatSecretConfig,
    token: &AccessToken,
    entry_id: &FoodEntryId,
    update: FoodEntryUpdate,
) -> Result<(), FatSecretError> {
    let mut params = HashMap::new();
    params.insert("food_entry_id".to_string(), entry_id.as_str().to_string());

    if let Some(units) = update.number_of_units {
        params.insert("number_of_units".to_string(), units.to_string());
    }

    if let Some(meal) = update.meal {
        params.insert("meal".to_string(), meal.to_api_string().to_string());
    }

    http::make_authenticated_request(config, token, "food_entry.edit", params).await?;
    Ok(())
}

/// Delete a food entry
///
/// # Arguments
/// * `config` - FatSecret API configuration
/// * `token` - User's OAuth access token
/// * `entry_id` - The food entry ID to delete
pub async fn delete_food_entry(
    config: &FatSecretConfig,
    token: &AccessToken,
    entry_id: &FoodEntryId,
) -> Result<(), FatSecretError> {
    let mut params = HashMap::new();
    params.insert("food_entry_id".to_string(), entry_id.as_str().to_string());

    http::make_authenticated_request(config, token, "food_entry.delete", params).await?;
    Ok(())
}

/// Get monthly summary of food entries
///
/// # Arguments
/// * `config` - FatSecret API configuration
/// * `token` - User's OAuth access token
/// * `date_int` - Any date within the desired month (days since epoch)
///
/// # Returns
/// Monthly summary with daily nutrition totals
pub async fn get_month_summary(
    config: &FatSecretConfig,
    token: &AccessToken,
    date_int: i32,
) -> Result<MonthSummary, FatSecretError> {
    let mut params = HashMap::new();
    params.insert("date_int".to_string(), date_int.to_string());

    let body =
        http::make_authenticated_request(config, token, "food_entries.get_month", params).await?;
    decoders::parse_month_summary(&body)
}

// ============================================================================
// Copy/Template Operations
// ============================================================================

/// Copy all food entries from one date to another
///
/// FatSecret API: food_entry.copy
pub async fn copy_entries(
    config: &FatSecretConfig,
    token: &AccessToken,
    from_date_int: i32,
    to_date_int: i32,
) -> Result<(), FatSecretError> {
    let mut params = HashMap::new();
    params.insert("from_date_int".to_string(), from_date_int.to_string());
    params.insert("to_date_int".to_string(), to_date_int.to_string());

    http::make_authenticated_request(config, token, "food_entry.copy", params).await?;
    Ok(())
}

/// Copy entries for a specific meal from one date/meal to another
///
/// FatSecret API: food_entry.copy_meal
pub async fn copy_meal(
    config: &FatSecretConfig,
    token: &AccessToken,
    from_date_int: i32,
    from_meal: MealType,
    to_date_int: i32,
    to_meal: MealType,
) -> Result<(), FatSecretError> {
    let mut params = HashMap::new();
    params.insert("from_date_int".to_string(), from_date_int.to_string());
    params.insert("from_meal".to_string(), from_meal.to_api_string().to_string());
    params.insert("to_date_int".to_string(), to_date_int.to_string());
    params.insert("to_meal".to_string(), to_meal.to_api_string().to_string());

    http::make_authenticated_request(config, token, "food_entry.copy_meal", params).await?;
    Ok(())
}

/// Commit/finalize a day's diary entries
///
/// FatSecret API: food_entry.commit_day
pub async fn commit_day(
    config: &FatSecretConfig,
    token: &AccessToken,
    date_int: i32,
) -> Result<(), FatSecretError> {
    let mut params = HashMap::new();
    params.insert("date_int".to_string(), date_int.to_string());

    http::make_authenticated_request(config, token, "food_entry.commit_day", params).await?;
    Ok(())
}

/// Save a day's entries as a reusable template
///
/// FatSecret API: food_entry.save_template
pub async fn save_template(
    config: &FatSecretConfig,
    token: &AccessToken,
    date_int: i32,
    template_name: &str,
) -> Result<(), FatSecretError> {
    let mut params = HashMap::new();
    params.insert("date_int".to_string(), date_int.to_string());
    params.insert("template_name".to_string(), template_name.to_string());

    http::make_authenticated_request(config, token, "food_entry.save_template", params).await?;
    Ok(())
}
