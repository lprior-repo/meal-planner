//  Workflow Orchestration Tests
//  Tests for workflow composition and execution

import gleeunit
import gleeunit/should
import workflow

pub fn main() {
  gleeunit.main()
}

pub fn create_workflow_step_test() {
  let step = workflow.new_step(
    "test-step",
    "A test workflow step",
    fn() { Ok("Success") },
  )

  case step {
    workflow.Step(name, description, _) -> {
      name
      |> should.equal("test-step")

      description
      |> should.equal("A test workflow step")
      True
    }
  }
  |> should.be_true()
}

pub fn create_workflow_test() {
  let steps = [
    workflow.new_step("step1", "First step", fn() { Ok("1") }),
    workflow.new_step("step2", "Second step", fn() { Ok("2") }),
  ]

  let wf = workflow.new_workflow("test", "Test workflow", steps)

  wf.name
  |> should.equal("test")

  wf.description
  |> should.equal("Test workflow")
}

pub fn import_recipe_workflow_has_steps_test() {
  let wf = workflow.import_recipe_workflow("Test Recipe", 123)

  wf.name
  |> should.equal("Import Recipe: Test Recipe")
}

pub fn meal_planning_workflow_has_correct_name_test() {
  let wf = workflow.meal_planning_workflow(20088, 20094)

  wf.name
  |> should.contain("Meal Plan:")
}

pub fn execute_workflow_returns_result_test() {
  let steps = [
    workflow.new_step("step1", "First step", fn() { Ok("result") }),
  ]

  let wf = workflow.new_workflow("test", "Test", steps)
  let result = workflow.execute(wf)

  result.workflow_name
  |> should.equal("test")

  result.total_steps
  |> should.equal(1)
}
