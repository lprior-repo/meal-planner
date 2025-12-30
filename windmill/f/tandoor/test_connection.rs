//! Verify Tandoor API connection
//!
//! ```cargo
//! [dependencies]
//! anyhow = "1.0"
//! serde = { version = "1.0", features = ["derive"] }
//! serde_json = "1.0"
//! ureq = { version = "2.10", features = ["json"] }
//! ```

use serde::{Deserialize, Serialize};

#[derive(Deserialize)]
pub struct TandoorConfig {
    pub base_url: String,
    pub api_token: String,
}

#[derive(Serialize)]
pub struct Output {
    pub success: bool,
    pub recipe_count: Option<i64>,
    pub message: String,
}

fn main(tandoor: TandoorConfig) -> anyhow::Result<Output> {
    let url = format!("{}/api/recipe/", tandoor.base_url.trim_end_matches('/'));
    
    let resp = ureq::get(&url)
        .set("Authorization", &format!("Bearer {}", tandoor.api_token))
        .call()?
        .into_string()?;
    
    // Try to parse and get count
    let json: serde_json::Value = serde_json::from_str(&resp)?;
    let count = json.get("count").and_then(|v| v.as_i64());
    
    Ok(Output {
        success: true,
        recipe_count: count,
        message: "Connected to Tandoor".to_string(),
    })
}
