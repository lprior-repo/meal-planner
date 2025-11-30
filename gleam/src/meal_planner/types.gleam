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

/// Activity level for calorie/macro calculations
pub type ActivityLevel {
  Sedentary
  Moderate
  Active
}

/// Fitness goal for calorie adjustments
pub type Goal {
  Gain
  Maintain
  Lose
}

/// User profile for personalized nutrition targets
pub type UserProfile {
  UserProfile(
    bodyweight: Float,
    activity_level: ActivityLevel,
    goal: Goal,
    meals_per_day: Int,
  )
}

/// Calculate daily protein target (0.8-1g per lb bodyweight)
/// Higher end for active/gain, lower for sedentary/lose
pub fn daily_protein_target(u: UserProfile) -> Float {
  let multiplier = case u.activity_level, u.goal {
    Active, _ -> 1.0
    _, Gain -> 1.0
    Sedentary, _ -> 0.8
    _, Lose -> 0.8
    _, _ -> 0.9
  }
  u.bodyweight *. multiplier
}

/// Calculate daily fat target (0.3g per lb bodyweight)
pub fn daily_fat_target(u: UserProfile) -> Float {
  u.bodyweight *. 0.3
}

/// Calculate daily calorie target based on activity and goal
pub fn daily_calorie_target(u: UserProfile) -> Float {
  // Base: cal/lb based on activity level
  let base_multiplier = case u.activity_level {
    Sedentary -> 12.0
    Moderate -> 15.0
    Active -> 18.0
  }

  let base = u.bodyweight *. base_multiplier

  // Adjust for goal
  case u.goal {
    Gain -> base *. 1.15
    Lose -> base *. 0.85
    Maintain -> base
  }
}

/// Calculate daily carb target based on remaining calories
/// After protein (4cal/g) and fat (9cal/g), fill rest with carbs (4cal/g)
pub fn daily_carb_target(u: UserProfile) -> Float {
  let total_calories = daily_calorie_target(u)
  let protein_calories = daily_protein_target(u) *. 4.0
  let fat_calories = daily_fat_target(u) *. 9.0
  let remaining = total_calories -. protein_calories -. fat_calories
  case remaining <. 0.0 {
    True -> 0.0
    False -> remaining /. 4.0
  }
}

/// Calculate complete daily macro targets
pub fn daily_macro_targets(u: UserProfile) -> Macros {
  Macros(
    protein: daily_protein_target(u),
    fat: daily_fat_target(u),
    carbs: daily_carb_target(u),
  )
}
