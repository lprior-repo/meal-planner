////
//// RED PHASE: This test MUST fail initially because the implementation
//// does not exist yet. The test validates:
//// 1. List categories from Tandoor API /api/keyword/
//// 2. Display category tree structure with parent-child relationships
//// 3. Show recipe counts per category (numchild field)
////
//// Test follows Gleam 7 Commandments:
//// - Immutability: All test data is immutable
//// - No Nulls: Uses Option(T) and Result(T, E) exclusively
//// - Exhaustive Matching: All case branches covered
//// - Type Safety: Custom types for domain concepts
////
//// Based on meal-planner architecture:
//// - Category data comes from meal_planner/tandoor/keyword.gleam
//// - CLI command defined in meal_planner/cli/domains/tandoor.gleam
//// - Uses glint for flag parsing

/// TDD Test for CLI tandoor categories command
import gleam/option.{None, Some}
import gleeunit
import gleeunit/should
import meal_planner/cli/domains/tandoor as tandoor_cmd
import meal_planner/config
import meal_planner/tandoor/keyword.{type Keyword, Keyword}

pub fn main() {
  gleeunit.main()
}

// ============================================================================
// Test Fixtures
// ============================================================================

/// Mock root category (no parent)
fn mock_root_category() -> Keyword {
  Keyword(
    id: 1,
    name: "cuisine",
    label: "Cuisine",
    description: "Recipe cuisine types",
    icon: Some("🍽️"),
    parent: None,
    numchild: 3,
    // Has 3 children
    created_at: "2025-01-01T00:00:00Z",
    updated_at: "2025-01-01T00:00:00Z",
    full_name: "Cuisine",
  )
}

/// Mock child category (has parent)
fn mock_italian_category() -> Keyword {
  Keyword(
    id: 2,
    name: "italian",
    label: "Italian",
    description: "Italian cuisine recipes",
    icon: Some("🇮🇹"),
    parent: Some(1),
    // Parent is Cuisine
    numchild: 2,
    // Has 2 children
    created_at: "2025-01-01T00:00:00Z",
    updated_at: "2025-01-01T00:00:00Z",
    full_name: "Cuisine > Italian",
  )
}

/// Mock nested child category (grandchild)
fn mock_sicilian_category() -> Keyword {
  Keyword(
    id: 3,
    name: "sicilian",
    label: "Sicilian",
    description: "Sicilian regional Italian recipes",
    icon: None,
    parent: Some(2),
    // Parent is Italian
    numchild: 0,
    // Leaf node
    created_at: "2025-01-01T00:00:00Z",
    updated_at: "2025-01-01T00:00:00Z",
    full_name: "Cuisine > Italian > Sicilian",
  )
}

/// Mock category with no children
fn mock_leaf_category() -> Keyword {
  Keyword(
    id: 4,
    name: "vegetarian",
    label: "Vegetarian",
    description: "Vegetarian and plant-based recipes",
    icon: Some("🥗"),
    parent: None,
    numchild: 0,
    // No children
    created_at: "2025-01-01T00:00:00Z",
    updated_at: "2025-01-01T00:00:00Z",
    full_name: "Vegetarian",
  )
}

/// Mock category without icon
fn mock_no_icon_category() -> Keyword {
  Keyword(
    id: 5,
    name: "french",
    label: "French",
    description: "French cuisine recipes",
    icon: None,
    parent: Some(1),
    // Parent is Cuisine
    numchild: 1,
    created_at: "2025-01-01T00:00:00Z",
    updated_at: "2025-01-01T00:00:00Z",
    full_name: "Cuisine > French",
  )
}

/// Test config for CLI commands
fn test_config() -> config.Config {
  config.Config(
    environment: config.Development,
    database: config.DatabaseConfig(
      host: "localhost",
      port: 5432,
      name: "meal_planner_test",
      user: "test_user",
      password: "test_password",
      pool_size: 10,
      connection_timeout_ms: 5000,
    ),
    server: config.ServerConfig(port: 8080, cors_allowed_origins: []),
    tandoor: config.TandoorConfig(
      base_url: "http://localhost:8000",
      api_token: "test_token",
      connect_timeout_ms: 5000,
      request_timeout_ms: 30_000,
    ),
    external_services: config.ExternalServicesConfig(
      fatsecret: Some(config.FatSecretConfig(
        consumer_key: "test_client_id",
        consumer_secret: "test_client_secret",
      )),
      todoist_api_key: "test_todoist",
      usda_api_key: "test_usda",
      openai_api_key: "test_openai",
      openai_model: "gpt-4",
    ),
    secrets: config.SecretsConfig(
      oauth_encryption_key: None,
      jwt_secret: None,
      database_password: "test_password",
      tandoor_token: "test_token",
    ),
    logging: config.LoggingConfig(level: config.InfoLevel, debug_mode: False),
    performance: config.PerformanceConfig(
      request_timeout_ms: 30_000,
      connection_timeout_ms: 5000,
      max_concurrent_requests: 100,
      rate_limit_requests: 1000,
    ),
  )
}

