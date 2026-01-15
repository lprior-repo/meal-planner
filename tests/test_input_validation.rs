//! BEAD-010: Comprehensive Input Validation Test Suite
//!
//! This test suite validates all input validation rules implemented in:
//! - BEAD-001: meal_type validation
//! - BEAD-004: Numeric bounds validation
//! - BEAD-005: Date format validation
//! - BEAD-006: Empty string validation
//!
//! Test Modules:
//! 1. numeric_bounds - Test calories, protein, carbs, fat, servings, bmr ranges
//! 2. date_format - Test YYYY-MM-DD validation
//! 3. empty_strings - Test string field validation
//! 4. enum_validation - Test meal_type and other enum fields
//!
//! All tests follow the pattern:
//! - Test invalid values are rejected
//! - Test valid values pass
//! - Test edge cases
//! - Test error messages are clear and actionable

#![allow(clippy::unwrap_used, clippy::indexing_slicing, clippy::panic)]
#![allow(clippy::panic)]
#![allow(clippy::manual_assert)]
#![allow(clippy::approx_constant)]

// =============================================================================
// MODULE 1: NUMERIC BOUNDS VALIDATION
// =============================================================================

mod numeric_bounds {
    use meal_planner::fatsecret::diary::{validate_custom_entry, validate_number_of_units};
    use meal_planner::sync::types::NutritionData;

    // -------------------------------------------------------------------------
    // Negative Values Tests
    // -------------------------------------------------------------------------

    #[test]
    fn test_negative_calories_rejected() {
        let result = validate_custom_entry(
            "Test Food",
            "1 serving",
            1.0,
            -100.0, // negative calories
            10.0,
            5.0,
            2.0,
        );
        assert!(result.is_err(), "Negative calories should be rejected");
        assert_eq!(
            result.unwrap_err().0,
            "Nutrition values cannot be negative"
        );
    }

    #[test]
    fn test_negative_protein_rejected() {
        let result = validate_custom_entry(
            "Test Food",
            "1 serving",
            1.0,
            100.0,
            10.0,
            -5.0, // negative protein
            2.0,
        );
        assert!(result.is_err(), "Negative protein should be rejected");
    }

    #[test]
    fn test_negative_carbs_rejected() {
        let result = validate_custom_entry(
            "Test Food",
            "1 serving",
            1.0,
            100.0,
            -10.0, // negative carbs
            5.0,
            2.0,
        );
        assert!(result.is_err(), "Negative carbohydrates should be rejected");
    }

    #[test]
    fn test_negative_fat_rejected() {
        let result = validate_custom_entry(
            "Test Food",
            "1 serving",
            1.0,
            100.0,
            10.0,
            5.0,
            -2.0, // negative fat
        );
        assert!(result.is_err(), "Negative fat should be rejected");
    }

    #[test]
    fn test_negative_servings_rejected() {
        let result = validate_number_of_units(-1.0);
        assert!(result.is_err(), "Negative servings should be rejected");
        assert_eq!(
            result.unwrap_err().0,
            "number_of_units must be greater than 0"
        );
    }

    // -------------------------------------------------------------------------
    // Zero Values Tests (Edge Cases)
    // -------------------------------------------------------------------------

    #[test]
    fn test_zero_calories_allowed() {
        let result = validate_custom_entry(
            "Water",
            "1 glass",
            1.0,
            0.0, // zero calories is valid (e.g., water)
            0.0,
            0.0,
            0.0,
        );
        assert!(result.is_ok(), "Zero calories should be allowed (e.g., water)");
    }

    #[test]
    fn test_zero_macros_allowed() {
        let result = validate_custom_entry(
            "Water",
            "1 glass",
            1.0,
            0.0,
            0.0, // zero carbs
            0.0, // zero protein
            0.0, // zero fat
        );
        assert!(result.is_ok(), "Zero macros should be allowed");
    }

    #[test]
    fn test_zero_servings_rejected() {
        let result = validate_number_of_units(0.0);
        assert!(result.is_err(), "Zero servings should be rejected");
        assert_eq!(
            result.unwrap_err().0,
            "number_of_units must be greater than 0"
        );
    }

