//! Test Tandoor API connection
//!
//! JSON stdin (Windmill format):
//!   `{"tandoor": {"base_url": "...", "api_token": "..."}}`
//!
//! JSON stdin (standalone format):
//!   `{"base_url": "...", "api_token": "..."}`
//!
//! JSON stdout: `{"success": true, "message": "...", "recipe_count": N}`

// CLI binaries: exit and unwrap/expect are acceptable at the top level
#![allow(clippy::exit, clippy::unwrap_used, clippy::expect_used)]

use meal_planner::tandoor::{TandoorClient, TandoorConfig};
use serde::Deserialize;
use std::io::{self, Read};

/// Input wrapper supporting both Windmill and standalone formats
#[derive(Deserialize)]
struct Input {
    /// Windmill resource format (optional)
    tandoor: Option<TandoorConfig>,
    /// Standalone format fields (optional)
    base_url: Option<String>,
    api_token: Option<String>,
}

fn main() {
    // Check for help and schema flags first
    let args: Vec<String> = std::env::args().collect();
    if args.len() > 1 {
        let arg = &args[1];
        if arg == "--help" || arg == "-h" || arg == "help" {
            print_help();
            std::process::exit(0);
        }
        if arg == "--schema" {
            print_schema();
            std::process::exit(0);
        }
    }

    match run() {
        Ok(output) => println!(
            "{}",
            serde_json::to_string(&output).expect("Failed to serialize output JSON")
        ),
        Err(e) => {
            println!("{{\"success\":false,\"error\":\"{e}\"}}");
            std::process::exit(1);
        }
    }
}

fn run() -> anyhow::Result<serde_json::Value> {
    let mut input = String::new();
    io::stdin().read_to_string(&mut input)?;

    let parsed: Input = serde_json::from_str(&input)?;

    // Support both Windmill format (nested) and standalone format (flat)
    let config = match parsed.tandoor {
        Some(c) => c,
        None => TandoorConfig {
            base_url: parsed
                .base_url
                .ok_or_else(|| anyhow::anyhow!("base_url required"))?,
            api_token: parsed
                .api_token
                .ok_or_else(|| anyhow::anyhow!("api_token required"))?,
        },
    };

    let client = TandoorClient::new(&config)?;
    let result = client.test_connection()?;

    Ok(serde_json::to_value(result)?)
}