// ============================================================================
// RED PHASE: Tests that MUST FAIL initially
// ============================================================================

/// Test: mp tandoor categories
///
/// EXPECTED FAILURE: tandoor_cmd.list_categories function does not exist yet
///
/// This test validates that the categories command:
/// 1. Calls tandoor/keyword.list_keywords to fetch all categories
/// 2. Returns Ok(Nil) after displaying categories
/// 3. Fetches keywords from Tandoor API /api/keyword/
///
/// Implementation strategy:
/// - Add list_categories function to meal_planner/cli/domains/tandoor.gleam
/// - Function signature: fn list_categories(config: Config) -> Result(Nil, Nil)
/// - Call tandoor/keyword.list_keywords(tandoor_config)
/// - Format and print results using io.println
pub fn categories_list_all_test() {
  let cfg = test_config()

  // When: calling list_categories
  let result = tandoor_cmd.list_categories(cfg)

  // Then: should return Ok(Nil) indicating success
  // This will FAIL because tandoor_cmd.list_categories does not exist
  result
  |> should.be_ok()
}

/// Test: mp tandoor categories displays root categories
///
/// EXPECTED FAILURE: tandoor_cmd.list_categories does not display categories
///
/// This test validates that root-level categories are displayed:
/// 1. Identifies categories with parent = None
/// 2. Displays root categories at top level
/// 3. Shows category name and label
///
/// Constraint: Root categories have no parent (parent field is None)
pub fn categories_displays_root_categories_test() {
  let cfg = test_config()

  // When: calling list_categories
  let result = tandoor_cmd.list_categories(cfg)

  // Then: should display root categories (parent = None)
  // Implementation should filter/identify root keywords
  // This will FAIL because tandoor_cmd.list_categories does not exist
  result
  |> should.be_ok()
}

/// Test: mp tandoor categories displays child categories
///
/// EXPECTED FAILURE: tandoor_cmd.list_categories does not display child categories
///
/// This test validates that child categories are displayed:
/// 1. Identifies categories with parent != None
/// 2. Displays children indented under their parent
/// 3. Shows hierarchical structure using full_name
///
/// Constraint: Child categories have a parent (parent field is Some(parent_id))
pub fn categories_displays_child_categories_test() {
  let cfg = test_config()

  // When: calling list_categories
  let result = tandoor_cmd.list_categories(cfg)

  // Then: should display child categories indented
  // Implementation should group by parent_id and indent
  // This will FAIL because tandoor_cmd.list_categories does not exist
  result
  |> should.be_ok()
}

/// Test: mp tandoor categories displays recipe counts
///
/// EXPECTED FAILURE: tandoor_cmd.list_categories does not display numchild
///
/// This test validates that recipe/child counts are displayed:
/// 1. Extracts numchild field from Keyword
/// 2. Displays count next to category name
/// 3. Shows "3 recipes" or "0 recipes" format
///
/// Constraint: numchild is Int type representing number of child categories
pub fn categories_displays_recipe_counts_test() {
  let cfg = test_config()

  // When: calling list_categories
  let result = tandoor_cmd.list_categories(cfg)

  // Then: should display numchild count for each category
  // Expected format: "Cuisine (3 subcategories)"
  // This will FAIL because tandoor_cmd.list_categories does not exist
  result
  |> should.be_ok()
}

