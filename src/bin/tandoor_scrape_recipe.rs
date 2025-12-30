//! Scrape recipe from URL via Tandoor API
//!
//! JSON stdin:
//!   {"tandoor": {"base_url": "...", "api_token": "..."}, "url": "https://..."}
//!
//! JSON stdout:
//!   {"success": true, "recipe_json": {...}, "images": [...]}
//!   {"success": false, "error": "..."}

use meal_planner::tandoor::{TandoorClient, TandoorConfig};
use serde::{Deserialize, Serialize};
use std::io::{self, Read};

#[derive(Deserialize)]
struct Input {
    tandoor: TandoorConfig,
    url: String,
}

#[derive(Serialize)]
struct Output {
    success: bool,
    #[serde(skip_serializing_if = "Option::is_none")]
    recipe_json: Option<serde_json::Value>,
    #[serde(skip_serializing_if = "Option::is_none")]
    images: Option<Vec<String>>,
    #[serde(skip_serializing_if = "Option::is_none")]
    error: Option<String>,
}

fn main() {
    let output = match run() {
        Ok(o) => o,
        Err(e) => Output {
            success: false,
            recipe_json: None,
            images: None,
            error: Some(e.to_string()),
        },
    };
    println!("{}", serde_json::to_string(&output).unwrap());
    if !output.success {
        std::process::exit(1);
    }
}

fn run() -> anyhow::Result<Output> {
    let mut input = String::new();
    io::stdin().read_to_string(&mut input)?;

    let parsed: Input = serde_json::from_str(&input)?;
    let client = TandoorClient::new(&parsed.tandoor)?;
    let result = client.scrape_recipe_from_url(&parsed.url)?;

    if result.error {
        return Ok(Output {
            success: false,
            recipe_json: None,
            images: None,
            error: Some(if result.msg.is_empty() {
                "Unknown scraping error".to_string()
            } else {
                result.msg
            }),
        });
    }

    match result.recipe {
        Some(recipe) => Ok(Output {
            success: true,
            recipe_json: Some(serde_json::to_value(recipe)?),
            images: result.images,
            error: None,
        }),
        None => Ok(Output {
            success: false,
            recipe_json: None,
            images: None,
            error: Some("No recipe data returned from scraper".to_string()),
        }),
    }
}