fn print_help() {
    println!(
        r#"tandoor_test_connection - Test Tandoor API connection

USAGE
    echo '{{...}}' | tandoor_test_connection
    tandoor_test_connection --help
    tandoor_test_connection -h
    tandoor_test_connection help

    This utility tests connectivity to a Tandoor Recipes API instance by
    attempting to authenticate and fetch basic information (recipe count).

INPUT SCHEMA
    JSON input via stdin (Windmill resource format):
    {{
        "tandoor": {{
            "base_url": "string",   // Tandoor API base URL (e.g., "https://recipes.example.com")
            "api_token": "string"   // Tandoor API authentication token
        }}
    }}

    JSON input via stdin (standalone format):
    {{
        "base_url": "string",       // Tandoor API base URL
        "api_token": "string"       // Tandoor API authentication token
    }}

    Command-line arguments:
    - --help, -h, help: Display this help message

    Both input formats are supported for compatibility with Windmill and
    standalone usage.

OUTPUT SCHEMA
    Success response (JSON on stdout):
    {{
        "success": true,
        "message": "Successfully connected to Tandoor API",
        "recipe_count": 123,        // Number of recipes in the Tandoor instance
        "base_url": "https://..."   // Confirmed API endpoint
    }}

    Error response (JSON on stdout):
    {{
        "success": false,
        "error": "Error description"
    }}

    Common error messages:
    - "base_url required" - Missing base URL in input
    - "api_token required" - Missing API token in input
    - "Invalid API token" - Authentication failed
    - "Connection refused" - Unable to reach Tandoor server
    - "Invalid base URL format" - Malformed URL

EXAMPLES
    1. Test connection (Windmill format):
       $ echo '{{"tandoor":{{"base_url":"https://recipes.example.com","api_token":"your-token"}}}}' | tandoor_test_connection
       {{"success":true,"message":"Successfully connected...","recipe_count":42}}

    2. Test connection (standalone format):
       $ echo '{{"base_url":"https://recipes.example.com","api_token":"your-token"}}' | tandoor_test_connection
       {{"success":true,"message":"Successfully connected...","recipe_count":42}}

    3. Use in startup scripts:
       $ if echo '{{...}}' | tandoor_test_connection > /dev/null; then
           echo "Tandoor API is reachable"
         else
           echo "Cannot connect to Tandoor API"
           exit 1
         fi

    4. Display help:
       $ tandoor_test_connection --help

EXIT CODES
    0 - Success (connected to Tandoor API successfully)
    1 - Error (connection failed, invalid credentials, or malformed input)

NOTES
    - This binary reads JSON from stdin (not command-line arguments)
    - The base_url should include the protocol (http:// or https://)
    - The base_url should NOT include a trailing slash
    - API token can be obtained from Tandoor web UI: Settings > API
    - Connection test fetches recipe count to verify API access
    - Typical response time: < 2 seconds for local networks
    - Both Windmill resource format and standalone format are supported
    - Used for health checks and configuration validation

TANDOOR API TOKEN
    To obtain an API token from Tandoor Recipes:
    1. Log into your Tandoor web interface
    2. Navigate to Settings > API
    3. Click "Generate Token" or use an existing token
    4. Copy the token for use with this binary

TROUBLESHOOTING
    - "Connection refused": Check base_url and network connectivity
    - "Invalid API token": Generate a new token in Tandoor settings
    - "SSL certificate error": Verify HTTPS certificate or use HTTP for local dev
    - Empty response: Check Tandoor server logs for errors
    - Timeout: Increase network timeout or check server load

SECURITY
    - API tokens grant full access to your Tandoor instance
    - Never commit tokens to version control
    - Store tokens in environment variables or secure vaults
    - For Windmill, use secure resources (u/admin/tandoor)
    - Rotate tokens periodically for security
"#
    );
}

fn print_schema() {
    use meal_planner::schema::SchemaBuilder;

    let schema = SchemaBuilder::new("tandoor_test_connection", env!("CARGO_PKG_VERSION"))
        .description("Test Tandoor API connection and validate credentials")
        .input_schema(serde_json::json!({
            "oneOf": [
                {
                    "type": "object",
                    "properties": {
                        "tandoor": {
                            "type": "object",
                            "properties": {
                                "base_url": {"type": "string", "format": "uri"},
                                "api_token": {"type": "string"}
                            },
                            "required": ["base_url", "api_token"]
                        }
                    },
                    "required": ["tandoor"]
                },
                {
                    "type": "object",
                    "properties": {
                        "base_url": {"type": "string", "format": "uri"},
                        "api_token": {"type": "string"}
                    },
                    "required": ["base_url", "api_token"]
                }
            ]
        }))
        .output_success_schema(serde_json::json!({
            "type": "object",
            "properties": {
                "success": {"type": "boolean", "const": true},
                "message": {"type": "string"},
                "recipe_count": {"type": "integer", "minimum": 0}
            },
            "required": ["success", "message", "recipe_count"]
        }))
        .output_error_schema(serde_json::json!({
            "type": "object",
            "properties": {
                "success": {"type": "boolean", "const": false},
                "error": {"type": "string"}
            },
            "required": ["success", "error"]
        }))
        .example(
            "Windmill format",
            serde_json::json!({
                "tandoor": {
                    "base_url": "https://recipes.example.com",
                    "api_token": "your-api-token-here"
                }
            }),
            serde_json::json!({
                "success": true,
                "message": "Successfully connected to Tandoor",
                "recipe_count": 42
            })
        )
        .example(
            "Standalone format",
            serde_json::json!({
                "base_url": "https://recipes.example.com",
                "api_token": "your-api-token-here"
            }),
            serde_json::json!({
                "success": true,
                "message": "Successfully connected to Tandoor",
                "recipe_count": 100
            })
        )
        .build();

    println!(
        "{}",
        serde_json::to_string_pretty(&schema).expect("Failed to serialize schema")
    );
}