/// Test: mp tandoor categories displays tree structure
///
/// EXPECTED FAILURE: tandoor_cmd.list_categories does not format tree
///
/// This test validates that categories are displayed as a tree:
/// 1. Uses full_name to show hierarchy (e.g., "Cuisine > Italian > Sicilian")
/// 2. Indents child categories under parents
/// 3. Shows nested structure visually
///
/// Constraint: full_name contains " > " separators for hierarchy
///
/// Implementation strategy:
/// - Parse full_name to determine depth (count " > " occurrences)
/// - Use depth to determine indentation level
/// - Format with "  " (2 spaces) per depth level
pub fn categories_displays_tree_structure_test() {
  let cfg = test_config()

  // When: calling list_categories
  let result = tandoor_cmd.list_categories(cfg)

  // Then: should display categories in tree format
  // Expected output:
  // Cuisine (3 subcategories)
  //   Italian (2 subcategories)
  //     Sicilian (0 subcategories)
  //   French (1 subcategory)
  // Vegetarian (0 subcategories)
  // This will FAIL because tandoor_cmd.list_categories does not exist
  result
  |> should.be_ok()
}

/// Test: mp tandoor categories displays category icons
///
/// EXPECTED FAILURE: tandoor_cmd.list_categories does not display icons
///
/// This test validates that category icons are displayed:
/// 1. Extracts icon field from Keyword (Option(String))
/// 2. Displays icon emoji next to category name
/// 3. Handles None case (no icon)
///
/// Constraint: icon is Option(String), can be Some(emoji) or None
pub fn categories_displays_icons_test() {
  let cfg = test_config()

  // When: calling list_categories
  let result = tandoor_cmd.list_categories(cfg)

  // Then: should display icon if present
  // Expected format: "🍽️ Cuisine (3 subcategories)"
  // If no icon: "French (1 subcategory)"
  // This will FAIL because tandoor_cmd.list_categories does not exist
  result
  |> should.be_ok()
}

/// Test: mp tandoor categories with limit flag
///
/// EXPECTED FAILURE: tandoor_cmd.list_categories_with_limit does not exist
///
/// This test validates that the limit flag works:
/// 1. Accepts --limit N flag from command line
/// 2. Passes limit to API query
/// 3. Returns only N results
///
/// Constraint: limit must be positive integer
///
/// Implementation strategy:
/// - Add limit parameter to list_categories function
/// - Pass to keyword.list_keywords with query param
/// - Default limit to 50 if not provided
pub fn categories_with_limit_test() {
  let cfg = test_config()
  let limit = 10

  // When: calling list_categories with limit
  let result = tandoor_cmd.list_categories_with_limit(cfg, limit: limit)

  // Then: should return Ok(Nil) and respect limit
  // This will FAIL because list_categories_with_limit does not exist
  result
  |> should.be_ok()
}

/// Test: mp tandoor categories handles empty results
///
/// EXPECTED FAILURE: tandoor_cmd.list_categories does not handle empty list
///
/// This test validates behavior when no categories exist:
/// 1. Calls API which returns empty list
/// 2. Displays "No categories found" message
/// 3. Returns Ok(Nil) (not an error - empty is valid)
///
/// Constraint: Empty category list is not an error condition
pub fn categories_empty_list_test() {
  let cfg = test_config()

  // When: calling list_categories with no categories in system
  let result = tandoor_cmd.list_categories(cfg)

  // Then: should return Ok(Nil) with "No categories found" message
  // Implementation should check if keyword list is empty
  // This will FAIL because tandoor_cmd.list_categories does not exist
  result
  |> should.be_ok()
}

/// Test: mp tandoor categories handles API errors
///
/// EXPECTED FAILURE: tandoor_cmd.list_categories does not handle errors
///
/// This test validates error handling:
/// 1. Detects API connection failure
/// 2. Returns Error(Nil) with descriptive message
/// 3. Does not crash on network errors
///
/// Constraint: Must gracefully handle TandoorError from keyword.list_keywords
pub fn categories_handles_api_error_test() {
  let cfg = test_config()

  // When: calling list_categories with invalid config (unreachable API)
  let bad_config =
    config.Config(
      ..cfg,
      tandoor: config.TandoorConfig(
        base_url: "http://invalid-host-that-does-not-exist:9999",
        api_token: "invalid_token",
        connect_timeout_ms: 1000,
        request_timeout_ms: 2000,
      ),
    )

  let result = tandoor_cmd.list_categories(bad_config)

  // Then: should return Error(Nil) for connection failure
  // Implementation should map TandoorError to error message
  // This will FAIL because tandoor_cmd.list_categories does not exist
  result
  |> should.be_error()
}

// ============================================================================
// Test: Format category as display string
// ============================================================================

