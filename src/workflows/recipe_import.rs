//! Recipe import workflow - pure functions only
//!
//! These functions take explicit types and return explicit types.
//! No generic Box<T>, no escape hatches, type system prevents mistakes.

use super::errors::RecipeImportResult;
use super::recipe::{ImportedRecipe, RecipeWithTags, ValidUrl};

/// Step 1: Parse and validate URL
/// Input: &str (untrusted)
/// Output: ValidUrl (trusted, validated)
pub fn validate_url(input: &str) -> RecipeImportResult<ValidUrl> {
    ValidUrl::parse(input)
}

/// Step 2: Prepare recipe with tags
/// Input: ValidUrl + user keywords
/// Output: RecipeWithTags (all fields validated)
pub fn prepare_recipe(
    url: ValidUrl,
    user_keywords: Vec<&str>,
) -> RecipeImportResult<RecipeWithTags> {
    RecipeWithTags::new(url, user_keywords)
}

/// Step 3: Simulate creating recipe in API
/// Real implementation would call Tandoor
/// Input: RecipeWithTags (guaranteed valid)
/// Output: ImportedRecipe (guaranteed valid)
pub fn create_recipe_in_api(
    recipe: RecipeWithTags,
) -> RecipeImportResult<ImportedRecipe> {
    // Simulate API call - in reality this would use http client
    // Mock returns realistic data derived from the input
    let recipe_id = 123i64;
    
    // Generate recipe name from the source tag for more realistic mock behavior
    let recipe_name = format!("Recipe from {}", recipe.source_tag.as_str());
    
    // Use the actual URL from input, not a placeholder
    let source_url = recipe.url.as_str().to_string();
    
    // Preserve all tags from the input
    let tags_applied = recipe.keywords;

    ImportedRecipe::new(recipe_id, recipe_name, source_url, tags_applied)
}

/// Full workflow: from untrusted input to validated output
/// Combines all steps into a single pure function
pub fn import_recipe(
    url: &str,
    keywords: Vec<&str>,
) -> RecipeImportResult<ImportedRecipe> {
    let validated_url = validate_url(url)?;
    let recipe_with_tags = prepare_recipe(validated_url, keywords)?;
    create_recipe_in_api(recipe_with_tags)
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn step_by_step_workflow() {
        // Step 1: Validate URL
        let url = validate_url("https://www.seriouseats.com/recipe").unwrap();

        // Step 2: Prepare recipe
        let recipe = prepare_recipe(url, vec!["quick", "dinner"]).unwrap();
        assert_eq!(recipe.keywords.len(), 3);

        // Step 3: Create in API
        let imported = create_recipe_in_api(recipe).unwrap();
        assert!(imported.id > 0);
        assert!(!imported.name.is_empty());
    }

    #[test]
    fn full_workflow_valid() {
        let result = import_recipe(
            "https://www.bbcgoodfood.com/recipe",
            vec!["easy", "weeknight"],
        );
        assert!(result.is_ok());

        let recipe = result.unwrap();
        assert_eq!(recipe.id, 123);
        assert!(recipe.tags_applied.len() >= 3); // source tag + 2 user tags
    }

    #[test]
    fn full_workflow_invalid_url() {
        let result = import_recipe("not a url", vec![]);
        assert!(result.is_err());
    }

    #[test]
    fn full_workflow_empty_keywords_rejected() {
        let result = import_recipe(
            "https://www.seriouseats.com/recipe",
            vec!["", "   "],
        );
        assert!(result.is_err());
    }
    
    #[test]
    fn mock_implementation_uses_actual_input_url() {
        // Verify that the mock doesn't use hard-coded placeholder URLs
        let test_url = "https://www.allrecipes.com/recipe/12345";
        let result = import_recipe(test_url, vec!["quick"]);
        assert!(result.is_ok());
        
        let recipe = result.unwrap();
        assert_eq!(recipe.source_url, test_url);
        assert!(recipe.name.contains("allrecipes")); // Should derive from source tag
    }
    
    #[test]
    fn mock_preserves_all_keywords() {
        let result = import_recipe(
            "https://www.seriouseats.com/recipe",
            vec!["italian", "pasta", "quick"],
        );
        assert!(result.is_ok());
        
        let recipe = result.unwrap();
        // Should have source tag + 3 user keywords
        assert_eq!(recipe.tags_applied.len(), 4);
        assert!(recipe.tags_applied.iter().any(|k| k.as_str() == "seriouseats"));
        assert!(recipe.tags_applied.iter().any(|k| k.as_str() == "italian"));
        assert!(recipe.tags_applied.iter().any(|k| k.as_str() == "pasta"));
        assert!(recipe.tags_applied.iter().any(|k| k.as_str() == "quick"));
    }
}
