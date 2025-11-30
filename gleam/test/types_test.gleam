import gleeunit/should
import meal_planner/types.{Macros, macros_calories, macros_add, macros_scale}

pub fn macros_calories_test() {
  // 4cal/g protein, 9cal/g fat, 4cal/g carbs
  let m = Macros(protein: 30.0, fat: 10.0, carbs: 50.0)
  // (30 * 4) + (10 * 9) + (50 * 4) = 120 + 90 + 200 = 410
  macros_calories(m)
  |> should.equal(410.0)
}

pub fn macros_calories_zero_test() {
  let m = Macros(protein: 0.0, fat: 0.0, carbs: 0.0)
  macros_calories(m)
  |> should.equal(0.0)
}

pub fn macros_add_test() {
  let m1 = Macros(protein: 20.0, fat: 10.0, carbs: 30.0)
  let m2 = Macros(protein: 15.0, fat: 5.0, carbs: 25.0)
  let result = macros_add(m1, m2)
  result.protein |> should.equal(35.0)
  result.fat |> should.equal(15.0)
  result.carbs |> should.equal(55.0)
}

pub fn macros_scale_test() {
  let m = Macros(protein: 10.0, fat: 5.0, carbs: 20.0)
  let result = macros_scale(m, 2.0)
  result.protein |> should.equal(20.0)
  result.fat |> should.equal(10.0)
  result.carbs |> should.equal(40.0)
}
