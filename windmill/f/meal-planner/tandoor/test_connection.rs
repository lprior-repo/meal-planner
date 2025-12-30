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
    pub message: String,
}

fn main(tandoor: TandoorConfig) -> anyhow::Result<Output> {
    let url = format!("{}/api/recipe/", tandoor.base_url.trim_end_matches('/'));
    
    let resp = ureq::get(&url)
        .set("Authorization", &format!("Bearer {}", tandoor.api_token))
        .set("Host", "localhost")
        .call()?
        .into_string()?;
    
    Ok(Output {
        success: true,
        message: format!("Connected! Response length: {} chars", resp.len()),
    })
}
