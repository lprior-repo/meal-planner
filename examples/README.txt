MEAL PLANNER - EXAMPLE JSON FILES
==================================

This directory contains example JSON input files for the meal-planner binaries.
Each file demonstrates the expected input schema for a specific binary.

USAGE INSTRUCTIONS
------------------

There are two ways to use these example files:

1. Via stdin (pipe or redirect):
   cat examples/sync_meal_plan_basic.json | cargo run --bin sync_meal_plan

2. As a command-line argument:
   cargo run --bin sync_meal_plan "$(cat examples/sync_meal_plan_basic.json)"

EXAMPLE FILES
-------------

sync_meal_plan_basic.json
    Single meal entry on a single day. Demonstrates the minimal valid input
    for syncing a Tandoor meal plan entry to FatSecret.
    Binary: sync_meal_plan

sync_meal_plan_multiple_days.json
    Full week of meal entries (21 meals across 7 days: breakfast, lunch, and
    dinner). Demonstrates batch processing of multiple days.
    Binary: sync_meal_plan

sync_meal_plan_edge_cases.json
    Mix of valid and potentially problematic entries including:
    - Fractional servings (0.25, 0.5, 2.5)
    - Zero values (0.0 fat)
    - High serving counts (10.0)
    - Special characters in recipe names
    - Very long recipe names
    - Invalid date (Feb 29, 2026 - not a leap year)
    - Extreme calorie values
    Binary: sync_meal_plan

analyze_nutrition_week.json
    Weekly nutrition analysis request with calorie and protein targets.
    Analyzes food diary entries for trend detection and recommendations.
    Binary: analyze_nutrition

track_exercise_balance_deficit.json
    Daily exercise and calorie balance tracking for a deficit (weight loss)
    goal. Includes BMR, activity multiplier, and multiple exercise entries.
    Binary: track_exercise_balance

tandoor_recipe_get_basic.json
    Fetch a recipe from Tandoor by ID. Retrieves full recipe information
    including ingredients, steps, and nutrition data.
    Binary: tandoor_recipe_get

generate_encryption_key_basic.json
    Generate a new OAuth encryption key for secure token storage. No input
    parameters required (file contains "null").
    Binary: generate_encryption_key

validate_encryption_basic.json
    Validate OAuth encryption configuration with detailed diagnostics enabled.
    Checks that OAUTH_ENCRYPTION_KEY environment variable is properly set.
    Binary: validate_encryption

tandoor_test_connection_basic.json
    Test connection to Tandoor API and validate credentials. Returns recipe
    count if connection is successful.
    Binary: tandoor_test_connection

log_recipe_to_fatsecret_basic.json
    Log a Tandoor recipe to FatSecret food diary with custom servings.
    Fetches recipe from Tandoor, scales nutrition, and creates diary entry.
    Binary: log_recipe_to_fatsecret

BEFORE USING EXAMPLES
----------------------

1. Replace placeholder credentials:
   - "user_oauth_token_here" -> Your actual FatSecret OAuth token
   - "user_oauth_secret_here" -> Your actual FatSecret OAuth secret
   - "your_tandoor_api_token_here" -> Your actual Tandoor API token
   - "your_fatsecret_consumer_key_here" -> Your FatSecret app consumer key
   - "your_fatsecret_consumer_secret_here" -> Your FatSecret app consumer secret
   - "https://recipes.example.com" -> Your actual Tandoor instance URL

2. For FatSecret binaries, ensure you have completed OAuth flow:
   - Run: cargo run --bin fatsecret_oauth_start
   - Follow the URL and authorize the app
   - Run: cargo run --bin fatsecret_oauth_complete
   - Use the returned access_token and access_secret in example files

3. For encryption binaries, set the OAUTH_ENCRYPTION_KEY environment variable:
   - Generate a key: cargo run --bin generate_encryption_key
   - Set it: export OAUTH_ENCRYPTION_KEY="<generated_key>"

4. Update dates to current or future dates as needed.

VALIDATION
----------

All example files are valid JSON and can be validated with jq:
    jq . examples/*.json

To validate a specific file:
    jq . examples/sync_meal_plan_basic.json

To extract and pretty-print:
    cat examples/sync_meal_plan_basic.json | jq .

SCHEMA INFORMATION
------------------

To view the full JSON schema for any binary, use the --schema flag:
    cargo run --bin sync_meal_plan --schema
    cargo run --bin analyze_nutrition --schema
    cargo run --bin track_exercise_balance --schema
    cargo run --bin tandoor_recipe_get --schema
    cargo run --bin generate_encryption_key --schema
    cargo run --bin validate_encryption --schema
    cargo run --bin tandoor_test_connection --schema
    cargo run --bin log_recipe_to_fatsecret --schema

COMMON ERRORS
-------------

1. "Invalid date format":
   - Dates must be YYYY-MM-DD format (e.g., "2026-01-10")
   - Ensure dates are valid (no Feb 30, Apr 31, etc.)

2. "Invalid meal_type":
   - Must be one of: "breakfast", "lunch", "dinner", "snack"
   - Case-sensitive (lowercase only)

3. "Invalid credentials":
   - Check that OAuth tokens and secrets are valid and not expired
   - Ensure FatSecret consumer key/secret match your app registration
   - Verify Tandoor API token has not been revoked

4. "Recipe has no nutrition data":
   - For log_recipe_to_fatsecret, ensure recipe nutrition has been calculated
   - Run tandoor_recipe_calculate_nutrition first if needed

5. "OAUTH_ENCRYPTION_KEY environment variable not set":
   - Generate a key with generate_encryption_key
   - Export it: export OAUTH_ENCRYPTION_KEY="<key>"

NOTES
-----

- All numeric values (calories, protein, etc.) should be positive numbers
- Servings can be fractional (e.g., 0.5, 1.5, 2.5)
- Recipe names support UTF-8 characters including special symbols
- FatSecret API has rate limits; avoid excessive concurrent requests
- Tandoor base_url should not include trailing slash
- For production use, store credentials in environment variables or secure vaults

TESTING
-------

To test binaries with example data without making real API calls:
1. Use mock servers or test accounts
2. Validate JSON structure before testing
3. Check binary help text: cargo run --bin <binary_name> --help

TROUBLESHOOTING
---------------

If you encounter issues:
1. Validate JSON syntax: jq . <file>
2. Check binary schema: cargo run --bin <binary_name> --schema
3. Verify credentials are not placeholders
4. Ensure environment variables are set (for encryption)
5. Check network connectivity to Tandoor/FatSecret APIs
6. Review binary help text for specific requirements

CONTRIBUTING
------------

When adding new example files:
1. Follow naming convention: <binary_name>_<scenario>.json
2. Include realistic data values
3. Document the purpose in this README
4. Ensure JSON is valid (test with jq)
5. Use placeholder text for credentials (never commit real tokens)

SECURITY WARNING
----------------

Never commit real credentials to version control:
- Replace all tokens/secrets with placeholders before committing
- Store real credentials in environment variables
- Use .gitignore to prevent accidental commits of credential files
- Rotate tokens if accidentally exposed

For questions or issues, refer to the project documentation or binary --help text.
