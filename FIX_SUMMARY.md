# Compilation Errors in client.gleam - Root Cause and Fix

## Problem
Type duplication across multiple modules causes type mismatches:
- `types/base.gleam` defines `ClientConfig`, `TandoorError`, `AuthMethod`, `ApiResponse`
- `client.gleam` ALSO defines these types (duplicate)
- `recipe.gleam` imports from `types/base.gleam`  
- CLI domain imports from `client.gleam`
- When CLI passes `client.ClientConfig` to recipe functions, type mismatch occurs

## Required Fix

### File: src/meal_planner/tandoor/client.gleam

1. **Remove duplicate type definitions** (lines ~40-231):
   - `pub type HttpMethod`
   - `pub type TandoorError`
   - `pub type AuthMethod`
   - `pub type ClientConfig`
   - `pub type ApiResponse`
   - Config functions: `session_config`, `bearer_config`, `default_config`, `with_timeout`, `with_retry_config`
   - Helper function: `with_session`

2. **Add import of types from `types/base.gleam`**:
   ```gleam
   import meal_planner/tandoor/types/base.{
     type AuthMethod,
     type ClientConfig,
     type TandoorError,
     type ApiResponse,
     AuthenticationError,
     AuthorizationError,
     BadRequestError,
     BearerAuth,
     NetworkError,
     NotFoundError,
     ParseError,
     ServerError,
     SessionAuth,
     TimeoutError,
     UnknownError,
   }
   ```

3. **Keep only session authentication functions**:
   - `build_login_page_request`
   - `build_login_post_request`
   - `login`
   - `parse_csrf_from_html`
   - `extract_csrf_from_cookies`
   - `extract_session_from_cookies`
   - `add_auth_headers`
   - `base64_encode` / `do_base64_encode`
   - `add_json_headers`
   - `build_request_from_url`
   - `build_query_string`
   - `uri_encode`
   - Request building functions (`build_get_request`, `build_post_request`, etc.)
   - Request execution functions (`execute_request`, `execute_and_parse`)
   - Response parsing functions (`parse_response`, `parse_json_body`)
   - Error handling functions (`is_transient_error`, `error_to_string`)
   - Recipe API functions (`get_recipes`, `get_recipe_by_id`, etc.)
   - Decoders (keep local definitions that reference other modules)
   - Recipe type aliases (keep using imports)

## Alternative Quick Fixes

### Option A: Fix CLI imports (Quickest)
Change `src/meal_planner/cli/domains/tandoor.gleam`:
- Replace: `import meal_planner/tandoor/client`
- With: `import meal_planner/tandoor/types/base`

### Option B: Fix recipe imports (Better architecture)  
Change `src/meal_planner/tandoor/recipe.gleam`:
- Replace: `import ... types/base.{type ClientConfig, type TandoorError}`
- With: `import ... client.{type ClientConfig, type TandoorError}`

### Option C: Fix client to re-export from base (Best architecture)
Complete removal of duplicate types from `client.gleam` as described above.

## Recommendation

Use **Option A** for immediate fix as it's minimal change.
Use **Option C** for proper long-term architecture.

