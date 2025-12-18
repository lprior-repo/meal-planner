import gleam/list
import gleam/option.{None, Some}
import gleeunit/should
import meal_planner/tandoor/core/ids
import meal_planner/tandoor/property.{FoodProperty, Property}
import meal_planner/tandoor/supermarket.{SupermarketCategory}
import meal_planner/tandoor/types/food/food_inherit_field.{FoodInheritField}
import meal_planner/tandoor/unit.{Unit}
import meal_planner/tandoor/food.{Food}

pub fn food_full_constructor_test() {
  let food =
    Food(
      id: ids.food_id_from_int(1),
      name: "Tomato",
      plural_name: Some("Tomatoes"),
      description: "Fresh red tomatoes",
      recipe: None,
      food_onhand: Some(True),
      supermarket_category: Some(SupermarketCategory(
        id: 1,
        name: "Produce",
        description: Some("Fresh produce section"),
        open_data_slug: None,
      )),
      ignore_shopping: False,
      shopping: "Fresh tomatoes",
      url: Some("https://example.com/tomato"),
      properties: Some([
        Property(
          id: ids.property_id_from_int(1),
          name: "Allergen",
          description: "Contains peanuts",
          property_type: FoodProperty,
          unit: None,
          order: 1,
          created_at: "2025-01-01T00:00:00Z",
          updated_at: "2025-01-01T00:00:00Z",
        ),
      ]),
      properties_food_amount: 100.0,
      properties_food_unit: Some(Unit(
        id: 1,
        name: "gram",
        plural_name: Some("grams"),
        description: Some("Unit of mass"),
        base_unit: None,
        open_data_slug: None,
      )),
      fdc_id: Some(123456),
      parent: Some(2),
      numchild: 0,
      inherit_fields: Some([
        FoodInheritField(id: 1, name: "Nutrition", field: "nutrition"),
      ]),
      full_name: "Vegetables > Tomato",
    )

  food.id
  |> should.not_equal(ids.food_id_from_int(999))

  food.name
  |> should.equal("Tomato")

  food.plural_name
  |> should.equal(Some("Tomatoes"))

  food.shopping
  |> should.equal("Fresh tomatoes")

  food.url
  |> should.equal(Some("https://example.com/tomato"))

  food.fdc_id
  |> should.equal(Some(123456))

  food.parent
  |> should.equal(Some(2))

  food.numchild
  |> should.equal(0)

  food.full_name
  |> should.equal("Vegetables > Tomato")
}

pub fn food_minimal_test() {
  let food =
    Food(
      id: ids.food_id_from_int(2),
      name: "Carrot",
      plural_name: None,
      description: "Orange root vegetable",
      recipe: None,
      food_onhand: None,
      supermarket_category: None,
      ignore_shopping: False,
      shopping: "",
      url: None,
      properties: None,
      properties_food_amount: 0.0,
      properties_food_unit: None,
      fdc_id: None,
      parent: None,
      numchild: 0,
      inherit_fields: None,
      full_name: "Vegetables > Carrot",
    )

  food.name
  |> should.equal("Carrot")

  food.plural_name
  |> should.equal(None)

  food.shopping
  |> should.equal("")

  food.url
  |> should.equal(None)

  food.properties
  |> should.equal(None)

  food.fdc_id
  |> should.equal(None)

  food.parent
  |> should.equal(None)
}

pub fn food_properties_field_test() {
  let food =
    Food(
      id: ids.food_id_from_int(3),
      name: "Peanuts",
      plural_name: Some("Peanuts"),
      description: "Legume",
      recipe: None,
      food_onhand: Some(False),
      supermarket_category: Some(SupermarketCategory(
        id: 2,
        name: "Nuts & Seeds",
        description: None,
        open_data_slug: None,
      )),
      ignore_shopping: True,
      shopping: "Roasted peanuts",
      url: Some("https://example.com/peanuts"),
      properties: Some([
        Property(
          id: ids.property_id_from_int(2),
          name: "Major Allergen",
          description: "Tree nut allergen",
          property_type: FoodProperty,
          unit: Some("severity"),
          order: 1,
          created_at: "2025-01-01T00:00:00Z",
          updated_at: "2025-01-02T00:00:00Z",
        ),
        Property(
          id: ids.property_id_from_int(3),
          name: "Organic",
          description: "Certified organic",
          property_type: FoodProperty,
          unit: None,
          order: 2,
          created_at: "2025-01-01T00:00:00Z",
          updated_at: "2025-01-02T00:00:00Z",
        ),
      ]),
      properties_food_amount: 150.0,
      properties_food_unit: Some(Unit(
        id: 2,
        name: "ounce",
        plural_name: Some("ounces"),
        description: Some("Unit of weight"),
        base_unit: Some("gram"),
        open_data_slug: None,
      )),
      fdc_id: Some(789012),
      parent: Some(5),
      numchild: 2,
      inherit_fields: Some([
        FoodInheritField(id: 1, name: "Nutrition", field: "nutrition"),
        FoodInheritField(id: 2, name: "Allergens", field: "allergens"),
      ]),
      full_name: "Nuts & Seeds > Peanuts",
    )

  food.properties
  |> should.not_equal(None)

  case food.properties {
    Some(props) -> {
      list.length(props)
      |> should.equal(2)
    }
    None -> {
      should.fail()
    }
  }

  food.properties_food_amount
  |> should.equal(150.0)

  food.inherit_fields
  |> should.not_equal(None)

  food.ignore_shopping
  |> should.equal(True)
}
