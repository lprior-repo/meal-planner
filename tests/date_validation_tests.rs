#![allow(clippy::indexing_slicing)]
#![allow(clippy::panic)]
#![allow(clippy::manual_assert)]
#![allow(clippy::approx_constant)]
#![allow(clippy::expect_used)]
#![allow(clippy::panic)]
#![allow(clippy::manual_assert)]
#![allow(clippy::approx_constant)]
#![allow(clippy::option_if_let_else)]
#![allow(clippy::panic)]
#![allow(clippy::manual_assert)]
#![allow(clippy::approx_constant)]
//! BEAD-005: Strict Date Format Validation Tests
//!
//! This test suite validates the strict YYYY-MM-DD date format enforcement
//! across all binaries that accept date inputs.
//!
//! Requirements:
//! - Exactly YYYY-MM-DD format (10 characters)
//! - Year: 1900-2099
//! - Month: 01-12 (zero-padded)
//! - Day: 01-31 (zero-padded, valid for month)
//! - Leap year logic for February 29

use meal_planner::fatsecret::diary::validate_strict_date_format;

// ============================================================================
// Valid Date Format Tests
// ============================================================================

#[test]
fn test_valid_date_standard() {
    assert!(validate_strict_date_format("2025-01-15").is_ok());
}

#[test]
fn test_valid_date_leap_year_feb_29() {
    assert!(validate_strict_date_format("2024-02-29").is_ok());
}

#[test]
fn test_valid_date_year_boundary_1900() {
    assert!(validate_strict_date_format("1900-01-01").is_ok());
}

#[test]
fn test_valid_date_year_boundary_2099() {
    assert!(validate_strict_date_format("2099-12-31").is_ok());
}

#[test]
fn test_valid_date_month_boundaries() {
    assert!(validate_strict_date_format("2025-01-31").is_ok()); // Jan has 31 days
    assert!(validate_strict_date_format("2025-04-30").is_ok()); // Apr has 30 days
    assert!(validate_strict_date_format("2025-02-28").is_ok()); // Feb non-leap
}

#[test]
fn test_valid_date_all_months() {
    for month in 1..=12 {
        let date = format!("2025-{:02}-15", month);
        assert!(
            validate_strict_date_format(&date).is_ok(),
            "Month {} should be valid",
            month
        );
    }
}

#[test]
fn test_valid_date_leap_years() {
    // Known leap years
    assert!(validate_strict_date_format("2000-02-29").is_ok());
    assert!(validate_strict_date_format("2004-02-29").is_ok());
    assert!(validate_strict_date_format("2020-02-29").is_ok());
    assert!(validate_strict_date_format("2024-02-29").is_ok());
}

// ============================================================================
// Invalid Format Tests
// ============================================================================

#[test]
fn test_invalid_format_no_zero_padding_month() {
    let result = validate_strict_date_format("2025-1-15");
    assert!(result.is_err());
    assert!(result
        .unwrap_err()
        .contains("must be exactly YYYY-MM-DD format"));
}

#[test]
fn test_invalid_format_no_zero_padding_day() {
    let result = validate_strict_date_format("2025-01-9");
    assert!(result.is_err());
    assert!(result
        .unwrap_err()
        .contains("must be exactly YYYY-MM-DD format"));
}

#[test]
fn test_invalid_format_slash_separators() {
    let result = validate_strict_date_format("2025/01/09");
    assert!(result.is_err());
    assert!(result
        .unwrap_err()
        .contains("must be exactly YYYY-MM-DD format"));
}

#[test]
fn test_invalid_format_wrong_length_short() {
    let result = validate_strict_date_format("2025-1-1");
    assert!(result.is_err());
}

#[test]
fn test_invalid_format_wrong_length_long() {
    let result = validate_strict_date_format("2025-001-001");
    assert!(result.is_err());
}

#[test]
fn test_invalid_format_empty_string() {
    let result = validate_strict_date_format("");
    assert!(result.is_err());
    assert!(result
        .unwrap_err()
        .contains("must be exactly YYYY-MM-DD format"));
}

