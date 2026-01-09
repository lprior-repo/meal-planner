//  Meal Planner Automation Framework
//  A comprehensive Gleam-based automation layer for the meal-planner project
//
//  This module provides the core framework for:
//  - FatSecret API integration (OAuth, nutrition data)
//  - Tandoor recipe management
//  - Workflow orchestration
//  - CLI command handling

import gleam/list
import gleam/io
import gleam/erlang/process
import cli

pub const version = "0.1.0"

/// Main entry point for the meal-planner automation
pub fn main() {
  let args = list.drop(process.arguments(), 1)
  args
  |> cli.parse_args
  |> cli.execute
  |> cli.format_result
  |> io.println
}
