#!/bin/bash
set -e

echo "=== Meat Church Recipe Import ==="
echo "Starting import of 36 Meat Church recipes..."

# Counters
SUCCESS=0
FAILED=0
TOTAL=36

# Function to scrape and create recipe
import_recipe() {
	local name="$1"
	local url="$2"

	echo ""
	echo "[$((SUCCESS + FAILED + 1))/$TOTAL] Importing: $name"

	# Scrape recipe
	scrape_result=$(wmill script run f/tandoor/scrape_recipe -d "{
        \"tandoor\": \"$res:u/admin/tandoor_api\",
        \"url\": \"$url\"
    }" 2>&1)

	if ! echo "$scrape_result" | jq -e '.success == true' >/dev/null; then
		echo "  ✗ Failed to scrape"
		echo "  Error: $(echo "$scrape_result" | jq -r '.error // . // .' 2>&1)"
		((FAILED++))
		return 1
	fi

	recipe_data=$(echo "$scrape_result" | jq -c '.recipe' 2>&1)

	# Create with keywords
	create_result=$(wmill script run f/tandoor/create_recipe -d "{
        \"tandoor\": \"$res:u/admin/tandoor_api\",
        \"recipe_json\": $recipe_data,
        \"keywords\": [\"meat-church\", \"bbq\"]
    }" 2>&1)

	if ! echo "$create_result" | jq -e '.success == true' >/dev/null; then
		echo "  ✗ Failed to create in Tandoor"
		echo "  Error: $(echo "$create_result" | jq -r '.error // . // .' 2>&1)"
		((FAILED++))
		return 1
	fi

	recipe_id=$(echo "$create_result" | jq -r '.recipe_id' 2>&1)
	echo "  ✓ Created (ID: $recipe_id)"
	((SUCCESS++))

	# Rate limiting - 1 second between recipes
	sleep 1
}

# Beef Recipes
import_recipe "Prime Rib" "https://meatchurch.com/pages/prime-rib"
import_recipe "The Big Block Beef Ribs" "https://meatchurch.com/pages/big-block-beef-ribs"
import_recipe "Beef Cheeks" "https://meatchurch.com/pages/beef-cheeks"
import_recipe "Smoked Brisket" "https://meatchurch.com/pages/smoked-brisket"
import_recipe "Beef Short Ribs" "https://meatchurch.com/pages/beef-short-ribs"
import_recipe "Beef Plate Ribs" "https://meatchurch.com/pages/beef-plate-ribs"
import_recipe "Reverse Seared Ribeye" "https://meatchurch.com/pages/reverse-seared-ribeye"
import_recipe "Tomahawk Steak" "https://meatchurch.com/pages/tomahawk-steak"

echo ""
echo "=== Beef Recipes Complete ==="

# Chicken Recipes
import_recipe "Smoked Whole Chicken" "https://meatchurch.com/pages/smoked-whole-chicken"
import_recipe "Chicken Thighs" "https://meatchurch.com/pages/chicken-thighs"
import_recipe "Spatchcock Chicken" "https://meatchurch.com/pages/spatchcock-chicken"
import_recipe "Chicken Wings" "https://meatchurch.com/pages/chicken-wings"
import_recipe "Jalapeño Poppers" "https://meatchurch.com/pages/jalapeno-poppers"
import_recipe "Chicken Fried Rice" "https://meatchurch.com/pages/chicken-fried-rice"
import_recipe "Chicken Tortilla Soup" "https://meatchurch.com/pages/chicken-tortilla-soup"
import_recipe "Buffalo Chicken Dip" "https://meatchurch.com/pages/buffalo-chicken-dip"

echo ""
echo "=== Chicken Recipes Complete ==="

# Pork Recipes
import_recipe "Pork Butt" "https://meatchurch.com/pages/pork-butt"
import_recipe "Pork Shoulder" "https://meatchurch.com/pages/pork-shoulder"
import_recipe "Pork Ribs" "https://meatchurch.com/pages/pork-ribs"
import_recipe "Baby Back Ribs" "https://meatchurch.com/pages/baby-back-ribs"
import_recipe "St. Louis Ribs" "https://meatchurch.com/pages/st-louis-ribs"
import_recipe "Pork Belly Burnt Ends" "https://meatchurch.com/pages/pork-belly-burnt-ends"
import_recipe "Pork Chop" "https://meatchurch.com/pages/pork-chop"
import_recipe "Pork Tenderloin" "https://meatchurch.com/pages/pork-tenderloin"

echo ""
echo "=== Pork Recipes Complete ==="

# Side Dishes
import_recipe "Mac and Cheese" "https://meatchurch.com/pages/mac-and-cheese"
import_recipe "Bacon Wrapped Jalapeños" "https://meatchurch.com/pages/bacon-wrapped-jalapenos"
import_recipe "Creamed Corn" "https://meatchurch.com/pages/creamed-corn"
import_recipe "Baked Beans" "https://meatchurch.com/pages/baked-beans"
import_recipe "Corn on the Cob" "https://meatchurch.com/pages/corn-on-the-cob"
import_recipe "Potato Salad" "https://meatchurch.com/pages/potato-salad"
import_recipe "Coleslaw" "https://meatchurch.com/pages/coleslaw"
import_recipe "Biscuits" "https://meatchurch.com/pages/biscuits"

echo ""
echo "=== Side Dishes Complete ==="

# Sauces and Rubs
import_recipe "BBQ Sauce" "https://meatchurch.com/pages/bbq-sauce"
import_recipe "Honey Glaze" "https://meatchurch.com/pages/honey-glaze"
import_recipe "Tangy Sauce" "https://meatchurch.com/pages/tangy-sauce"

echo ""
echo "=== Sauces and Rubs Complete ==="

# Summary
echo ""
echo "=== Import Summary ==="
echo "Total: $TOTAL"
echo "Success: $SUCCESS"
echo "Failed: $FAILED"
echo "Success rate: $((SUCCESS * 100 / TOTAL))%"
echo ""

if [ $FAILED -eq 0 ]; then
	echo "✓ All recipes imported successfully!"
	exit 0
else
	echo "✗ Some recipes failed to import"
	exit 1
fi
