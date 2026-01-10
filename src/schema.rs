//! JSON Schema introspection for binary interfaces
//!
//! This module provides utilities for binaries to output JSON Schema Draft 7
//! descriptions of their input/output contracts when invoked with --schema flag.
//!
//! # Usage
//!
//! ```rust,no_run
//! use meal_planner::schema::{BinarySchema, SchemaBuilder, Example};
//!
//! fn main() {
//!     if std::env::args().nth(1).as_deref() == Some("--schema") {
//!         let schema = SchemaBuilder::new("my_binary", "1.0.0")
//!             .description("Does something useful")
//!             .input_schema(serde_json::json!({
//!                 "type": "object",
//!                 "properties": {
//!                     "name": {"type": "string"}
//!                 },
//!                 "required": ["name"]
//!             }))
//!             .output_success_schema(serde_json::json!({
//!                 "type": "object",
//!                 "properties": {
//!                     "success": {"type": "boolean"},
//!                     "message": {"type": "string"}
//!                 },
//!                 "required": ["success", "message"]
//!             }))
//!             .output_error_schema(serde_json::json!({
//!                 "type": "object",
//!                 "properties": {
//!                     "success": {"type": "boolean"},
//!                     "error": {"type": "string"}
//!                 },
//!                 "required": ["success", "error"]
//!             }))
//!             .example(
//!                 "Basic usage",
//!                 serde_json::json!({"name": "test"}),
//!                 serde_json::json!({"success": true, "message": "OK"})
//!             )
//!             .build();
//!
//!         println!("{}", serde_json::to_string_pretty(&schema).unwrap());
//!         std::process::exit(0);
//!     }
//!     // ... normal binary logic
//! }
//! ```

use serde::{Deserialize, Serialize};
use serde_json::Value;

/// Complete JSON Schema Draft 7 description of a binary's interface
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct BinarySchema {
    /// JSON Schema version
    #[serde(rename = "$schema")]
    pub schema_version: String,

    /// Binary name
    pub binary_name: String,

    /// Human-readable description
    pub description: String,

    /// Binary version
    pub version: String,

    /// Input schema (JSON Schema Draft 7)
    pub input: Value,

    /// Success output schema (JSON Schema Draft 7)
    pub output_success: Value,

    /// Error output schema (JSON Schema Draft 7)
    pub output_error: Value,

    /// Usage examples
    pub examples: Vec<Example>,
}

/// Example of binary input/output
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct Example {
    /// Description of what this example demonstrates
    pub description: String,

    /// Example input (must conform to input schema)
    pub input: Value,

    /// Expected output (must conform to output_success schema)
    pub expected_output: Value,
}

/// Builder for `BinarySchema`
#[derive(Debug, Clone)]
pub struct SchemaBuilder {
    binary_name: String,
    version: String,
    description: Option<String>,
    input: Option<Value>,
    output_success: Option<Value>,
    output_error: Option<Value>,
    examples: Vec<Example>,
}

impl SchemaBuilder {
    /// Create a new schema builder
    #[must_use]
    pub fn new(binary_name: impl Into<String>, version: impl Into<String>) -> Self {
        Self {
            binary_name: binary_name.into(),
            version: version.into(),
            description: None,
            input: None,
            output_success: None,
            output_error: None,
            examples: Vec::new(),
        }
    }

    /// Set the description
    #[must_use]
    pub fn description(mut self, description: impl Into<String>) -> Self {
        self.description = Some(description.into());
        self
    }

    /// Set the input schema
    #[must_use]
    pub fn input_schema(mut self, schema: Value) -> Self {
        self.input = Some(schema);
        self
    }

    /// Set the success output schema
    #[must_use]
    pub fn output_success_schema(mut self, schema: Value) -> Self {
        self.output_success = Some(schema);
        self
    }

    /// Set the error output schema
    #[must_use]
    pub fn output_error_schema(mut self, schema: Value) -> Self {
        self.output_error = Some(schema);
        self
    }

    /// Add an example
    #[must_use]
    pub fn example(
        mut self,
        description: impl Into<String>,
        input: Value,
        expected_output: Value,
    ) -> Self {
        self.examples.push(Example {
            description: description.into(),
            input,
            expected_output,
        });
        self
    }

    /// Build the schema
    ///
    /// # Panics
    ///
    /// Panics if required fields are missing
    #[must_use]
    pub fn build(self) -> BinarySchema {
        BinarySchema {
            schema_version: "http://json-schema.org/draft-07/schema#".to_string(),
            binary_name: self.binary_name,
            description: self.description.unwrap_or_else(|| "No description provided".to_string()),
            version: self.version,
            input: self.input.unwrap_or_else(|| serde_json::json!({"type": "null"})),
            output_success: self.output_success.unwrap_or_else(|| serde_json::json!({"type": "object"})),
            output_error: self.output_error.unwrap_or_else(|| serde_json::json!({"type": "object"})),
            examples: self.examples,
        }
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_schema_builder() {
        let schema = SchemaBuilder::new("test_binary", "1.0.0")
            .description("Test binary")
            .input_schema(serde_json::json!({
                "type": "object",
                "properties": {
                    "name": {"type": "string"}
                },
                "required": ["name"]
            }))
            .output_success_schema(serde_json::json!({
                "type": "object",
                "properties": {
                    "success": {"type": "boolean"}
                },
                "required": ["success"]
            }))
            .output_error_schema(serde_json::json!({
                "type": "object",
                "properties": {
                    "success": {"type": "boolean"},
                    "error": {"type": "string"}
                },
                "required": ["success", "error"]
            }))
            .example(
                "Basic usage",
                serde_json::json!({"name": "test"}),
                serde_json::json!({"success": true})
            )
            .build();

        assert_eq!(schema.binary_name, "test_binary");
        assert_eq!(schema.version, "1.0.0");
        assert_eq!(schema.examples.len(), 1);
        assert_eq!(schema.schema_version, "http://json-schema.org/draft-07/schema#");
    }

    #[test]
    fn test_schema_serialization() {
        let schema = SchemaBuilder::new("test_binary", "1.0.0")
            .description("Test binary")
            .input_schema(serde_json::json!({"type": "object"}))
            .output_success_schema(serde_json::json!({"type": "object"}))
            .output_error_schema(serde_json::json!({"type": "object"}))
            .build();

        let json = serde_json::to_string(&schema).expect("Failed to serialize");
        assert!(json.contains("\"binary_name\":\"test_binary\""));
        assert!(json.contains("\"version\":\"1.0.0\""));
        assert!(json.contains("\"$schema\":\"http://json-schema.org/draft-07/schema#\""));
    }

    #[test]
    fn test_valid_json_output() {
        let schema = SchemaBuilder::new("test_binary", "1.0.0")
            .description("Test binary")
            .input_schema(serde_json::json!({"type": "null"}))
            .output_success_schema(serde_json::json!({"type": "object"}))
            .output_error_schema(serde_json::json!({"type": "object"}))
            .build();

        let json = serde_json::to_string_pretty(&schema).expect("Failed to serialize");

        // Verify it's valid JSON by parsing it back
        let parsed: BinarySchema = serde_json::from_str(&json).expect("Failed to parse");
        assert_eq!(parsed.binary_name, "test_binary");
    }
}
