import gleam/list
import gleam/result
import gleeunit/should
import meal_planner/ncp
import shared/types.{Macros}

pub fn recipe_scoring_test() {
  let deviation =
    ncp.DeviationResult(
      protein_pct: -15.0,
      fat_pct: -5.0,
      carbs_pct: 0.0,
      calories_pct: -10.0,
    )

  let high_protein_macros = Macros(protein: 30.0, fat: 10.0, carbs: 20.0)
  let low_protein_macros = Macros(protein: 5.0, fat: 10.0, carbs: 20.0)

  // Test scoring high protein recipe for protein deficit
  let high_protein_score =
    ncp.score_recipe_for_deviation(deviation, high_protein_macros)
  // High protein recipe should score well for protein deficit
  should.be_true(high_protein_score >. 0.3)

  // Test scoring low protein recipe for protein deficit
  let low_protein_score =
    ncp.score_recipe_for_deviation(deviation, low_protein_macros)
  // Low protein recipe should score lower
  should.be_true(low_protein_score <. high_protein_score)

  // Test recipe selection
  let recipes = [
    ncp.ScoredRecipe(name: "High Protein", macros: high_protein_macros),
    ncp.ScoredRecipe(name: "Low Protein", macros: low_protein_macros),
  ]

  let suggestions = ncp.select_top_recipes(deviation, recipes, 2)
  suggestions
  |> list.length
  |> should.equal(2)

  let first_suggestion =
    list.first(suggestions)
    |> result.unwrap(ncp.RecipeSuggestion(
      recipe_name: "",
      reason: "",
      score: 0.0,
    ))
  first_suggestion.recipe_name
  |> should.equal("High Protein")
}