#[test]
fn test_invalid_format_no_separators() {
    let result = validate_strict_date_format("20250115");
    assert!(result.is_err());
}

#[test]
fn test_invalid_format_reversed_mdy() {
    let result = validate_strict_date_format("01-15-2025");
    assert!(result.is_err());
}

#[test]
fn test_invalid_format_reversed_dmy() {
    let result = validate_strict_date_format("15-01-2025");
    assert!(result.is_err());
}

// ============================================================================
// Invalid Year Tests
// ============================================================================

#[test]
fn test_invalid_year_below_1900() {
    let result = validate_strict_date_format("1899-12-31");
    assert!(result.is_err());
    assert!(result.unwrap_err().contains("must be between 1900 and 2099"));
}

#[test]
fn test_invalid_year_above_2099() {
    let result = validate_strict_date_format("2100-01-01");
    assert!(result.is_err());
    assert!(result.unwrap_err().contains("must be between 1900 and 2099"));
}

#[test]
fn test_invalid_year_three_digits() {
    let result = validate_strict_date_format("999-01-01");
    assert!(result.is_err());
}

#[test]
fn test_invalid_year_five_digits() {
    let result = validate_strict_date_format("10000-01-01");
    assert!(result.is_err());
}

// ============================================================================
// Invalid Month Tests
// ============================================================================

#[test]
fn test_invalid_month_zero() {
    let result = validate_strict_date_format("2025-00-15");
    assert!(result.is_err());
    assert!(result.unwrap_err().contains("month must be 01-12"));
}

#[test]
fn test_invalid_month_13() {
    let result = validate_strict_date_format("2025-13-01");
    assert!(result.is_err());
    assert!(result.unwrap_err().contains("month must be 01-12"));
}

#[test]
fn test_invalid_month_99() {
    let result = validate_strict_date_format("2025-99-01");
    assert!(result.is_err());
    assert!(result.unwrap_err().contains("month must be 01-12"));
}

// ============================================================================
// Invalid Day Tests
// ============================================================================

#[test]
fn test_invalid_day_zero() {
    let result = validate_strict_date_format("2025-01-00");
    assert!(result.is_err());
    assert!(result.unwrap_err().contains("day must be between 01 and"));
}

#[test]
fn test_invalid_day_32_in_january() {
    let result = validate_strict_date_format("2025-01-32");
    assert!(result.is_err());
    assert!(result.unwrap_err().contains("January has 31 days"));
}

#[test]
fn test_invalid_day_31_in_april() {
    let result = validate_strict_date_format("2025-04-31");
    assert!(result.is_err());
    assert!(result.unwrap_err().contains("April has 30 days"));
}

#[test]
fn test_invalid_day_31_in_june() {
    let result = validate_strict_date_format("2025-06-31");
    assert!(result.is_err());
    assert!(result.unwrap_err().contains("June has 30 days"));
}

#[test]
fn test_invalid_day_31_in_september() {
    let result = validate_strict_date_format("2025-09-31");
    assert!(result.is_err());
    assert!(result.unwrap_err().contains("September has 30 days"));
}

#[test]
fn test_invalid_day_31_in_november() {
    let result = validate_strict_date_format("2025-11-31");
    assert!(result.is_err());
    assert!(result.unwrap_err().contains("November has 30 days"));
}

#[test]
fn test_invalid_day_30_in_february() {
    let result = validate_strict_date_format("2025-02-30");
    assert!(result.is_err());
    assert!(result
        .unwrap_err()
        .contains("February has 28 days in non-leap years"));
}

#[test]
fn test_invalid_day_29_in_february_non_leap() {
    let result = validate_strict_date_format("2025-02-29");
    assert!(result.is_err());
    assert!(result
        .unwrap_err()
        .contains("February has 28 days in non-leap years"));
}

