# FatSecret Weight Decoder Validation Report

**Analysis Date:** 2025-12-14
**Analyzed By:** Research Agent (Claude Code)
**Files Analyzed:**
- `/home/lewis/src/meal-planner/gleam/src/meal_planner/fatsecret/weight/decoders.gleam`
- `/home/lewis/src/meal-planner/gleam/src/meal_planner/fatsecret/weight/types.gleam`
- `/home/lewis/src/meal-planner/gleam/src/meal_planner/fatsecret/weight/client.gleam`

---

## Executive Summary

**Status:** 🔴 **CRITICAL FAILURES DETECTED**

The `WeightMonthSummary` decoder has **critical bugs** that will cause **100% parsing failure** on all API responses. The decoder expects fields that don't exist in the actual FatSecret API response.

| Decoder | Status | Severity | Issue Count |
|---------|--------|----------|-------------|
| `WeightEntry` | ✅ PASS | None | 0 |
| `WeightDaySummary` | ⚠️ INCOMPLETE | Low | 1 |
| `WeightMonthSummary` | 🔴 FAIL | Critical | 3 |

---

## Issue Details

### 🔴 Issue 1: CRITICAL - Missing Required Fields in `WeightMonthSummary`

**File:** `decoders.gleam:77-93`, `types.gleam:63-72`

**Actual FatSecret API Response:**
```json
{
  "month": {
    "from_date_int": "14276",
    "to_date_int": "14303",
    "day": [
      {"date_int": "14276", "weight_kg": "82.000"},
      {"date_int": "14282", "weight_kg": "81.000"}
    ]
  }
}
```

**Current Decoder Expects:**
```gleam
// Lines 78-79: Decoder expects fields that don't exist
use month <- decode.field("month", int_string_decoder())  // ❌ No "month" field
use year <- decode.field("year", int_string_decoder())    // ❌ No "year" field
```

**Current Type Definition:**
```gleam
// types.gleam:63-72
pub type WeightMonthSummary {
  WeightMonthSummary(
    days: List(WeightDaySummary),
    month: Int,   // ❌ API provides from_date_int instead
    year: Int,    // ❌ API provides to_date_int instead
  )
}
```

**Impact:**
- **100% parsing failure** - decoder will fail on every API call
- Client code at `client.gleam:145` will always return `ParseError`
- No weight month data can be retrieved

**Fix Required:**
```gleam
// types.gleam - Update type
pub type WeightMonthSummary {
  WeightMonthSummary(
    days: List(WeightDaySummary),
    from_date_int: Int,  // ✓ Matches API
    to_date_int: Int,    // ✓ Matches API
  )
}

// decoders.gleam - Update decoder
pub fn weight_month_summary_decoder() -> decode.Decoder(WeightMonthSummary) {
  use from_date_int <- decode.field("from_date_int", int_string_decoder())
  use to_date_int <- decode.field("to_date_int", int_string_decoder())
  // ... rest of decoder
}
```

---

### 🔴 Issue 2: CRITICAL - Wrong Field Path for Days Array

**File:** `decoders.gleam:82-90`

**Current Implementation:**
```gleam
// Line 82-90: Looks for nested path "days" -> "day"
use days <- decode.field(
  "days",  // ❌ This field doesn't exist
  decode.one_of(
    decode.at(["day"], decode.list(weight_day_summary_decoder())),
    [decode.at(["day"], single_day_to_list_decoder())],
  ),
)
```

**This expects:**
```json
{
  "days": {        // ❌ Doesn't exist
    "day": [...]
  }
}
```

**Actual API structure:**
```json
{
  "day": [...]     // ✓ At root level, not nested
}
```

**Impact:**
- Decoder searches for `days.day` path
- Actual path is just `day`
- Results in parsing failure

**Fix Required:**
```gleam
// Remove the outer "days" field wrapper
use days <- decode.field(
  "day",  // ✓ Correct - field is at root level
  decode.one_of(
    decode.list(weight_day_summary_decoder()),
    [single_day_to_list_decoder()],
  ),
)
```

---

### 🔴 Issue 3: HIGH - Type Design Mismatch

