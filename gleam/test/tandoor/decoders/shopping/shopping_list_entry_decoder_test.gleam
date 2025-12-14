/// Shopping List Entry Decoder Tests
///
/// Tests for decoding shopping list entries from Tandoor API responses.
import gleam/dynamic/decode
import gleam/json
import gleam/option.{None, Some}
import gleeunit/should
import meal_planner/tandoor/decoders/shopping/shopping_list_entry_decoder.{
  type ShoppingListEntryResponse, ShoppingListEntryResponse,
}

/// Test decoding a complete shopping list entry with all fields populated
pub fn decode_entry_complete_test() {
  let json_str =
    "{
      \"id\": 1,
      \"list_recipe\": 5,
      \"food\": {
        \"id\": 10,
        \"name\": \"Tomato\",
        \"plural_name\": \"Tomatoes\",
        \"description\": \"Fresh red tomatoes\",
        \"recipe\": null,
        \"food_onhand\": true,
        \"supermarket_category\": null,
        \"ignore_shopping\": false
      },
      \"unit\": {
        \"id\": 2,
        \"name\": \"piece\",
        \"plural_name\": \"pieces\",
        \"description\": null,
        \"base_unit\": null,
        \"open_data_slug\": null
      },
      \"amount\": 3.0,
      \"order\": 0,
      \"checked\": false,
      \"created_at\": \"2025-12-14T12:00:00Z\",
      \"completed_at\": null
    }"

  let result =
    json.decode(
      from: json_str,
      using: shopping_list_entry_decoder.decode_entry(),
    )

  case result {
    Ok(entry) -> {
      // Verify entry fields
      entry.id |> should.equal(1)
      entry.list_recipe |> should.equal(Some(5))
      entry.amount |> should.equal(3.0)
      entry.order |> should.equal(0)
      entry.checked |> should.equal(False)
      entry.created_at |> should.equal("2025-12-14T12:00:00Z")
      entry.completed_at |> should.equal(None)

      // Verify nested food object
      case entry.food {
        Some(food) -> {
          food.id |> should.equal(10)
          food.name |> should.equal("Tomato")
          food.plural_name |> should.equal(Some("Tomatoes"))
          food.description |> should.equal("Fresh red tomatoes")
          food.ignore_shopping |> should.equal(False)
        }
        None -> should.fail("Expected food to be present")
      }

      // Verify nested unit object
      case entry.unit {
        Some(unit) -> {
          unit.id |> should.equal(2)
          unit.name |> should.equal("piece")
          unit.plural_name |> should.equal(Some("pieces"))
        }
        None -> should.fail("Expected unit to be present")
      }
    }
    Error(errors) -> {
      should.fail(
        "Failed to decode shopping list entry: "
        <> decode.errors_to_string(errors),
      )
    }
  }
}

/// Test decoding entry with minimal fields (nulls for optional data)
pub fn decode_entry_minimal_test() {
  let json_str =
    "{
      \"id\": 2,
      \"list_recipe\": null,
      \"food\": null,
      \"unit\": null,
      \"amount\": 1.5,
      \"order\": 1,
      \"checked\": true,
      \"created_at\": \"2025-12-14T13:00:00Z\",
      \"completed_at\": \"2025-12-14T13:30:00Z\"
    }"

  let result =
    json.decode(
      from: json_str,
      using: shopping_list_entry_decoder.decode_entry(),
    )

  case result {
    Ok(entry) -> {
      entry.id |> should.equal(2)
      entry.list_recipe |> should.equal(None)
      entry.food |> should.equal(None)
      entry.unit |> should.equal(None)
      entry.amount |> should.equal(1.5)
      entry.order |> should.equal(1)
      entry.checked |> should.equal(True)
      entry.created_at |> should.equal("2025-12-14T13:00:00Z")
      entry.completed_at |> should.equal(Some("2025-12-14T13:30:00Z"))
    }
    Error(errors) -> {
      should.fail(
        "Failed to decode minimal entry: " <> decode.errors_to_string(errors),
      )
    }
  }
}

/// Test decoding a list of entries from paginated response
pub fn decode_entry_list_test() {
  let json_str =
    "{
      \"results\": [
        {
          \"id\": 1,
          \"list_recipe\": null,
          \"food\": null,
          \"unit\": null,
          \"amount\": 2.0,
          \"order\": 0,
          \"checked\": false,
          \"created_at\": \"2025-12-14T10:00:00Z\",
          \"completed_at\": null
        },
        {
          \"id\": 2,
          \"list_recipe\": null,
          \"food\": null,
          \"unit\": null,
          \"amount\": 1.0,
          \"order\": 1,
          \"checked\": true,
          \"created_at\": \"2025-12-14T11:00:00Z\",
          \"completed_at\": \"2025-12-14T11:30:00Z\"
        }
      ]
    }"

  let result =
    json.decode(
      from: json_str,
      using: shopping_list_entry_decoder.decode_entry_list(),
    )

  case result {
    Ok(entries) -> {
      // Verify we got 2 entries
      entries |> should.have_length(2)

      // Verify first entry
      let assert [first, second] = entries
      first.id |> should.equal(1)
      first.checked |> should.equal(False)
      first.amount |> should.equal(2.0)

      // Verify second entry
      second.id |> should.equal(2)
      second.checked |> should.equal(True)
      second.amount |> should.equal(1.0)
      second.completed_at |> should.equal(Some("2025-12-14T11:30:00Z"))
    }
    Error(errors) -> {
      should.fail(
        "Failed to decode entry list: " <> decode.errors_to_string(errors),
      )
    }
  }
}

/// Test decoding empty results list
pub fn decode_entry_list_empty_test() {
  let json_str = "{\"results\": []}"

  let result =
    json.decode(
      from: json_str,
      using: shopping_list_entry_decoder.decode_entry_list(),
    )

  case result {
    Ok(entries) -> {
      entries |> should.have_length(0)
    }
    Error(errors) -> {
      should.fail(
        "Failed to decode empty list: " <> decode.errors_to_string(errors),
      )
    }
  }
}