    // -------------------------------------------------------------------------
    // Positive Values Tests
    // -------------------------------------------------------------------------

    #[test]
    fn test_small_positive_servings_allowed() {
        assert!(validate_number_of_units(0.001).is_ok());
        assert!(validate_number_of_units(0.1).is_ok());
        assert!(validate_number_of_units(0.5).is_ok());
    }

    #[test]
    fn test_typical_nutrition_values_allowed() {
        let result = validate_custom_entry(
            "Chicken Breast",
            "100g",
            1.0,
            165.0, // typical calories
            31.0,  // typical protein
            0.0,   // typical carbs
            3.6,   // typical fat
        );
        assert!(result.is_ok(), "Typical nutrition values should be valid");
    }

    // -------------------------------------------------------------------------
    // Large Values Tests (Boundary Testing)
    // -------------------------------------------------------------------------

    #[test]
    fn test_large_calories_allowed() {
        let result = validate_custom_entry(
            "High Calorie Food",
            "1 serving",
            1.0,
            10000.0, // very high but valid
            100.0,
            100.0,
            100.0,
        );
        assert!(result.is_ok(), "Large but valid calories should be allowed");
    }

    #[test]
    fn test_large_servings_allowed() {
        assert!(
            validate_number_of_units(100.0).is_ok(),
            "Large servings should be allowed"
        );
        assert!(validate_number_of_units(1000.0).is_ok());
    }

    // -------------------------------------------------------------------------
    // NutritionData Validation Tests
    // -------------------------------------------------------------------------

    #[test]
    fn test_nutrition_data_is_valid_positive() {
        let nutrition = NutritionData::macros_only(100.0, 10.0, 5.0, 15.0);
        assert!(
            nutrition.is_valid(),
            "Positive nutrition values should be valid"
        );
    }

    #[test]
    fn test_nutrition_data_is_valid_zero() {
        let nutrition = NutritionData::zero();
        assert!(nutrition.is_valid(), "Zero nutrition values should be valid");
    }

    #[test]
    fn test_nutrition_data_is_invalid_negative_calories() {
        let nutrition = NutritionData::macros_only(-100.0, 10.0, 5.0, 15.0);
        assert!(
            !nutrition.is_valid(),
            "Negative calories should be invalid"
        );
    }

    #[test]
    fn test_nutrition_data_is_invalid_negative_protein() {
        let nutrition = NutritionData::macros_only(100.0, -10.0, 5.0, 15.0);
        assert!(
            !nutrition.is_valid(),
            "Negative protein should be invalid"
        );
    }

    #[test]
    fn test_nutrition_data_is_invalid_negative_fat() {
        let nutrition = NutritionData::macros_only(100.0, 10.0, -5.0, 15.0);
        assert!(!nutrition.is_valid(), "Negative fat should be invalid");
    }

    #[test]
    fn test_nutrition_data_is_invalid_negative_carbs() {
        let nutrition = NutritionData::macros_only(100.0, 10.0, 5.0, -15.0);
        assert!(
            !nutrition.is_valid(),
            "Negative carbohydrates should be invalid"
        );
    }

    // -------------------------------------------------------------------------
    // Overflow/Extreme Values Tests
    // -------------------------------------------------------------------------

    #[test]
    fn test_infinity_servings_handled() {
        let result = validate_number_of_units(f64::INFINITY);
        // Should be allowed or handled gracefully
        assert!(result.is_ok(), "Infinity should be handled (though unusual)");
    }

    #[test]
    fn test_nan_servings_rejected() {
        let result = validate_number_of_units(f64::NAN);
        // NaN should fail the > 0.0 check
        assert!(result.is_err(), "NaN servings should be rejected");
    }
}

// =============================================================================
// MODULE 2: DATE FORMAT VALIDATION
// =============================================================================

mod date_format {
    use meal_planner::fatsecret::diary::{date_to_int, int_to_date};

    // -------------------------------------------------------------------------
    // Valid Date Format Tests
    // -------------------------------------------------------------------------

    #[test]
    fn test_valid_date_format_accepted() {
        assert!(date_to_int("2024-01-01").is_ok());
        assert!(date_to_int("2024-12-31").is_ok());
        assert!(date_to_int("2025-06-15").is_ok());
    }