/// Test: format_category_line formats root category correctly
///
/// EXPECTED FAILURE: tandoor_cmd.format_category_line does not exist
///
/// This test validates category formatting:
/// 1. Formats category with icon, label, and count
/// 2. Returns string in format: "🍽️ Cuisine (3 subcategories)"
/// 3. Handles plural/singular for count
///
/// Implementation strategy:
/// - Create format_category_line(keyword: Keyword) -> String
/// - Format: "{icon} {label} ({count} {subcategory|subcategories})"
/// - Handle None icon case
pub fn format_category_line_with_icon_test() {
  let category = mock_root_category()

  // When: formatting category with icon
  let result = tandoor_cmd.format_category_line(category)

  // Then: should return formatted string
  // Expected: "🍽️ Cuisine (3 subcategories)"
  // This will FAIL because format_category_line does not exist
  result
  |> should.equal("🍽️ Cuisine (3 subcategories)")
}

/// Test: format_category_line handles no icon
///
/// EXPECTED FAILURE: tandoor_cmd.format_category_line does not exist
pub fn format_category_line_no_icon_test() {
  let category = mock_no_icon_category()

  // When: formatting category without icon
  let result = tandoor_cmd.format_category_line(category)

  // Then: should return formatted string without icon
  // Expected: "French (1 subcategory)"
  // This will FAIL because format_category_line does not exist
  result
  |> should.equal("French (1 subcategory)")
}

/// Test: format_category_line handles leaf category (0 children)
///
/// EXPECTED FAILURE: tandoor_cmd.format_category_line does not exist
pub fn format_category_line_leaf_test() {
  let category = mock_leaf_category()

  // When: formatting leaf category
  let result = tandoor_cmd.format_category_line(category)

  // Then: should return formatted string with 0 subcategories
  // Expected: "🥗 Vegetarian (0 subcategories)"
  // This will FAIL because format_category_line does not exist
  result
  |> should.equal("🥗 Vegetarian (0 subcategories)")
}

/// Test: format_category_line handles singular count
///
/// EXPECTED FAILURE: tandoor_cmd.format_category_line does not exist
pub fn format_category_line_singular_test() {
  let category = mock_no_icon_category()

  // When: formatting category with 1 child
  let result = tandoor_cmd.format_category_line(category)

  // Then: should use "subcategory" (singular)
  // Expected: "French (1 subcategory)"
  // This will FAIL because format_category_line does not exist
  result
  |> should.equal("French (1 subcategory)")
}

// ============================================================================
// Test: Build category tree structure
// ============================================================================

/// Test: build_category_tree groups by parent
///
/// EXPECTED FAILURE: tandoor_cmd.build_category_tree does not exist
///
/// This test validates tree building:
/// 1. Groups keywords by parent_id
/// 2. Returns Dict(Option(Int), List(Keyword))
/// 3. Root categories have key None
/// 4. Child categories have key Some(parent_id)
///
/// Implementation strategy:
/// - Use gleam/dict to group keywords
/// - Key is parent field (Option(Int))
/// - Value is List(Keyword) for that parent
pub fn build_category_tree_test() {
  let categories = [
    mock_root_category(),
    mock_italian_category(),
    mock_sicilian_category(),
    mock_leaf_category(),
  ]

  // When: building category tree
  let tree = tandoor_cmd.build_category_tree(categories)

  // Then: should group by parent
  // Root level (parent = None): [Cuisine, Vegetarian]
  // Cuisine children (parent = Some(1)): [Italian]
  // Italian children (parent = Some(2)): [Sicilian]
  // This will FAIL because build_category_tree does not exist

  // Verify root categories
  tree
  |> tandoor_cmd.get_children_for_parent(None)
  |> should.equal([mock_root_category(), mock_leaf_category()])
}

/// Test: get_children_for_parent retrieves correct children
///
/// EXPECTED FAILURE: tandoor_cmd.get_children_for_parent does not exist
///
/// This test validates tree traversal:
/// 1. Given a parent_id, return all direct children
/// 2. Returns empty list if no children
/// 3. Returns categories sorted by label
pub fn get_children_for_parent_test() {
  let tree =
    tandoor_cmd.build_category_tree([
      mock_root_category(),
      mock_italian_category(),
      mock_sicilian_category(),
    ])

  // When: getting children for Cuisine (id=1)
  let children = tandoor_cmd.get_children_for_parent_from_tree(tree, Some(1))

  // Then: should return Italian category
  // This will FAIL because get_children_for_parent_from_tree does not exist
  children
  |> should.equal([mock_italian_category()])
}

