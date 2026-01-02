#!/usr/bin/env nu
# Generate Rust types from CUE schema using typify
# Usage: nu scripts/gen_rust_types.nu

# First, export CUE to JSON Schema format
let cue_def = (cue export schemas/cue/fatsecret/api.cue --out json 2>/dev/null | from json)

# Create JSON Schema for typify
# We need to transform CUE definitions to JSON Schema format
let json_schema = {
    "\$schema": "http://json-schema.org/draft-07/schema#"
    title: "FatSecret API"
    type: "object"
    definitions: {
        DateInt: {
            type: "integer"
            minimum: 0
        }
        FoodId: {
            type: "string"
            pattern: "^[0-9]+\$"
        }
        ServingId: {
            type: "string"
            pattern: "^[0-9]+\$"
        }
        FoodEntryId: {
            type: "string"
            pattern: "^[0-9]+\$"
        }
        MealType: {
            type: "string"
            enum: ["breakfast", "lunch", "dinner", "other", "snack"]
        }
        FoodType: {
            type: "string"
            enum: ["Generic", "Brand"]
        }
        NutritionData: {
            type: "object"
            properties: {
                calories: {type: "number"}
                fat: {type: "number"}
                saturated_fat: {type: "number"}
                trans_fat: {type: "number"}
                polyunsaturated_fat: {type: "number"}
                monounsaturated_fat: {type: "number"}
                cholesterol: {type: "number"}
                sodium: {type: "number"}
                carbohydrate: {type: "number"}
                fiber: {type: "number"}
                sugar: {type: "number"}
                protein: {type: "number"}
            }
        }
        FoodEntry: {
            type: "object"
            required: ["food_entry_id", "food_id", "food_entry_name", "serving_id", "number_of_units", "meal", "date_int", "calories", "carbohydrate", "protein", "fat"]
            properties: {
                food_entry_id: {\$ref: "#/definitions/FoodEntryId"}
                food_id: {\$ref: "#/definitions/FoodId"}
                food_entry_name: {type: "string"}
                serving_id: {\$ref: "#/definitions/ServingId"}
                number_of_units: {type: "number"}
                meal: {\$ref: "#/definitions/MealType"}
                date_int: {\$ref: "#/definitions/DateInt"}
                calories: {type: "number"}
                carbohydrate: {type: "number"}
                protein: {type: "number"}
                fat: {type: "number"}
            }
        }
        FoodsSearchV3Input: {
            type: "object"
            required: ["search_expression"]
            properties: {
                search_expression: {type: "string"}
                page_number: {type: "integer", minimum: 0}
                max_results: {type: "integer", maximum: 50}
                include_sub_categories: {type: "boolean"}
                include_food_images: {type: "boolean"}
                include_food_attributes: {type: "boolean"}
                flag_default_serving: {type: "boolean"}
                region: {type: "string"}
                language: {type: "string"}
                format: {type: "string", enum: ["json", "xml"]}
            }
        }
        FoodEntryCreateInput: {
            type: "object"
            required: ["food_id", "food_entry_name", "serving_id", "number_of_units", "meal"]
            properties: {
                food_id: {\$ref: "#/definitions/FoodId"}
                food_entry_name: {type: "string"}
                serving_id: {\$ref: "#/definitions/ServingId"}
                number_of_units: {type: "number", minimum: 0}
                meal: {\$ref: "#/definitions/MealType"}
                date: {\$ref: "#/definitions/DateInt"}
                format: {type: "string", enum: ["json", "xml"]}
            }
        }
    }
}

# Save JSON Schema for typify
$json_schema | to json -r | save target/fatsecret_schema.json --force

print "Generated target/fatsecret_schema.json"
print "Run: cargo typify target/fatsecret_schema.json -o src/api/fatsecret_types.rs"