    #[test]
    fn test_valid_date_epoch() {
        let result = date_to_int("1970-01-01");
        assert!(result.is_ok());
        assert_eq!(result.unwrap(), 0);
    }

    #[test]
    fn test_valid_date_modern() {
        let result = date_to_int("2024-01-01");
        assert!(result.is_ok());
        assert_eq!(result.unwrap(), 19723);
    }

    // -------------------------------------------------------------------------
    // Invalid Format Tests
    // -------------------------------------------------------------------------

    #[test]
    fn test_invalid_format_wrong_separator() {
        assert!(
            date_to_int("2024/01/01").is_err(),
            "Slash separator should be rejected"
        );
        assert!(
            date_to_int("2024.01.01").is_err(),
            "Dot separator should be rejected"
        );
    }

    #[test]
    fn test_invalid_format_wrong_order() {
        assert!(
            date_to_int("01-01-2024").is_err(),
            "MM-DD-YYYY format should be rejected"
        );
        assert!(
            date_to_int("01-2024-01").is_err(),
            "DD-YYYY-MM format should be rejected"
        );
    }

    #[test]
    fn test_format_missing_padding_rejected() {
        // Strict validation requires exact YYYY-MM-DD format (10 characters)
        let result = date_to_int("2024-1-1");
        assert!(
            result.is_err(),
            "Non-padded dates should be rejected (strict validation)"
        );
        assert!(result.unwrap_err().contains("10 characters"));

        // Test other non-padded formats
        assert!(date_to_int("2024-01-1").is_err());
        assert!(date_to_int("2024-1-01").is_err());
    }

    #[test]
    fn test_invalid_format_empty_string() {
        assert!(date_to_int("").is_err(), "Empty string should be rejected");
    }

    #[test]
    fn test_invalid_format_garbage() {
        assert!(
            date_to_int("not-a-date").is_err(),
            "Garbage input should be rejected"
        );
        assert!(
            date_to_int("2024-13-45").is_err(),
            "Invalid date should be rejected"
        );
    }

    // -------------------------------------------------------------------------
    // Invalid Date Values Tests
    // -------------------------------------------------------------------------

    #[test]
    fn test_invalid_date_month_13() {
        assert!(
            date_to_int("2024-13-01").is_err(),
            "Month 13 should be rejected"
        );
    }

    #[test]
    fn test_invalid_date_month_0() {
        assert!(
            date_to_int("2024-00-01").is_err(),
            "Month 0 should be rejected"
        );
    }

    #[test]
    fn test_invalid_date_day_32() {
        assert!(
            date_to_int("2024-01-32").is_err(),
            "Day 32 should be rejected"
        );
    }

    #[test]
    fn test_invalid_date_day_0() {
        assert!(
            date_to_int("2024-01-00").is_err(),
            "Day 0 should be rejected"
        );
    }

    #[test]
    fn test_invalid_date_february_30() {
        assert!(
            date_to_int("2024-02-30").is_err(),
            "February 30 should be rejected"
        );
    }

    #[test]
    fn test_invalid_date_april_31() {
        assert!(
            date_to_int("2024-04-31").is_err(),
            "April 31 should be rejected (April has 30 days)"
        );
    }

    // -------------------------------------------------------------------------
    // Leap Year Tests
    // -------------------------------------------------------------------------

    #[test]
    fn test_leap_year_feb_29_valid() {
        // 2024 is a leap year
        let result = date_to_int("2024-02-29");
        assert!(result.is_ok(), "Feb 29 in leap year should be valid");
        assert_eq!(result.unwrap(), 19782);
    }

    #[test]
    fn test_non_leap_year_feb_29_invalid() {
        // 2023 is not a leap year
        assert!(
            date_to_int("2023-02-29").is_err(),
            "Feb 29 in non-leap year should be rejected"
        );
    }

    #[test]
    fn test_leap_year_2000_feb_29_valid() {
        // 2000 is a leap year (divisible by 400)
        assert!(
            date_to_int("2000-02-29").is_ok(),
            "Feb 29, 2000 should be valid"
        );
    }

