#!/bin/bash

# Add breakfast entries to FatSecret for Monday-Friday
# Using custom entries with exact FatSecret nutrition data

API_URL="http://localhost:8080/api/fatsecret/diary/entries"

echo "Adding breakfast entries for December 15-19, 2025 (Monday-Friday)"
echo "================================================================"

for day in {15..19}; do
  date="2025-12-$day"
  day_name=$(date -d "$date" +%A)
  echo ""
  echo "📅 $day_name, $date"
  echo "-------------------"

  # Add Dannon Light & Fit - Lemon (from FatSecret food_id: 78442)
  echo -n "  Adding Dannon Light & Fit Yogurt... "
  result=$(curl -s -X POST "$API_URL" \
    -H "Content-Type: application/json" \
    -d "{
      \"type\": \"custom\",
      \"food_id\": \"78442\",
      \"food_entry_name\": \"Light & Fit Yogurt - Lemon\",
      \"serving_description\": \"1 container\",
      \"number_of_units\": 1.0,
      \"meal\": \"breakfast\",
      \"date\": \"$date\",
      \"calories\": 80.0,
      \"carbohydrate\": 8.0,
      \"protein\": 12.0,
      \"fat\": 0.0
    }")

  if echo "$result" | jq -e '.success' > /dev/null 2>&1; then
    echo "✓ (80 cal, 12g protein)"
  else
    echo "✗ $(echo "$result" | jq -r '.message // .error')"
  fi

  # Add Isopure Zero Carb Unflavored (from FatSecret food_id: 45885109)
  echo -n "  Adding Isopure Zero Carb Protein... "
  result=$(curl -s -X POST "$API_URL" \
    -H "Content-Type: application/json" \
    -d "{
      \"type\": \"custom\",
      \"food_id\": \"45885109\",
      \"food_entry_name\": \"Isopure Zero Carb Unflavored\",
      \"serving_description\": \"1 scoop\",
      \"number_of_units\": 1.0,
      \"meal\": \"breakfast\",
      \"date\": \"$date\",
      \"calories\": 100.0,
      \"carbohydrate\": 0.0,
      \"protein\": 25.0,
      \"fat\": 0.0
    }")

  if echo "$result" | jq -e '.success' > /dev/null 2>&1; then
    echo "✓ (100 cal, 25g protein)"
  else
    echo "✗ $(echo "$result" | jq -r '.message // .error')"
  fi

  # Add Mixed Berries (from FatSecret food_id: 91621)
  echo -n "  Adding Mixed Berries (1 cup)... "
  result=$(curl -s -X POST "$API_URL" \
    -H "Content-Type: application/json" \
    -d "{
      \"type\": \"custom\",
      \"food_id\": \"91621\",
      \"food_entry_name\": \"Best Yet Mixed Berries\",
      \"serving_description\": \"1 cup\",
      \"number_of_units\": 1.0,
      \"meal\": \"breakfast\",
      \"date\": \"$date\",
      \"calories\": 70.0,
      \"carbohydrate\": 16.0,
      \"protein\": 1.0,
      \"fat\": 0.0
    }")

  if echo "$result" | jq -e '.success' > /dev/null 2>&1; then
    echo "✓ (70 cal, 1g protein, 16g carbs)"
  else
    echo "✗ $(echo "$result" | jq -r '.message // .error')"
  fi

  echo "  Daily breakfast total: 250 cal | 38g protein | 24g carbs"
done

echo ""
echo "================================================================"
echo "✅ Breakfast entries added for the week!"
echo ""
echo "To view your diary, visit:"
echo "  http://localhost:8080/api/fatsecret/diary/day/20251215"