#[test]
fn test_invalid_day_30_in_february_leap_year() {
    let result = validate_strict_date_format("2024-02-30");
    assert!(result.is_err());
    assert!(result
        .unwrap_err()
        .contains("February has 29 days in leap years"));
}

// ============================================================================
// Leap Year Edge Cases
// ============================================================================

#[test]
fn test_leap_year_century_not_divisible_by_400() {
    // 1900, 2100 are NOT leap years (divisible by 100 but not 400)
    let result = validate_strict_date_format("1900-02-29");
    assert!(result.is_err());
    assert!(result
        .unwrap_err()
        .contains("February has 28 days in non-leap years"));
}

#[test]
fn test_leap_year_century_divisible_by_400() {
    // 2000 IS a leap year (divisible by 400)
    assert!(validate_strict_date_format("2000-02-29").is_ok());
}

#[test]
fn test_non_leap_years() {
    // Known non-leap years
    let result = validate_strict_date_format("2001-02-29");
    assert!(result.is_err());

    let result = validate_strict_date_format("2019-02-29");
    assert!(result.is_err());

    let result = validate_strict_date_format("2023-02-29");
    assert!(result.is_err());
}

// ============================================================================
// Special Character Tests
// ============================================================================

#[test]
fn test_invalid_contains_letters() {
    let result = validate_strict_date_format("202A-01-15");
    assert!(result.is_err());
}

#[test]
fn test_invalid_contains_spaces() {
    let result = validate_strict_date_format("2025 01 15");
    assert!(result.is_err());
}

#[test]
fn test_invalid_contains_special_chars() {
    let result = validate_strict_date_format("2025@01#15");
    assert!(result.is_err());
}

// ============================================================================
// Boundary Tests for Days in Each Month
// ============================================================================

#[test]
fn test_days_in_months_31() {
    // Months with 31 days: Jan, Mar, May, Jul, Aug, Oct, Dec
    for month in [1, 3, 5, 7, 8, 10, 12] {
        let date = format!("2025-{:02}-31", month);
        assert!(
            validate_strict_date_format(&date).is_ok(),
            "Month {} should have 31 days",
            month
        );
    }
}

#[test]
fn test_days_in_months_30() {
    // Months with 30 days: Apr, Jun, Sep, Nov
    for month in [4, 6, 9, 11] {
        let date_valid = format!("2025-{:02}-30", month);
        assert!(
            validate_strict_date_format(&date_valid).is_ok(),
            "Month {} should have 30 days",
            month
        );

        let date_invalid = format!("2025-{:02}-31", month);
        assert!(
            validate_strict_date_format(&date_invalid).is_err(),
            "Month {} should NOT have 31 days",
            month
        );
    }
}

// ============================================================================
// Error Message Quality Tests
// ============================================================================

#[test]
fn test_error_message_format_includes_expected() {
    let result = validate_strict_date_format("2025/01/15");
    assert!(result.is_err());
    let err = result.unwrap_err();
    assert!(err.contains("YYYY-MM-DD"), "Error should mention expected format");
}

#[test]
fn test_error_message_month_includes_range() {
    let result = validate_strict_date_format("2025-13-15");
    assert!(result.is_err());
    let err = result.unwrap_err();
    assert!(err.contains("01-12"), "Error should mention valid month range");
}

#[test]
fn test_error_message_year_includes_range() {
    let result = validate_strict_date_format("1899-01-15");
    assert!(result.is_err());
    let err = result.unwrap_err();
    assert!(
        err.contains("1900") && err.contains("2099"),
        "Error should mention valid year range"
    );
}

// ============================================================================
// Integration with date_to_int Tests
// ============================================================================

#[test]
fn test_validated_date_converts_to_int() {
    use meal_planner::fatsecret::diary::date_to_int;

    let date = "2025-01-15";
    assert!(validate_strict_date_format(date).is_ok());
    assert!(date_to_int(date).is_ok());
}

#[test]
fn test_invalid_date_rejected_before_conversion() {
    let date = "2025-1-15"; // No zero padding
    assert!(validate_strict_date_format(date).is_err());
}
