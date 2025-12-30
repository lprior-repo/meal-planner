# FatSecret Platform API - Parameters Reference

This guide documents common parameters used across the FatSecret Platform API.

## Unique Identifiers

These integer identifiers are used to reference specific resources:

| Parameter | Description |
|-----------|-------------|
| `food_id` | Unique identifier for a food item |
| `recipe_id` | Unique identifier for a recipe |
| `serving_id` | Unique identifier for a serving size |
| `food_entry_id` | Unique identifier for a food diary entry |
| `exercise_entry_id` | Unique identifier for an exercise diary entry |
| `meal_id` | Unique identifier for a saved meal |
| `weight_id` | Unique identifier for a weight entry |
| `brand_id` | Unique identifier for a food brand |

## Nutrient Parameters

### Macronutrients

| Parameter | Unit | Description |
|-----------|------|-------------|
| `calories` | kcal | Total calories (energy) |
| `carbohydrate` | g | Total carbohydrates |
| `protein` | g | Total protein |
| `fat` | g | Total fat |
| `saturated_fat` | g | Saturated fat |
| `polyunsaturated_fat` | g | Polyunsaturated fat |
| `monounsaturated_fat` | g | Monounsaturated fat |
| `trans_fat` | g | Trans fat |
| `fiber` | g | Dietary fiber |
| `sugar` | g | Total sugars |
| `added_sugars` | g | Added sugars |

### Vitamins

| Parameter | Unit | Description |
|-----------|------|-------------|
| `vitamin_a` | mcg | Vitamin A |
| `vitamin_c` | mg | Vitamin C |
| `vitamin_d` | mcg | Vitamin D |
| `vitamin_e` | mg | Vitamin E |
| `vitamin_k` | mcg | Vitamin K |
| `thiamin` | mg | Vitamin B1 (Thiamin) |
| `riboflavin` | mg | Vitamin B2 (Riboflavin) |
| `niacin` | mg | Vitamin B3 (Niacin) |
| `vitamin_b6` | mg | Vitamin B6 |
| `vitamin_b12` | mcg | Vitamin B12 |
| `folate` | mcg | Folate |
| `pantothenic_acid` | mg | Vitamin B5 (Pantothenic Acid) |

### Minerals

| Parameter | Unit | Description |
|-----------|------|-------------|
| `calcium` | mg | Calcium |
| `iron` | mg | Iron |
| `magnesium` | mg | Magnesium |
| `phosphorus` | mg | Phosphorus |
| `potassium` | mg | Potassium |
| `sodium` | mg | Sodium |
| `zinc` | mg | Zinc |
| `copper` | mg | Copper |
| `manganese` | mg | Manganese |
| `selenium` | mcg | Selenium |

### Other Nutrients

| Parameter | Unit | Description |
|-----------|------|-------------|
| `cholesterol` | mg | Cholesterol |
| `caffeine` | mg | Caffeine |
| `alcohol` | g | Alcohol |
| `water` | g | Water content |

## Common Request Parameters

### Pagination

| Parameter | Type | Description |
|-----------|------|-------------|
| `page_number` | integer | Page number (0-indexed) |
| `max_results` | integer | Maximum results per page |

### Search

| Parameter | Type | Description |
|-----------|------|-------------|
| `search_expression` | string | Search query text |
| `must_have_images` | boolean | Filter to items with images |

### Date Parameters

| Parameter | Type | Description |
|-----------|------|-------------|
| `date` | integer | Days since January 1, 1970 |
| `from_date` | integer | Start date (days since epoch) |
| `to_date` | integer | End date (days since epoch) |

### Food Entry Parameters

| Parameter | Type | Description |
|-----------|------|-------------|
| `meal` | string | Meal type: `breakfast`, `lunch`, `dinner`, `other` |
| `number_of_units` | decimal | Number of servings |

### Sorting

| Parameter | Type | Description |
|-----------|------|-------------|
| `sort_by` | string | Field to sort by |
| `sort_order` | string | Sort direction: `asc` or `desc` |

## Response Format

| Parameter | Type | Description |
|-----------|------|-------------|
| `format` | string | Response format: `json` or `xml` |

## Date Calculation

FatSecret uses "days since epoch" for date parameters. To convert:

```python
from datetime import date

def to_fatsecret_date(d):
    """Convert a date to FatSecret days-since-epoch format."""
    epoch = date(1970, 1, 1)
    return (d - epoch).days

def from_fatsecret_date(days):
    """Convert FatSecret days-since-epoch to a date."""
    epoch = date(1970, 1, 1)
    return epoch + timedelta(days=days)

# Example
today = date.today()
fs_date = to_fatsecret_date(today)  # e.g., 19723
```

## Serving Size

Food items may have multiple serving sizes. Each serving includes:

| Field | Description |
|-------|-------------|
| `serving_id` | Unique identifier |
| `serving_description` | Human-readable description (e.g., "1 cup") |
| `metric_serving_amount` | Amount in metric units |
| `metric_serving_unit` | Metric unit (e.g., "g", "ml") |
| `number_of_units` | Default number of units |

Nutrient values are provided per serving.
