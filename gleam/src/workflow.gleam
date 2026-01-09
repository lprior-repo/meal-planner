//  Workflow Orchestration
//  Provides abstractions for composing complex workflows from simpler operations
//  Used to coordinate between FatSecret, Tandoor, and local meal planning

import gleam/int
import gleam/list
import gleam/option
import gleam/result

pub type WorkflowStep(a) {
  Step(
    name: String,
    description: String,
    execute: fn() -> result.Result(a, String),
  )
}

pub type Workflow(a) {
  Workflow(
    name: String,
    description: String,
    steps: list.List(WorkflowStep(a)),
  )
}

pub type ExecutionResult(a) {
  ExecutionResult(
    workflow_name: String,
    total_steps: Int,
    succeeded_steps: Int,
    failed_steps: Int,
    result: result.Result(a, String),
  )
}

/// Create a new workflow step
pub fn new_step(
  name: String,
  description: String,
  execute: fn() -> result.Result(a, String),
) -> WorkflowStep(a) {
  Step(name, description, execute)
}

/// Create a new workflow from steps
pub fn new_workflow(
  name: String,
  description: String,
  steps: list.List(WorkflowStep(a)),
) -> Workflow(a) {
  Workflow(name, description, steps)
}

/// Execute a workflow and return results
pub fn execute(workflow: Workflow(a)) -> ExecutionResult(a) {
  let step_count = list.length(workflow.steps)
  ExecutionResult(
    workflow_name: workflow.name,
    total_steps: step_count,
    succeeded_steps: 0,
    failed_steps: 0,
    result: Error("Workflow execution not yet implemented"),
  )
}

/// Common workflow: Import recipe from Tandoor to FatSecret
pub fn import_recipe_workflow(
  recipe_name: String,
  recipe_id: Int,
) -> Workflow(String) {
  Workflow(
    name: "Import Recipe: " <> recipe_name,
    description: "Import recipe from Tandoor to FatSecret database",
    steps: [
      new_step(
        "fetch-recipe",
        "Fetch recipe details from Tandoor",
        fn() { Ok("Recipe fetched") },
      ),
      new_step(
        "extract-nutrition",
        "Calculate nutrition facts",
        fn() { Ok("Nutrition calculated") },
      ),
      new_step(
        "create-fatsecret-recipe",
        "Create recipe in FatSecret database",
        fn() { Ok("Recipe created") },
      ),
    ],
  )
}

/// Common workflow: Plan meals for a date range
pub fn meal_planning_workflow(
  start_date: Int,
  end_date: Int,
) -> Workflow(String) {
  Workflow(
    name: "Meal Plan: " <> int.to_string(start_date) <> " to " <> int.to_string(end_date),
    description: "Generate meal plan for specified date range",
    steps: [
      new_step(
        "fetch-recipes",
        "Fetch available recipes",
        fn() { Ok("Recipes fetched") },
      ),
      new_step(
        "calculate-nutrition",
        "Calculate nutrition requirements",
        fn() { Ok("Nutrition calculated") },
      ),
      new_step(
        "generate-plan",
        "Generate optimal meal plan",
        fn() { Ok("Plan generated") },
      ),
      new_step(
        "create-grocery-list",
        "Create grocery list from plan",
        fn() { Ok("Grocery list created") },
      ),
    ],
  )
}
