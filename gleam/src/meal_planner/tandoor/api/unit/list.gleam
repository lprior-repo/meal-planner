/// Unit List API
///
/// This module provides functions to list units from the Tandoor API
/// with pagination support.
import gleam/option.{type Option}
import meal_planner/tandoor/client.{type ClientConfig, type TandoorError}
import meal_planner/tandoor/core/pagination.{type PaginatedResponse}
import meal_planner/tandoor/types/unit/unit.{type Unit}

/// List units from Tandoor API with pagination
///
/// # Arguments
/// * `config` - Client configuration with authentication
/// * `limit` - Optional number of results per page
/// * `offset` - Optional offset for pagination
///
/// # Returns
/// Result with paginated unit list or error
///
/// # Example
/// ```gleam
/// let config = client.bearer_config("http://localhost:8000", "token")
/// let result = list_units(config, limit: Some(25), offset: Some(0))
/// ```
pub fn list_units(
  config: ClientConfig,
  limit _limit: Option(Int),
  offset _offset: Option(Int),
) -> Result(PaginatedResponse(Unit), TandoorError) {
  // TODO: Implement when client helpers are available
  // For now, this placeholder ensures type signature is correct
  let _config = config
  Error(client.NetworkError("Not implemented yet"))
}
