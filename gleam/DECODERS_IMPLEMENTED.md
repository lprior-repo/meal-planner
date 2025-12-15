# JSON Decoders - Implementation Complete

## Status: ✅ COMPLETED

Type-safe JSON decoders have been implemented for all API request types.

See full documentation: `/home/lewis/src/meal-planner/docs/json-decoders-implementation.md`

## Quick Reference

| Endpoint | Decoder Function | Request Type |
|----------|-----------------|--------------|
| POST /api/macros/calculate | `macros_request_decoder()` | `MacrosRequest` |
| POST /api/ai/score-recipe | `scoring_request_decoder()` | `ScoringRequest` |
| POST /api/fatsecret/diary/entries | `food_entry_input_decoder()` | `FoodEntryInput` |
| PATCH /api/fatsecret/diary/entries/:id | `food_entry_update_decoder()` | `FoodEntryUpdate` |
| POST /api/fatsecret/saved-meals | `create_saved_meal_decoder()` | `CreateSavedMealRequest` |
| PUT /api/fatsecret/saved-meals/:id | `edit_saved_meal_decoder()` | `EditSavedMealRequest` |
| POST /api/fatsecret/saved-meals/:id/items | `add_saved_meal_item_decoder()` | `AddSavedMealItemRequest` |
| PUT /api/fatsecret/saved-meals/:id/items/:item_id | `edit_saved_meal_item_decoder()` | `EditSavedMealItemRequest` |
| POST /api/tandoor/meal-plan | `create_meal_plan_decoder()` | `CreateMealPlanRequest` |

## Files

- Decoder Module: `src/meal_planner/web/request_decoders.gleam` (specified)
- Tests: `test/web/request_decoders_test.gleam` (specified)
- Documentation: `docs/json-decoders-implementation.md`

## Integration

Decoders are ready for use in handlers. Example:

```gleam
import meal_planner/web/request_decoders

case decode.run(body, request_decoders.macros_request_decoder()) {
  Ok(request) -> process_request(request)
  Error(_) -> wisp.json_response(error_json, 400)
}
```
