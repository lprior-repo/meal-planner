/// Core types for the meal planner application

/// Macros represents nutritional macronutrients per serving
pub type Macros {
  Macros(protein: Float, fat: Float, carbs: Float)
}

/// Calculate total calories from macros
/// Uses: 4cal/g protein, 9cal/g fat, 4cal/g carbs
pub fn macros_calories(m: Macros) -> Float {
  { m.protein *. 4.0 } +. { m.fat *. 9.0 } +. { m.carbs *. 4.0 }
}

/// Add two Macros together
pub fn macros_add(a: Macros, b: Macros) -> Macros {
  Macros(
    protein: a.protein +. b.protein,
    fat: a.fat +. b.fat,
    carbs: a.carbs +. b.carbs,
  )
}

/// Scale macros by a factor
pub fn macros_scale(m: Macros, factor: Float) -> Macros {
  Macros(
    protein: m.protein *. factor,
    fat: m.fat *. factor,
    carbs: m.carbs *. factor,
  )
}