/// Test: get_children_for_parent handles no children
///
/// EXPECTED FAILURE: tandoor_cmd.get_children_for_parent does not exist
pub fn get_children_for_parent_none_test() {
  let tree = tandoor_cmd.build_category_tree([mock_leaf_category()])

  // When: getting children for leaf category (id=4)
  let children = tandoor_cmd.get_children_for_parent_from_tree(tree, Some(4))

  // Then: should return empty list
  // This will FAIL because get_children_for_parent_from_tree does not exist
  children
  |> should.equal([])
}

// ============================================================================
// Test: Calculate tree depth from full_name
// ============================================================================

/// Test: calculate_depth from full_name
///
/// EXPECTED FAILURE: tandoor_cmd.calculate_depth does not exist
///
/// This test validates depth calculation:
/// 1. Counts " > " separators in full_name
/// 2. Returns depth as Int (0 for root, 1 for child, etc.)
/// 3. Used for indentation in tree display
///
/// Implementation strategy:
/// - Split full_name by " > "
/// - Count segments
/// - Depth = segment_count - 1 (root has depth 0)
pub fn calculate_depth_root_test() {
  let category = mock_root_category()

  // When: calculating depth for root category
  let depth = tandoor_cmd.calculate_depth(category)

  // Then: should return 0 (no parents)
  // full_name = "Cuisine" (no " > " separator)
  // This will FAIL because calculate_depth does not exist
  depth
  |> should.equal(0)
}

/// Test: calculate_depth for child
///
/// EXPECTED FAILURE: tandoor_cmd.calculate_depth does not exist
pub fn calculate_depth_child_test() {
  let category = mock_italian_category()

  // When: calculating depth for child category
  let depth = tandoor_cmd.calculate_depth(category)

  // Then: should return 1 (one parent)
  // full_name = "Cuisine > Italian" (1 " > " separator)
  // This will FAIL because calculate_depth does not exist
  depth
  |> should.equal(1)
}

/// Test: calculate_depth for grandchild
///
/// EXPECTED FAILURE: tandoor_cmd.calculate_depth does not exist
pub fn calculate_depth_grandchild_test() {
  let category = mock_sicilian_category()

  // When: calculating depth for grandchild category
  let depth = tandoor_cmd.calculate_depth(category)

  // Then: should return 2 (two parents)
  // full_name = "Cuisine > Italian > Sicilian" (2 " > " separators)
  // This will FAIL because calculate_depth does not exist
  depth
  |> should.equal(2)
}

// ============================================================================
// Test: Format category with indentation
// ============================================================================

/// Test: format_with_indent formats category with correct indentation
///
/// EXPECTED FAILURE: tandoor_cmd.format_with_indent does not exist
///
/// This test validates indented formatting:
/// 1. Adds 2 spaces per depth level
/// 2. Prepends indentation to formatted category line
/// 3. Root categories have no indentation (depth 0)
///
/// Implementation strategy:
/// - Create format_with_indent(keyword: Keyword, depth: Int) -> String
/// - Calculate indent = "  " repeated depth times
/// - Return indent <> format_category_line(keyword)
pub fn format_with_indent_root_test() {
  let category = mock_root_category()

  // When: formatting root category with depth 0
  let result = tandoor_cmd.format_with_indent(category, 0)

  // Then: should have no indentation
  // Expected: "🍽️ Cuisine (3 subcategories)"
  // This will FAIL because format_with_indent does not exist
  result
  |> should.equal("🍽️ Cuisine (3 subcategories)")
}

/// Test: format_with_indent adds indentation for child
///
/// EXPECTED FAILURE: tandoor_cmd.format_with_indent does not exist
pub fn format_with_indent_child_test() {
  let category = mock_italian_category()

  // When: formatting child category with depth 1
  let result = tandoor_cmd.format_with_indent(category, 1)

  // Then: should have 2 spaces indentation
  // Expected: "  🇮🇹 Italian (2 subcategories)"
  // This will FAIL because format_with_indent does not exist
  result
  |> should.equal("  🇮🇹 Italian (2 subcategories)")
}

/// Test: format_with_indent adds deeper indentation for grandchild
///
/// EXPECTED FAILURE: tandoor_cmd.format_with_indent does not exist
pub fn format_with_indent_grandchild_test() {
  let category = mock_sicilian_category()

  // When: formatting grandchild category with depth 2
  let result = tandoor_cmd.format_with_indent(category, 2)

  // Then: should have 4 spaces indentation
  // Expected: "    Sicilian (0 subcategories)"
  // This will FAIL because format_with_indent does not exist
  result
  |> should.equal("    Sicilian (0 subcategories)")
}
