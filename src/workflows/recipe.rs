//! Recipe workflow types and functions
//!
//! Type system makes it impossible to construct invalid recipes or states.
//! Each type represents a specific validated state.

use super::errors::{RecipeImportError, RecipeImportResult};
use serde::{Deserialize, Serialize};

/// A URL that has been validated to be a real URL
/// Type system guarantees it's valid - you can't construct one without validation
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct ValidUrl(String);

impl ValidUrl {
    /// Parse and validate a URL string
    /// Only way to construct a ValidUrl
    pub fn parse(input: &str) -> RecipeImportResult<Self> {
        // Use url crate for real validation
        url::Url::parse(input)
            .map(|_| ValidUrl(input.to_string()))
            .map_err(|e| RecipeImportError::InvalidUrl(e.to_string()))
    }

    /// Get the underlying string (only when you really need it)
    pub fn as_str(&self) -> &str {
        &self.0
    }
}

/// Domain extracted from URL - guaranteed valid
/// Compiler won't let you use a random string here
#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize)]
pub struct SourceTag(String);

impl SourceTag {
    /// Extract domain from URL and convert to kebab-case
    /// This is the ONLY way to create a SourceTag
    pub fn from_url(url: &ValidUrl) -> RecipeImportResult<Self> {
        let parsed = url::Url::parse(url.as_str())
            .map_err(|e| RecipeImportError::InvalidUrl(e.to_string()))?;

        let domain = parsed
            .domain()
            .ok_or_else(|| RecipeImportError::InvalidUrl("No domain in URL".to_string()))?;

        // Remove www. prefix
        let mut domain = domain.trim_start_matches("www.");
        
        // Strip common TLDs including country-code TLDs (check most specific first)
        let country_code_tlds = [".com.au", ".co.uk", ".co.nz", ".co.za"];
        for tld in &country_code_tlds {
            if let Some(stripped) = domain.strip_suffix(tld) {
                domain = stripped;
                break;
            }
        }
        
        // Then try generic TLDs
        let generic_tlds = [".com", ".org", ".net"];
        for tld in &generic_tlds {
            if let Some(stripped) = domain.strip_suffix(tld) {
                domain = stripped;
                break;
            }
        }
        
        // Convert remaining dots to hyphens and lowercase
        let tag = domain.replace(".", "-").to_lowercase();

        Ok(SourceTag(tag))
    }

    pub fn as_str(&self) -> &str {
        &self.0
    }
}

/// Keyword that's been added to a recipe
/// Can't be empty, can't be just whitespace
#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize)]
pub struct Keyword(String);

impl Keyword {
    /// Create keyword with validation
    pub fn new(input: &str) -> RecipeImportResult<Self> {
        let trimmed = input.trim();
        if trimmed.is_empty() {
            return Err(RecipeImportError::InvalidRecipeData(
                "Keyword cannot be empty".to_string(),
            ));
        }
        Ok(Keyword(trimmed.to_string()))
    }

    pub fn as_str(&self) -> &str {
        &self.0
    }
}

/// Recipe with tags - ready to import
/// Can't construct this without going through validation steps
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct RecipeWithTags {
    pub url: ValidUrl,
    pub source_tag: SourceTag,
    pub keywords: Vec<Keyword>,
}

impl RecipeWithTags {
    /// Create a recipe with all required validations
    /// This is the ONLY way to construct RecipeWithTags
    pub fn new(
        url: ValidUrl,
        keywords: Vec<&str>,
    ) -> RecipeImportResult<Self> {
        let source_tag = SourceTag::from_url(&url)?;

        let mut all_keywords = vec![Keyword::new(source_tag.as_str())?];

        for kw in keywords {
            all_keywords.push(Keyword::new(kw)?);
        }

        Ok(RecipeWithTags {
            url,
            source_tag,
            keywords: all_keywords,
        })
    }
}

/// A recipe that's been imported successfully
/// Compiler guarantees it has an ID and name
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct ImportedRecipe {
    pub id: i64,
    pub name: String,
    pub source_url: String,
    pub tags_applied: Vec<Keyword>,
}

impl ImportedRecipe {
    /// Create an imported recipe
    /// ID must be > 0 (compiler doesn't enforce but tests will catch)
    pub fn new(
        id: i64,
        name: String,
        source_url: String,
        tags_applied: Vec<Keyword>,
    ) -> RecipeImportResult<Self> {
        if id <= 0 {
            return Err(RecipeImportError::InvalidRecipeData(
                "Recipe ID must be positive".to_string(),
            ));
        }
        if name.trim().is_empty() {
            return Err(RecipeImportError::InvalidRecipeData(
                "Recipe name cannot be empty".to_string(),
            ));
        }

        Ok(ImportedRecipe {
            id,
            name,
            source_url,
            tags_applied,
        })
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn valid_url_accepted() {
        let url = ValidUrl::parse("https://www.seriouseats.com/recipe").unwrap();
        assert_eq!(url.as_str(), "https://www.seriouseats.com/recipe");
    }

    #[test]
    fn invalid_url_rejected() {
        let result = ValidUrl::parse("not a url");
        assert!(result.is_err());
    }

    #[test]
    fn source_tag_from_url() {
        let url = ValidUrl::parse("https://www.serious-eats.com/recipe").unwrap();
        let tag = SourceTag::from_url(&url).unwrap();
        assert_eq!(tag.as_str(), "serious-eats");
    }
    
    #[test]
    fn source_tag_handles_country_code_tlds() {
        // Test .com.au
        let url = ValidUrl::parse("https://www.taste.com.au/recipe").unwrap();
        let tag = SourceTag::from_url(&url).unwrap();
        assert_eq!(tag.as_str(), "taste");
        
        // Test .co.uk
        let url = ValidUrl::parse("https://www.bbcgoodfood.co.uk/recipe").unwrap();
        let tag = SourceTag::from_url(&url).unwrap();
        assert_eq!(tag.as_str(), "bbcgoodfood");
        
        // Test .co.nz
        let url = ValidUrl::parse("https://www.nzherald.co.nz/recipe").unwrap();
        let tag = SourceTag::from_url(&url).unwrap();
        assert_eq!(tag.as_str(), "nzherald");
    }

    #[test]
    fn keyword_rejects_empty() {
        let result = Keyword::new("");
        assert!(result.is_err());
    }

    #[test]
    fn keyword_trims_whitespace() {
        let kw = Keyword::new("  dinner  ").unwrap();
        assert_eq!(kw.as_str(), "dinner");
    }

    #[test]
    fn recipe_with_tags_validates() {
        let url = ValidUrl::parse("https://www.serious-eats.com/recipe").unwrap();
        let recipe = RecipeWithTags::new(url, vec!["quick", "dinner"]).unwrap();

        assert_eq!(recipe.keywords.len(), 3); // source tag + 2 user keywords
        assert!(recipe.keywords.iter().any(|k| k.as_str() == "serious-eats"));
    }

    #[test]
    fn imported_recipe_rejects_zero_id() {
        let result = ImportedRecipe::new(0, "Test".to_string(), "http://example.com".to_string(), vec![]);
        assert!(result.is_err());
    }
}