**File:** `types.gleam:63-72`

**Problem:**
The type stores `month: Int` and `year: Int`, but the API provides date ranges as `from_date_int` and `to_date_int` (days since Unix epoch).

**Current Design:**
```gleam
pub type WeightMonthSummary {
  WeightMonthSummary(
    days: List(WeightDaySummary),
    month: Int,  // e.g., 1 for January
    year: Int,   // e.g., 2024
  )
}
```

**API Provides:**
```json
{
  "from_date_int": "14276",  // Days since 1970-01-01 (start of month)
  "to_date_int": "14303"     // Days since 1970-01-01 (end of month)
}
```

**Impact:**
- Type doesn't match API contract
- Would need conversion logic to extract month/year from date_int
- Semantic mismatch between design intent and API reality

**Fix Required:**
Change the type to match what the API actually provides (see Issue 1 fix).

---

### ⚠️ Issue 4: LOW - Missing `weight_comment` in `WeightDaySummary`

**File:** `decoders.gleam:55-60`, `types.gleam:51-58`

**Current Type:**
```gleam
pub type WeightDaySummary {
  WeightDaySummary(
    date_int: Int,
    weight_kg: Float,
    // ⚠️ Missing: weight_comment field
  )
}
```

**Actual API Response:**
```json
{
  "date_int": "14276",
  "weight_kg": "82.000",
  "weight_comment": "whoo i did it again"  // ⚠️ Present in API
}
```

**Current Decoder:**
```gleam
// Lines 55-60: Only decodes date_int and weight_kg
pub fn weight_day_summary_decoder() -> decode.Decoder(WeightDaySummary) {
  use date_int <- decode.field("date_int", int_string_decoder())
  use weight_kg <- decode.field("weight_kg", float_string_decoder())
  // ⚠️ Ignores weight_comment
  decode.success(WeightDaySummary(date_int: date_int, weight_kg: weight_kg))
}
```

**Impact:**
- Decoder doesn't fail (extra fields are ignored)
- User weight comments are silently discarded
- Data loss - comments from monthly summaries are lost

**Fix Required:**
```gleam
// types.gleam - Add weight_comment
pub type WeightDaySummary {
  WeightDaySummary(
    date_int: Int,
    weight_kg: Float,
    weight_comment: Option(String),  // ✓ Add this
  )
}

// decoders.gleam - Decode weight_comment
pub fn weight_day_summary_decoder() -> decode.Decoder(WeightDaySummary) {
  use date_int <- decode.field("date_int", int_string_decoder())
  use weight_kg <- decode.field("weight_kg", float_string_decoder())
  use weight_comment <- decode.optional_field(
    "weight_comment",
    None,
    decode.optional(decode.string),
  )

  decode.success(WeightDaySummary(
    date_int: date_int,
    weight_kg: weight_kg,
    weight_comment: weight_comment,
  ))
}
```

---

### ✅ Issue 5: NONE - `WeightEntry` Decoder is Correct

**File:** `decoders.gleam:26-40`, `types.gleam:14-23`

**Status:** ✅ **PASS**

The `WeightEntry` decoder correctly handles the API response format:

```gleam
pub fn weight_entry_decoder() -> decode.Decoder(WeightEntry) {
  use date_int <- decode.field("date_int", int_string_decoder())
  use weight_kg <- decode.field("weight_kg", float_string_decoder())
  use weight_comment <- decode.optional_field(
    "weight_comment",
    None,
    decode.optional(decode.string),
  )

  decode.success(WeightEntry(
    date_int: date_int,
    weight_kg: weight_kg,
    weight_comment: weight_comment,
  ))
}
```

**Correctly handles:**
- ✅ `date_int` as string → Int conversion
- ✅ `weight_kg` as string → Float conversion
- ✅ `weight_comment` as optional string field
- ✅ Matches API response structure exactly

**No changes needed.**

---

## Summary Table

