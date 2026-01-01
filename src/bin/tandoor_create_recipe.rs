//! Create recipe in Tandoor from scraped data
//!
//! JSON stdin:
//!   {"tandoor": {...}, "recipe": {...}, "`additional_keywords"`: `["tag1", "tag2"]`}
//!
//! JSON stdout:
//!   {"success": true, "`recipe_id`": 123, "name": "..."}
//!   {"success": false, "error": "..."}

// CLI binaries: exit and JSON unwrap are acceptable at the top level
#![allow(clippy::exit, clippy::unwrap_used)]
#![allow(clippy::too_many_lines)]

use meal_planner::tandoor::{
    CreateFoodRequest, CreateIngredientRequest, CreateKeywordRequest, CreateRecipeRequest,
    CreateStepRequest, CreateUnitRequest, SourceImportRecipe, TandoorClient, TandoorConfig,
};
use serde::{Deserialize, Serialize};
use std::io::{self, Read};

#[derive(Deserialize)]
struct Input {
    tandoor: TandoorConfig,
    recipe: SourceImportRecipe,
    #[serde(default)]
    additional_keywords: Vec<String>,
}

#[derive(Serialize)]
struct Output {
    success: bool,
    #[serde(skip_serializing_if = "Option::is_none")]
    recipe_id: Option<i64>,
    #[serde(skip_serializing_if = "Option::is_none")]
    name: Option<String>,
    #[serde(skip_serializing_if = "Option::is_none")]
    error: Option<String>,
}

fn main() {
    let output = match run() {
        Ok(o) => o,
        Err(e) => Output {
            success: false,
            recipe_id: None,
            name: None,
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

    // Build keywords from scraped + additional
    let mut keywords: Vec<CreateKeywordRequest> = parsed
        .recipe
        .keywords
        .iter()
        .map(|k| CreateKeywordRequest {
            name: k.name.clone(),
        })
        .collect();

    for kw in parsed.additional_keywords {
        keywords.push(CreateKeywordRequest { name: kw });
    }

    // Build steps with ingredients
    let steps: Vec<CreateStepRequest> = parsed
        .recipe
        .steps
        .iter()
        .map(|s| {
            let ingredients: Vec<CreateIngredientRequest> = s
                .ingredients
                .iter()
                .filter_map(|i| {
                    let food = i.food.as_ref()?;
                    // Unit: use provided unit, or "piece" as default for unit-less items
                    let unit_name = i
                        .unit
                        .as_ref()
                        .map(|u| u.name.clone())
                        .filter(|n| !n.is_empty())
                        .unwrap_or_else(|| "piece".to_string());

                    Some(CreateIngredientRequest {
                        amount: i.amount,
                        food: CreateFoodRequest {
                            name: food.name.clone(),
                        },
                        unit: Some(CreateUnitRequest { name: unit_name }),
                        note: if i.note.is_empty() {
                            None
                        } else {
                            Some(i.note.clone())
                        },
                    })
                })
                .collect();

            CreateStepRequest {
                instruction: s.instruction.clone(),
                // Always include ingredients array (even if empty) for Tandoor API
                ingredients: Some(ingredients),
            }
        })
        .collect();

    let request = CreateRecipeRequest {
        name: parsed.recipe.name.clone(),
        description: if parsed.recipe.description.is_empty() {
            None
        } else {
            Some(parsed.recipe.description.clone())
        },
        source_url: parsed.recipe.source_url.clone(),
        servings: Some(parsed.recipe.servings),
        working_time: if parsed.recipe.working_time > 0 {
            Some(parsed.recipe.working_time)
        } else {
            None
        },
        waiting_time: if parsed.recipe.waiting_time > 0 {
            Some(parsed.recipe.waiting_time)
        } else {
            None
        },
        keywords: if keywords.is_empty() {
            None
        } else {
            Some(keywords)
        },
        steps: if steps.is_empty() { None } else { Some(steps) },
    };

    let created = client.create_recipe(&request)?;

    Ok(Output {
        success: true,
        recipe_id: Some(created.id),
        name: Some(created.name),
        error: None,
    })
}