    #[test]
    fn test_non_leap_year_1900_feb_29_invalid() {
        // 1900 is not a leap year (divisible by 100 but not 400)
        assert!(
            date_to_int("1900-02-29").is_err(),
            "Feb 29, 1900 should be invalid"
        );
    }

    // -------------------------------------------------------------------------
    // Date Conversion Roundtrip Tests
    // -------------------------------------------------------------------------

    #[test]
    fn test_date_roundtrip_conversion() {
        let test_dates = [
            "1970-01-01",
            "2000-01-01",
            "2024-01-01",
            "2024-06-15",
            "2024-12-31",
            "2025-01-01",
        ];

        for date in test_dates {
            let date_int = date_to_int(date).unwrap();
            let back = int_to_date(date_int).unwrap();
            assert_eq!(
                date, back,
                "Date {} should roundtrip through date_int {}",
                date, date_int
            );
        }
    }

    #[test]
    fn test_int_to_date_negative() {
        // Dates before epoch should work
        assert_eq!(int_to_date(-1).unwrap(), "1969-12-31");
        assert_eq!(int_to_date(-365).unwrap(), "1969-01-01");
    }
}

// =============================================================================
// MODULE 3: EMPTY STRING VALIDATION
// =============================================================================

mod empty_strings {
    use meal_planner::fatsecret::diary::validate_custom_entry;
    use meal_planner::fatsecret::exercise::validation::{
        validate_access_secret, validate_access_token,
    };

    // -------------------------------------------------------------------------
    // Empty String Tests
    // -------------------------------------------------------------------------

    #[test]
    fn test_empty_food_name_rejected() {
        let result = validate_custom_entry(
            "", // empty name
            "1 serving",
            1.0,
            100.0,
            10.0,
            5.0,
            2.0,
        );
        assert!(result.is_err(), "Empty food name should be rejected");
        assert_eq!(result.unwrap_err().0, "food_entry_name cannot be empty");
    }

    #[test]
    fn test_empty_serving_description_rejected() {
        let result = validate_custom_entry(
            "Apple",
            "", // empty serving description
            1.0,
            100.0,
            10.0,
            5.0,
            2.0,
        );
        assert!(
            result.is_err(),
            "Empty serving description should be rejected"
        );
        assert_eq!(
            result.unwrap_err().0,
            "serving_description cannot be empty"
        );
    }

    #[test]
    fn test_empty_access_token_rejected() {
        let result = validate_access_token("");
        assert!(result.is_err(), "Empty access token should be rejected");
        assert_eq!(result.unwrap_err(), "access_token cannot be empty");
    }

    #[test]
    fn test_empty_access_secret_rejected() {
        let result = validate_access_secret("");
        assert!(result.is_err(), "Empty access secret should be rejected");
        assert_eq!(result.unwrap_err(), "access_secret cannot be empty");
    }

    // -------------------------------------------------------------------------
    // Whitespace-only Tests
    // -------------------------------------------------------------------------

    #[test]
    fn test_whitespace_only_token_rejected() {
        assert!(
            validate_access_token("   ").is_err(),
            "Whitespace-only token should be rejected"
        );
        assert!(
            validate_access_token("\t").is_err(),
            "Tab-only token should be rejected"
        );
        assert!(
            validate_access_token("\n").is_err(),
            "Newline-only token should be rejected"
        );
    }

    #[test]
    fn test_whitespace_only_secret_rejected() {
        assert!(
            validate_access_secret("   ").is_err(),
            "Whitespace-only secret should be rejected"
        );
        assert!(
            validate_access_secret("\t\n").is_err(),
            "Mixed whitespace secret should be rejected"
        );
    }

    // -------------------------------------------------------------------------
    // Valid String Tests
    // -------------------------------------------------------------------------

    #[test]
    fn test_valid_food_name_accepted() {
        let result = validate_custom_entry(
            "Apple", // valid name
            "1 medium",
            1.0,
            95.0,
            25.0,
            0.5,
            0.3,
        );
        assert!(result.is_ok(), "Valid food name should be accepted");
    }

