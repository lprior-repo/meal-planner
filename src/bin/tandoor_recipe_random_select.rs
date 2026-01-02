//! Randomly select recipes from Tandoor by keyword
//!
//! Filters recipes by keyword and randomly selects N recipes.
//!
//! JSON input: {"tandoor": {...}, "keyword": "meat-church", "count": 2}
//! JSON output: {"success": true, "recipes": [...], "error": null}

use meal_planner::tandoor::{RecipeSummary, TandoorClient, TandoorConfig};
use serde::{Deserialize, Serialize};
use std::io::{self, Read};

#[derive(Deserialize)]
struct Input {
    tandoor: TandoorConfig,
    keyword: String,
    #[serde(default)]
    count: u32,
}

#[derive(Serialize)]
struct Output {
    success: bool,
    recipes: Option<Vec<RecipeSummary>>,
    error: Option<String>,
}

fn main() {
    let input = match std::env::args().nth(1) {
        Some(arg) => match serde_json::from_str(&arg) {
            Ok(i) => i,
            Err(_) => match read_stdin() {
                Ok(i) => i,
                Err(e) => {
                    print_error(e);
                    return;
                }
            },
        },
        None => match read_stdin() {
            Ok(i) => i,
            Err(e) => {
                print_error(e);
                return;
            }
        },
    };

    let client = match TandoorClient::new(&input.tandoor) {
        Ok(c) => c,
        Err(e) => {
            print_error(format!("Failed to create Tandoor client: {}", e));
            return;
        }
    };

    let all_recipes = fetch_all_recipes(&client);
    let matching = filter_by_keyword(all_recipes, &input.keyword);
    let selected = random_select(matching, input.count);

    let output = Output {
        success: true,
        recipes: Some(selected),
        error: None,
    };

    if let Ok(json) = serde_json::to_string(&output) {
        println!("{json}");
    }
}

fn read_stdin() -> Result<Input, String> {
    let mut s = String::new();
    io::stdin()
        .read_to_string(&mut s)
        .map_err(|e| format!("Failed to read stdin: {}", e))?;
    serde_json::from_str(&s).map_err(|e| format!("Failed to parse JSON: {}", e))
}

fn fetch_all_recipes(client: &TandoorClient) -> Vec<RecipeSummary> {
    let mut all_recipes = Vec::new();
    let mut page = 1;
    let page_size: u32 = 100;

    while let Ok(paginated) = client.list_recipes(Some(page), Some(page_size)) {
        let count = paginated.results.len();
        all_recipes.extend(paginated.results);
        if count < page_size as usize {
            break;
        }
        page += 1;
    }

    all_recipes
}

fn filter_by_keyword(recipes: Vec<RecipeSummary>, keyword: &str) -> Vec<RecipeSummary> {
    let keyword_lower = keyword.to_lowercase();
    recipes
        .into_iter()
        .filter(|r| {
            r.keywords.as_ref().is_some_and(|kws| {
                kws.iter().any(|kw| {
                    kw.label
                        .as_ref()
                        .is_some_and(|l| l.to_lowercase() == keyword_lower)
                })
            })
        })
        .collect()
}

fn random_select(recipes: Vec<RecipeSummary>, count: u32) -> Vec<RecipeSummary> {
    let count = count as usize;
    let mut rng = fastrand::Rng::new();
    let mut recipes = recipes;
    recipes.sort_by(|_, _| rng.usize(0..2).cmp(&rng.usize(0..2)));
    recipes.into_iter().take(count).collect()
}

fn print_error(msg: String) {
    let output = Output {
        success: false,
        recipes: None,
        error: Some(msg),
    };
    if let Ok(json) = serde_json::to_string(&output) {
        println!("{json}");
    }
}
