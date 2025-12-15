#!/bin/bash

# Add breakfast entries to FatSecret for Monday-Friday
# Using actual FatSecret food IDs and serving IDs

API_URL="http://localhost:8080/api/fatsecret/diary/entries"

echo "Adding breakfast entries for December 15-19, 2025 (Monday-Friday)"
echo "================================================================"

for day in {15..19}; do
  date="2025-12-$day"
  day_name=$(date -d "$date" +%A)
  echo ""
  echo "📅 $day_name, $date"
  echo "-------------------"

  # Add Dannon Light & Fit (food_id: 78442, serving_id: 118069)
  echo -n "  Adding Dannon Light & Fit Yogurt... "
  result=$(curl -s -X POST "$API_URL" \
    -H "Content-Type: application/json" \
    -d "{
      \"type\": \"from_food\",
      \"food_id\": \"78442\",
      \"serving_id\": \"118069\",
      \"number_of_units\": 1.0,
      \"meal\": \"breakfast\",
      \"date\": \"$date\"
    }")

  if echo "$result" | jq -e '.success' > /dev/null 2>&1; then
    echo "✓ (80 cal, 12g protein)"
  else
    echo "✗ $(echo "$result" | jq -r '.message // .error')"
  fi

  # Add Isopure Zero Carb (food_id: 45885109, serving_id: 39412696)
  echo -n "  Adding Isopure Zero Carb Protein... "
  result=$(curl -s -X POST "$API_URL" \
    -H "Content-Type: application/json" \
    -d "{
      \"type\": \"from_food\",
      \"food_id\": \"45885109\",
      \"serving_id\": \"39412696\",
      \"number_of_units\": 1.0,
      \"meal\": \"breakfast\",
      \"date\": \"$date\"
    }")

  if echo "$result" | jq -e '.success' > /dev/null 2>&1; then
    echo "✓ (100 cal, 25g protein)"
  else
    echo "✗ $(echo "$result" | jq -r '.message // .error')"
  fi

  # Add Mixed Berries (food_id: 91621, serving_id: 131951)
  echo -n "  Adding Mixed Berries (1 cup)... "
  result=$(curl -s -X POST "$API_URL" \
    -H "Content-Type: application/json" \
    -d "{
      \"type\": \"from_food\",
      \"food_id\": \"91621\",
      \"serving_id\": \"131951\",
      \"number_of_units\": 1.0,
      \"meal\": \"breakfast\",
      \"date\": \"$date\"
    }")

  if echo "$result" | jq -e '.success' > /dev/null 2>&1; then
    echo "✓ (70 cal, 16g carbs)"
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