| Issue | Severity | Component | Lines | Fix Required |
|-------|----------|-----------|-------|--------------|
| #1 | 🔴 CRITICAL | WeightMonthSummary Type | types.gleam:63-72 | Change `month`/`year` to `from_date_int`/`to_date_int` |
| #2 | 🔴 CRITICAL | WeightMonthSummary Decoder | decoders.gleam:82-90 | Change field path from `"days"` to `"day"` |
| #3 | 🔴 CRITICAL | WeightMonthSummary Decoder | decoders.gleam:78-79 | Decode `from_date_int` and `to_date_int` instead of `month`/`year` |
| #4 | ⚠️ LOW | WeightDaySummary | types.gleam:51-58, decoders.gleam:55-60 | Add optional `weight_comment` field |
| #5 | ✅ NONE | WeightEntry | decoders.gleam:26-40 | No changes needed |

---

## Complete Fix Implementation

### Step 1: Update Types (`types.gleam`)

```gleam
/// Monthly weight summary
///
/// Contains weight measurements for each day in the month that has data.
pub type WeightMonthSummary {
  WeightMonthSummary(
    /// List of daily weight measurements
    days: List(WeightDaySummary),
    /// First day of month as days since Unix epoch
    from_date_int: Int,
    /// Last day of month as days since Unix epoch
    to_date_int: Int,
  )
}

/// Single day's weight summary
///
/// Used within monthly summaries to show weight for each day.
pub type WeightDaySummary {
  WeightDaySummary(
    /// Date as days since Unix epoch
    date_int: Int,
    /// Weight in kilograms
    weight_kg: Float,
    /// Optional comment about the measurement
    weight_comment: Option(String),
  )
}
```

### Step 2: Update Decoders (`decoders.gleam`)

```gleam
/// Decode WeightMonthSummary from API response
///
/// Example JSON:
/// ```json
/// {
///   "from_date_int": "14276",
///   "to_date_int": "14303",
///   "day": [
///     { "date_int": "14276", "weight_kg": "82.000", "weight_comment": "comment" },
///     { "date_int": "14282", "weight_kg": "81.000" }
///   ]
/// }
/// ```
pub fn weight_month_summary_decoder() -> decode.Decoder(WeightMonthSummary) {
  use from_date_int <- decode.field("from_date_int", int_string_decoder())
  use to_date_int <- decode.field("to_date_int", int_string_decoder())

  // Days are at root level as "day", not nested inside "days"
  use days <- decode.field(
    "day",
    decode.one_of(
      decode.list(weight_day_summary_decoder()),
      [single_day_to_list_decoder()],
    ),
  )

  decode.success(WeightMonthSummary(
    days: days,
    from_date_int: from_date_int,
    to_date_int: to_date_int,
  ))
}

/// Decode WeightDaySummary from API response
///
/// Example JSON:
/// ```json
/// {
///   "date_int": "14276",
///   "weight_kg": "82.000",
///   "weight_comment": "whoo i did it again"
/// }
/// ```
pub fn weight_day_summary_decoder() -> decode.Decoder(WeightDaySummary) {
  use date_int <- decode.field("date_int", int_string_decoder())
  use weight_kg <- decode.field("weight_kg", float_string_decoder())
  use weight_comment <- decode.optional_field(
    "weight_comment",
    None,
    decode.optional(decode.string),
  )

  decode.success(WeightDaySummary(
    date_int: date_int,
    weight_kg: weight_kg,
    weight_comment: weight_comment,
  ))
}
```

### Step 3: Update Client Usage (if needed)

Check `client.gleam:145` to ensure the parsing path is correct:

```gleam
// This is already correct - parses at ["month"] path
json.parse(
  body,
  decode.at(["month"], decoders.weight_month_summary_decoder()),
)
```

### Step 4: Add Comprehensive Tests

Create `gleam/test/fatsecret/weight/decoders_test.gleam`:

```gleam
import gleeunit/should
import gleam/json
import gleam/dynamic/decode
import gleam/option.{Some, None}
import meal_planner/fatsecret/weight/decoders
import meal_planner/fatsecret/weight/types.{WeightEntry, WeightMonthSummary, WeightDaySummary}