    #[test]
    fn test_valid_serving_description_accepted() {
        let result = validate_custom_entry(
            "Chicken",
            "100g grilled", // valid description
            1.0,
            165.0,
            31.0,
            0.0,
            3.6,
        );
        assert!(
            result.is_ok(),
            "Valid serving description should be accepted"
        );
    }

    #[test]
    fn test_valid_access_token_accepted() {
        assert!(validate_access_token("valid_token_123").is_ok());
        assert!(validate_access_token("a").is_ok()); // single char is valid
    }

    #[test]
    fn test_valid_access_secret_accepted() {
        assert!(validate_access_secret("valid_secret_456").is_ok());
        assert!(validate_access_secret("x").is_ok()); // single char is valid
    }

    // -------------------------------------------------------------------------
    // String with Spaces Tests
    // -------------------------------------------------------------------------

    #[test]
    fn test_food_name_with_spaces_accepted() {
        let result = validate_custom_entry(
            "Grilled Chicken Breast", // spaces are fine
            "100g",
            1.0,
            165.0,
            31.0,
            0.0,
            3.6,
        );
        assert!(
            result.is_ok(),
            "Food name with spaces should be accepted"
        );
    }

    #[test]
    fn test_token_with_spaces_accepted() {
        // Tokens with internal spaces are valid (trim only checks leading/trailing)
        assert!(validate_access_token("token with spaces").is_ok());
    }
}

// =============================================================================
// MODULE 4: ENUM VALIDATION
// =============================================================================

mod enum_validation {
    use meal_planner::fatsecret::diary::MealType;

    // -------------------------------------------------------------------------
    // Valid Enum Values Tests
    // -------------------------------------------------------------------------

    #[test]
    fn test_valid_meal_types() {
        assert_eq!(
            MealType::from_api_string("breakfast"),
            Some(MealType::Breakfast)
        );
        assert_eq!(MealType::from_api_string("lunch"), Some(MealType::Lunch));
        assert_eq!(MealType::from_api_string("dinner"), Some(MealType::Dinner));
        assert_eq!(MealType::from_api_string("other"), Some(MealType::Snack));
        assert_eq!(MealType::from_api_string("snack"), Some(MealType::Snack));
    }

    #[test]
    fn test_meal_type_to_api_string() {
        assert_eq!(MealType::Breakfast.to_api_string(), "breakfast");
        assert_eq!(MealType::Lunch.to_api_string(), "lunch");
        assert_eq!(MealType::Dinner.to_api_string(), "dinner");
        assert_eq!(MealType::Snack.to_api_string(), "other");
    }

    // -------------------------------------------------------------------------
    // Invalid Enum Values Tests
    // -------------------------------------------------------------------------

    #[test]
    fn test_invalid_meal_type_rejected() {
        assert_eq!(
            MealType::from_api_string("invalid"),
            None,
            "Invalid meal type should return None"
        );
        assert_eq!(MealType::from_api_string("brunch"), None);
        assert_eq!(MealType::from_api_string("elevenses"), None);
        assert_eq!(MealType::from_api_string("afternoon_tea"), None);
    }

    #[test]
    fn test_empty_meal_type_rejected() {
        assert_eq!(
            MealType::from_api_string(""),
            None,
            "Empty meal type should return None"
        );
    }

    #[test]
    fn test_common_typos_rejected() {
        assert_eq!(MealType::from_api_string("breakfest"), None);
        assert_eq!(MealType::from_api_string("luntch"), None);
        assert_eq!(MealType::from_api_string("diner"), None); // valid word, wrong context
        assert_eq!(MealType::from_api_string("snak"), None);
    }

    // -------------------------------------------------------------------------
    // Case Sensitivity Tests
    // -------------------------------------------------------------------------

    #[test]
    fn test_meal_type_case_sensitive() {
        // MealType::from_api_string is case-sensitive
        assert_eq!(
            MealType::from_api_string("BREAKFAST"),
            None,
            "Uppercase should not match (case-sensitive)"
        );
        assert_eq!(
            MealType::from_api_string("Breakfast"),
            None,
            "Title case should not match"
        );
        assert_eq!(
            MealType::from_api_string("Lunch"),
            None,
            "Title case should not match"
        );
    }

