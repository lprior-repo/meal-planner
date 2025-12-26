/// Micronutrient types and operations
///
/// This module has been decomposed into a focused submodule:
/// - micronutrients/core.gleam: Opaque type definition and ALL operations
///
/// This file serves as a facade maintaining backward compatibility.
///
/// SPECIAL CASE: Due to Gleam's opaque type requirements, all functionality
/// must remain in the same module (core.gleam) as the opaque type definition.
/// This facade simply re-exports everything from core.
import gleam/dynamic/decode.{type Decoder}
import gleam/json.{type Json}
import gleam/option.{type Option}
import meal_planner/types/micronutrients/core

// Re-export type
pub type Micronutrients =
  core.Micronutrients

// Re-export type alias
pub type MicronutrientGoals =
  core.MicronutrientGoals

// Re-export constructor functions
pub fn new(
  fiber: Option(Float),
  sugar: Option(Float),
  sodium: Option(Float),
  cholesterol: Option(Float),
  vitamin_a: Option(Float),
  vitamin_c: Option(Float),
  vitamin_d: Option(Float),
  vitamin_e: Option(Float),
  vitamin_k: Option(Float),
  vitamin_b6: Option(Float),
  vitamin_b12: Option(Float),
  folate: Option(Float),
  thiamin: Option(Float),
  riboflavin: Option(Float),
  niacin: Option(Float),
  calcium: Option(Float),
  iron: Option(Float),
  magnesium: Option(Float),
  phosphorus: Option(Float),
  potassium: Option(Float),
  zinc: Option(Float),
) -> Result(Micronutrients, String) {
  core.new(
    fiber,
    sugar,
    sodium,
    cholesterol,
    vitamin_a,
    vitamin_c,
    vitamin_d,
    vitamin_e,
    vitamin_k,
    vitamin_b6,
    vitamin_b12,
    folate,
    thiamin,
    riboflavin,
    niacin,
    calcium,
    iron,
    magnesium,
    phosphorus,
    potassium,
    zinc,
  )
}

pub fn new_unchecked(
  fiber: Option(Float),
  sugar: Option(Float),
  sodium: Option(Float),
  cholesterol: Option(Float),
  vitamin_a: Option(Float),
  vitamin_c: Option(Float),
  vitamin_d: Option(Float),
  vitamin_e: Option(Float),
  vitamin_k: Option(Float),
  vitamin_b6: Option(Float),
  vitamin_b12: Option(Float),
  folate: Option(Float),
  thiamin: Option(Float),
  riboflavin: Option(Float),
  niacin: Option(Float),
  calcium: Option(Float),
  iron: Option(Float),
  magnesium: Option(Float),
  phosphorus: Option(Float),
  potassium: Option(Float),
  zinc: Option(Float),
) -> Micronutrients {
  core.new_unchecked(
    fiber,
    sugar,
    sodium,
    cholesterol,
    vitamin_a,
    vitamin_c,
    vitamin_d,
    vitamin_e,
    vitamin_k,
    vitamin_b6,
    vitamin_b12,
    folate,
    thiamin,
    riboflavin,
    niacin,
    calcium,
    iron,
    magnesium,
    phosphorus,
    potassium,
    zinc,
  )
}

// Re-export accessor functions
pub fn fiber(m: Micronutrients) -> Option(Float) {
  core.fiber(m)
}

pub fn sugar(m: Micronutrients) -> Option(Float) {
  core.sugar(m)
}

pub fn sodium(m: Micronutrients) -> Option(Float) {
  core.sodium(m)
}

pub fn cholesterol(m: Micronutrients) -> Option(Float) {
  core.cholesterol(m)
}

pub fn vitamin_a(m: Micronutrients) -> Option(Float) {
  core.vitamin_a(m)
}

pub fn vitamin_c(m: Micronutrients) -> Option(Float) {
  core.vitamin_c(m)
}

pub fn vitamin_d(m: Micronutrients) -> Option(Float) {
  core.vitamin_d(m)
}

pub fn vitamin_e(m: Micronutrients) -> Option(Float) {
  core.vitamin_e(m)
}

pub fn vitamin_k(m: Micronutrients) -> Option(Float) {
  core.vitamin_k(m)
}

pub fn vitamin_b6(m: Micronutrients) -> Option(Float) {
  core.vitamin_b6(m)
}

pub fn vitamin_b12(m: Micronutrients) -> Option(Float) {
  core.vitamin_b12(m)
}

pub fn folate(m: Micronutrients) -> Option(Float) {
  core.folate(m)
}

pub fn thiamin(m: Micronutrients) -> Option(Float) {
  core.thiamin(m)
}

pub fn riboflavin(m: Micronutrients) -> Option(Float) {
  core.riboflavin(m)
}

pub fn niacin(m: Micronutrients) -> Option(Float) {
  core.niacin(m)
}

pub fn calcium(m: Micronutrients) -> Option(Float) {
  core.calcium(m)
}

pub fn iron(m: Micronutrients) -> Option(Float) {
  core.iron(m)
}

pub fn magnesium(m: Micronutrients) -> Option(Float) {
  core.magnesium(m)
}

pub fn phosphorus(m: Micronutrients) -> Option(Float) {
  core.phosphorus(m)
}

pub fn potassium(m: Micronutrients) -> Option(Float) {
  core.potassium(m)
}

pub fn zinc(m: Micronutrients) -> Option(Float) {
  core.zinc(m)
}

// Re-export factory functions
pub fn fda_rda_defaults() -> MicronutrientGoals {
  core.fda_rda_defaults()
}

pub fn zero() -> Micronutrients {
  core.zero()
}

// Re-export operation functions
pub fn add(a: Micronutrients, b: Micronutrients) -> Micronutrients {
  core.add(a, b)
}

pub fn scale(m: Micronutrients, factor: Float) -> Micronutrients {
  core.scale(m, factor)
}

pub fn sum(micros: List(Micronutrients)) -> Micronutrients {
  core.sum(micros)
}

// Re-export JSON functions
pub fn to_json(m: Micronutrients) -> Json {
  core.to_json(m)
}

pub fn decoder() -> Decoder(Micronutrients) {
  core.decoder()
}
