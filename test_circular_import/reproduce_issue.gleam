// Test file to reproduce circular import issue in Tandoor package
// This file attempts to import the problematic modules to trigger the circular dependency error

import meal_planner/tandoor/client
import meal_planner/tandoor/food
import meal_planner/tandoor/ingredient

pub fn main() {
  // Just trying to import and reference the modules to trigger compilation error
  let _ingredient = ingredient
  let _food = food
  let _client = client
  "Test completed - if we get here, no circular import error occurred"
}