/// Test actual FatSecret API month response format
pub fn weight_month_summary_actual_api_test() {
  let json_str = "{
    \"month\": {
      \"day\": [
        {\"date_int\": \"14276\", \"weight_comment\": \"whoo i did it again\", \"weight_kg\": \"82.000\"},
        {\"date_int\": \"14282\", \"weight_kg\": \"81.000\"}
      ],
      \"from_date_int\": \"14276\",
      \"to_date_int\": \"14303\"
    }
  }"

  case json.parse(json_str, decode.at(["month"], decoders.weight_month_summary_decoder())) {
    Ok(summary) -> {
      summary.from_date_int |> should.equal(14276)
      summary.to_date_int |> should.equal(14303)
      list.length(summary.days) |> should.equal(2)

      // Check first day with comment
      case list.first(summary.days) {
        Ok(day1) -> {
          day1.date_int |> should.equal(14276)
          day1.weight_kg |> should.equal(82.0)
          day1.weight_comment |> should.equal(Some("whoo i did it again"))
        }
        Error(_) -> should.fail()
      }
    }
    Error(_) -> should.fail()
  }
}

/// Test weight entry with comment
pub fn weight_entry_with_comment_test() {
  let json_str = "{\"date_int\": \"19723\", \"weight_kg\": \"75.5\", \"weight_comment\": \"Morning weight\"}"

  case json.parse(json_str, decoders.weight_entry_decoder()) {
    Ok(entry) -> {
      entry.date_int |> should.equal(19723)
      entry.weight_kg |> should.equal(75.5)
      entry.weight_comment |> should.equal(Some("Morning weight"))
    }
    Error(_) -> should.fail()
  }
}

/// Test weight entry without comment
pub fn weight_entry_without_comment_test() {
  let json_str = "{\"date_int\": \"19723\", \"weight_kg\": \"75.5\"}"

  case json.parse(json_str, decoders.weight_entry_decoder()) {
    Ok(entry) -> {
      entry.date_int |> should.equal(19723)
      entry.weight_kg |> should.equal(75.5)
      entry.weight_comment |> should.equal(None)
    }
    Error(_) -> should.fail()
  }
}

/// Test single day in month (non-array)
pub fn weight_month_summary_single_day_test() {
  let json_str = "{
    \"from_date_int\": \"14276\",
    \"to_date_int\": \"14303\",
    \"day\": {\"date_int\": \"14276\", \"weight_kg\": \"82.000\"}
  }"

  case json.parse(json_str, decoders.weight_month_summary_decoder()) {
    Ok(summary) -> {
      list.length(summary.days) |> should.equal(1)
    }
    Error(_) -> should.fail()
  }
}
```

---

## Testing Instructions

After implementing the fixes:

```bash
cd /home/lewis/src/meal-planner/gleam

# Run weight decoder tests
gleam test --module=fatsecret/weight/decoders_test

# Run all FatSecret tests
gleam test --module=fatsecret

# Run full test suite
gleam test
```

---

## References

### FatSecret API Documentation
- **weights.get_month (v2):** https://platform.fatsecret.com/docs/v2/weights.get_month
- **weight.update (v1):** https://platform.fatsecret.com/docs/v1/weight.update

### Implementation Files
- **Decoders:** `/home/lewis/src/meal-planner/gleam/src/meal_planner/fatsecret/weight/decoders.gleam`
- **Types:** `/home/lewis/src/meal-planner/gleam/src/meal_planner/fatsecret/weight/types.gleam`
- **Client:** `/home/lewis/src/meal-planner/gleam/src/meal_planner/fatsecret/weight/client.gleam`
- **Tests:** `/home/lewis/src/meal-planner/gleam/test/fatsecret/weight/weight_test.gleam`

---

## Appendix: Example API Responses

### Successful `weights.get_month` Response

```json
{
  "month": {
    "day": [
      {
        "date_int": "14276",
        "weight_comment": "whoo i did it again",
        "weight_kg": "82.000"
      },
      {
        "date_int": "14282",
        "weight_kg": "81.000"
      }
    ],
    "from_date_int": "14276",
    "to_date_int": "14303"
  }
}
```

### Successful `weight.update` Response

```json
{
  "success": {
    "value": "1"
  }
}
```

---

**End of Report**