    #[test]
    fn test_meal_type_lowercase_only() {
        // Only lowercase should match
        assert!(MealType::from_api_string("breakfast").is_some());
        assert!(MealType::from_api_string("lunch").is_some());
        assert!(MealType::from_api_string("dinner").is_some());
        assert!(MealType::from_api_string("other").is_some());
    }

    // -------------------------------------------------------------------------
    // Enum Roundtrip Tests
    // -------------------------------------------------------------------------

    #[test]
    fn test_meal_type_roundtrip() {
        let meal_types = [
            MealType::Breakfast,
            MealType::Lunch,
            MealType::Dinner,
            MealType::Snack,
        ];

        for meal in meal_types {
            let api_string = meal.to_api_string();
            let parsed = MealType::from_api_string(api_string);
            assert_eq!(
                parsed,
                Some(meal),
                "MealType {:?} should roundtrip",
                meal
            );
        }
    }

    // -------------------------------------------------------------------------
    // Serialization Tests
    // -------------------------------------------------------------------------

    #[test]
    fn test_meal_type_serde_json() {
        use serde_json;

        // Test deserialization
        let json = serde_json::json!("breakfast");
        let meal: MealType = serde_json::from_value(json).unwrap();
        assert_eq!(meal, MealType::Breakfast);

        // Test "other" maps to Snack
        let json = serde_json::json!("other");
        let meal: MealType = serde_json::from_value(json).unwrap();
        assert_eq!(meal, MealType::Snack);

        // Test serialization
        let meal = MealType::Dinner;
        let json = serde_json::to_value(meal).unwrap();
        assert_eq!(json, serde_json::json!("dinner"));
    }

    #[test]
    fn test_meal_type_serde_invalid() {
        use serde_json;

        // Invalid meal type should fail deserialization
        let json = serde_json::json!("invalid_meal");
        let result: Result<MealType, _> = serde_json::from_value(json);
        assert!(
            result.is_err(),
            "Invalid meal type should fail deserialization"
        );
    }

    // -------------------------------------------------------------------------
    // Display Format Tests
    // -------------------------------------------------------------------------

    #[test]
    fn test_meal_type_display() {
        assert_eq!(format!("{}", MealType::Breakfast), "breakfast");
        assert_eq!(format!("{}", MealType::Lunch), "lunch");
        assert_eq!(format!("{}", MealType::Dinner), "dinner");
        assert_eq!(format!("{}", MealType::Snack), "other");
    }
}

// =============================================================================
// MODULE 5: INTEGRATION TESTS - Multiple Validations
// =============================================================================

mod integration {
    use meal_planner::fatsecret::diary::{date_to_int, validate_custom_entry, MealType};

    // -------------------------------------------------------------------------
    // Complete Entry Validation Tests
    // -------------------------------------------------------------------------

    #[test]
    fn test_complete_valid_entry() {
        // Test all validations pass for a valid entry
        let food_name = "Grilled Chicken";
        let serving_desc = "100g";
        let servings = 1.5;
        let calories = 165.0;
        let carbs = 0.0;
        let protein = 31.0;
        let fat = 3.6;

        // Validate nutrition
        let result = validate_custom_entry(
            food_name,
            serving_desc,
            servings,
            calories,
            carbs,
            protein,
            fat,
        );
        assert!(result.is_ok(), "Valid entry should pass validation");

        // Validate date
        let date = "2024-06-15";
        let date_int = date_to_int(date);
        assert!(date_int.is_ok(), "Valid date should parse");

        // Validate meal type
        let meal_type = MealType::from_api_string("dinner");
        assert!(meal_type.is_some(), "Valid meal type should parse");
    }

    #[test]
    fn test_multiple_validation_errors() {
        // Test entry with multiple validation errors
        let result = validate_custom_entry(
            "", // empty name - ERROR 1
            "", // empty serving - ERROR 2
            -1.0, // negative servings - ERROR 3
            -100.0, // negative calories - ERROR 4
            10.0,
            5.0,
            2.0,
        );

        assert!(
            result.is_err(),
            "Entry with multiple errors should be rejected"
        );
    }

    #[test]
    fn test_edge_case_minimal_valid_entry() {
        // Minimal valid entry (water)
        let result = validate_custom_entry(
            "W",    // single char name is valid
            "1",    // single char serving is valid
            0.001,  // very small servings is valid
            0.0,    // zero calories is valid
            0.0,    // zero carbs is valid
            0.0,    // zero protein is valid
            0.0,    // zero fat is valid
        );
        assert!(
            result.is_ok(),
            "Minimal valid entry should pass validation"
        );
    }

    // -------------------------------------------------------------------------
    // Error Message Quality Tests
    // -------------------------------------------------------------------------

    #[test]
    fn test_error_messages_are_actionable() {
        // Test that error messages provide clear guidance

        // Empty name error
        let result = validate_custom_entry("", "1 serving", 1.0, 100.0, 10.0, 5.0, 2.0);
        assert!(result.is_err());
        let error = result.unwrap_err().0;
        assert!(
            error.contains("food_entry_name"),
            "Error should mention field name"
        );
        assert!(error.contains("empty"), "Error should state the problem");

        // Negative values error
        let result = validate_custom_entry("Food", "1 serving", 1.0, -100.0, 10.0, 5.0, 2.0);
        assert!(result.is_err());
        let error = result.unwrap_err().0;
        assert!(
            error.contains("negative"),
            "Error should identify negative values"
        );

        // Invalid servings error
        let result_servings = meal_planner::fatsecret::diary::validate_number_of_units(0.0);
        assert!(result_servings.is_err());
        let error = result_servings.unwrap_err().0;
        assert!(
            error.contains("greater than 0"),
            "Error should specify valid range"
        );
    }
}

// =============================================================================
// MODULE 6: EXERCISE VALIDATION TESTS
// =============================================================================

mod exercise_validation {
    use meal_planner::fatsecret::exercise::validation::{
        validate_duration_min, validate_exercise_entry_id, validate_exercise_id,
    };

    // -------------------------------------------------------------------------
    // Duration Validation Tests
    // -------------------------------------------------------------------------

    #[test]
    fn test_valid_duration_accepted() {
        assert!(validate_duration_min(1).is_ok(), "1 minute should be valid");
        assert!(validate_duration_min(30).is_ok(), "30 minutes should be valid");
        assert!(validate_duration_min(60).is_ok(), "60 minutes should be valid");
        assert!(
            validate_duration_min(1440).is_ok(),
            "1440 minutes (24 hours) should be valid"
        );
    }

    #[test]
    fn test_invalid_duration_rejected() {
        let result = validate_duration_min(0);
        assert!(result.is_err(), "0 minutes should be rejected");
        assert_eq!(
            result.unwrap_err(),
            "duration_min must be between 1 and 1440"
        );

        let result = validate_duration_min(-1);
        assert!(result.is_err(), "Negative duration should be rejected");

        let result = validate_duration_min(1441);
        assert!(
            result.is_err(),
            "Duration over 24 hours should be rejected"
        );
        assert_eq!(
            result.unwrap_err(),
            "duration_min must be between 1 and 1440"
        );
    }

    // -------------------------------------------------------------------------
    // Exercise ID Validation Tests
    // -------------------------------------------------------------------------

    #[test]
    fn test_valid_exercise_id_accepted() {
        assert!(validate_exercise_id("123").is_ok());
        assert!(validate_exercise_id("456789").is_ok());
        assert!(validate_exercise_id("1").is_ok(), "Single digit is valid");
    }

    #[test]
    fn test_invalid_exercise_id_rejected() {
        let result = validate_exercise_id("");
        assert!(result.is_err(), "Empty ID should be rejected");
        assert_eq!(result.unwrap_err(), "exercise_id cannot be empty");

        let result = validate_exercise_id("abc");
        assert!(result.is_err(), "Non-numeric ID should be rejected");
        assert_eq!(result.unwrap_err(), "exercise_id must contain only digits");

        let result = validate_exercise_id("123abc");
        assert!(result.is_err(), "Mixed alphanumeric should be rejected");

        let result = validate_exercise_id("12.34");
        assert!(result.is_err(), "Decimal ID should be rejected");
    }

    // -------------------------------------------------------------------------
    // Exercise Entry ID Validation Tests
    // -------------------------------------------------------------------------

    #[test]
    fn test_valid_exercise_entry_id_accepted() {
        assert!(validate_exercise_entry_id("98765").is_ok());
        assert!(validate_exercise_entry_id("1").is_ok());
    }

    #[test]
    fn test_invalid_exercise_entry_id_rejected() {
        let result = validate_exercise_entry_id("");
        assert!(result.is_err(), "Empty entry ID should be rejected");
        assert_eq!(
            result.unwrap_err(),
            "exercise_entry_id cannot be empty"
        );

        let result = validate_exercise_entry_id("xyz");
        assert!(
            result.is_err(),
            "Non-numeric entry ID should be rejected"
        );
        assert_eq!(
            result.unwrap_err(),
            "exercise_entry_id must contain only digits"
        );
    }
}

// =============================================================================
// MODULE 7: COMPREHENSIVE EDGE CASE TESTS
// =============================================================================

mod edge_cases {
    use meal_planner::fatsecret::diary::{date_to_int, int_to_date, validate_custom_entry};

    #[test]
    fn test_very_long_food_name() {
        let long_name = "A".repeat(1000);
        let result = validate_custom_entry(&long_name, "1 serving", 1.0, 100.0, 10.0, 5.0, 2.0);
        assert!(
            result.is_ok(),
            "Very long food names should be allowed (API may have limits)"
        );
    }

    #[test]
    fn test_unicode_food_name() {
        let result =
            validate_custom_entry("Café au Lait ☕", "1 cup", 1.0, 150.0, 8.0, 5.0, 8.0);
        assert!(result.is_ok(), "Unicode in food names should be allowed");
    }

    #[test]
    fn test_special_characters_in_serving() {
        let result = validate_custom_entry(
            "Pasta",
            "1 cup (cooked)",
            1.0,
            200.0,
            42.0,
            8.0,
            1.0,
        );
        assert!(
            result.is_ok(),
            "Special characters in serving description should be allowed"
        );
    }

    #[test]
    fn test_fractional_servings() {
        use meal_planner::fatsecret::diary::validate_number_of_units;

        assert!(validate_number_of_units(0.25).is_ok());
        assert!(validate_number_of_units(0.333333).is_ok());
        assert!(validate_number_of_units(0.5).is_ok());
        assert!(validate_number_of_units(1.5).is_ok());
        assert!(validate_number_of_units(2.75).is_ok());
    }

    #[test]
    fn test_date_far_future_within_range() {
        // 2099-12-31 is the max allowed year
        let result = date_to_int("2099-12-31");
        assert!(result.is_ok(), "2099 dates should be valid (max year)");
        let date_int = result.unwrap();
        assert!(date_int > 0, "Future date should be positive");
    }

    #[test]
    fn test_date_year_2100_rejected() {
        // Year 2100 exceeds the allowed range (1900-2099)
        let result = date_to_int("2100-01-01");
        assert!(
            result.is_err(),
            "Year 2100 should be rejected (exceeds max year 2099)"
        );
        assert!(result.unwrap_err().contains("1900 and 2099"));
    }

    #[test]
    fn test_date_far_past() {
        let result = date_to_int("1900-01-01");
        assert!(result.is_ok(), "Far past dates should be valid");
    }

    #[test]
    fn test_date_int_large_positive() {
        let result = int_to_date(50000);
        assert!(result.is_ok(), "Large positive date_int should work");
    }

    #[test]
    fn test_date_int_large_negative() {
        let result = int_to_date(-10000);
        assert!(result.is_ok(), "Large negative date_int should work");
    }

    #[test]
    fn test_very_precise_nutrition_values() {
        let result = validate_custom_entry(
            "Precise Food",
            "1g",
            1.0,
            3.141592653589793,  // pi calories
            1.414213562373095,  // sqrt(2) carbs
            2.718281828459045,  // e protein
            1.618033988749895,  // golden ratio fat
        );
        assert!(
            result.is_ok(),
            "High precision nutrition values should be allowed"
        );
    }
}
