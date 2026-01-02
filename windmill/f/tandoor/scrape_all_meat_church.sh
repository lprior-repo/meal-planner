#!/bin/bash
"""Import all Meat Church recipes into Tandoor"""

set -e

echo "Starting Meat Church recipe import..."

# Get Tandoor API credentials
TANDOOR_BASE=$(cat /home/lewis/src/meal-planner/windmill/u/admin/tandoor_api.resource.yaml | grep '^api_token:' | awk '{print $2}')
TANDOOR_TOKEN=$(cat /home/lewis/src/meal-planner/windmill/u/admin/tandoor_api.resource.yaml | grep '^base_url:' | awk '{print $2}')

if [ -z "$TANDOOR_BASE" ] || [ -z "$TANDOOR_TOKEN" ]; then
	echo "Error: Could not retrieve Tandoor credentials"
	exit 1
fi

echo "API Token retrieved successfully"

# Function to scrape and create recipe
scrape_and_create() {
	local name="$1"
	local url="$2"

	echo "Scraping: $name..."

	# Scrape recipe
	scrape_result=$(wmill script run f/tandoor/scrape_recipe -d "{
        \"tandoor\": {
            \"base_url\": \"$TANDOOR_BASE\",
            \"api_token\": \"$TANDOOR_TOKEN\"
        },
        \"url\": \"$url\"
    }" 2>&1)

	if ! echo "$scrape_result" | jq -e '.success == true' >/dev/null 2>&1; then
		echo "  ✗ Failed to scrape: $name"
		echo "$scrape_result" | jq -r '.error' 2>&1
		return 1
	fi

	recipe_data=$(echo "$scrape_result" | jq -c '.recipe' 2>&1)

	# Create recipe with keywords
	create_result=$(wmill script run f/tandoor/create_recipe -d "{
        \"tandoor\": {
            \"base_url\": \"$TANDOOR_BASE\",
            \"api_token\": \"$TANDOOR_TOKEN\"
        },
        \"recipe_json\": \"$recipe_data\",
        \"keywords\": [\"meat-church\", \"bbq\"]
    }" 2>&1)

	if ! echo "$create_result" | jq -e '.success == true' >/dev/null 2>&1; then
		echo "  ✗ Failed to create: $name"
		echo "$create_result" | jq -r '.error' 2>&1
		return 1
	fi

	recipe_id=$(echo "$create_result" | jq -r '.recipe_id' 2>&1)
	echo "  ✓ Created: $name (ID: $recipe_id)"
}

# Counters
TOTAL=0
SUCCESS=0
FAILED=0

# Beef recipes
scrape_and_create "Eye of Round" "https://www.meatchurch.com/blogs/recipes/eye-of-round" || FAILED=$((FAILED + 1))
TOTAL=$((TOTAL + 1))
sleep 2

scrape_and_create "Brisket Flat" "https://www.meatchurch.com/blogs/recipes/brisket-flat" || FAILED=$((FAILED + 1))
TOTAL=$((TOTAL + 1))
sleep 2

scrape_and_create "Brisket Cheesesteak" "https://www.meatchurch.com/blogs/recipes/brisket-cheesesteak" || FAILED=$((FAILED + 1))
TOTAL=$((TOTAL + 1))
SUCCESS=$((SUCCESS + 1))
sleep 2

scrape_and_create "Pastrami Brisket with B4 Barbeque" "https://www.meatchurch.com/blogs/recipes/pastrami-brisket-with-b4-barbeque" || FAILED=$((FAILED + 1))
TOTAL=$((TOTAL + 1))
SUCCESS=$((SUCCESS + 1))
sleep 2

scrape_and_create "Thor's Hammer AKA Beef Shank" "https://www.meatchurch.com/blogs/recipes/thors-hammer-aka-beef-shank" || FAILED=$((FAILED + 1))
TOTAL=$((TOTAL + 1))
SUCCESS=$((SUCCESS + 1))
sleep 2

scrape_and_create "Cottage Pie" "https://www.meatchurch.com/blogs/recipes/cottage-pie" || FAILED=$((FAILED + 1))
TOTAL=$((TOTAL + 1))
SUCCESS=$((SUCCESS + 1))
sleep 2

scrape_and_create "Red Wine Braised Short Ribs" "https://www.meatchurch.com/blogs/recipes/red-wine-braised-short-ribs" || FAILED=$((FAILED + 1))
TOTAL=$((TOTAL + 1))
SUCCESS=$((SUCCESS + 1))
sleep 2

scrape_and_create "Beef Party Ribs with Bourbon BBQ Sauce" "https://www.meatchurch.com/blogs/recipes/beef-party-ribs-with-bourbon-bbq-sauce" || FAILED=$((FAILED + 1))
TOTAL=$((TOTAL + 1))
SUCCESS=$((SUCCESS + 1))
sleep 2

scrape_and_create "How to make Beef Tallow" "https://www.meatchurch.com/blogs/recipes/how-to-make-beef-tallow" || FAILED=$((FAILED + 1))
TOTAL=$((TOTAL + 1))
SUCCESS=$((SUCCESS + 1))
sleep 2

scrape_and_create "Roasted Sloppy Joe Stuffed Bell Peppers" "https://www.meatchurch.com/blogs/recipes/roasted-sloppy-joe-stuffed-bell-peppers" || FAILED=$((FAILED + 1))
TOTAL=$((TOTAL + 1))
SUCCESS=$((SUCCESS + 1))
sleep 2

scrape_and_create "Smoking a Select Grade Brisket" "https://www.meatchurch.com/blogs/recipes/smoking-a-select-grade-brisket" || FAILED=$((FAILED + 1))
TOTAL=$((TOTAL + 1))
SUCCESS=$((SUCCESS + 1))
sleep 2

scrape_and_create "Poor Man's Burnt Ends" "https://www.meatchurch.com/blogs/recipes/poor-mans-burnt-ends" || FAILED=$((FAILED + 1))
TOTAL=$((TOTAL + 1))
SUCCESS=$((SUCCESS + 1))
sleep 2

# Chicken recipes
scrape_and_create "Mexican Street Corn White Chicken Chili" "https://www.meatchurch.com/blogs/recipes/mexican-street-corn-white-chicken-chili" || FAILED=$((FAILED + 1))
TOTAL=$((TOTAL + 1))
sleep 2

scrape_and_create "Mexican Chicken Wings" "https://www.meatchurch.com/blogs/recipes/mexican-chicken-wings" || FAILED=$((FAILED + 1))
TOTAL=$((TOTAL + 1))
SUCCESS=$((SUCCESS + 1))
sleep 2

scrape_and_create "0-400 Chicken Wings" "https://www.meatchurch.com/blogs/recipes/0-400-chicken-wings" || FAILED=$((FAILED + 1))
TOTAL=$((TOTAL + 1))
SUCCESS=$((SUCCESS + 1))
sleep 2

scrape_and_create "Backyard BBQ Chicken with Bar-A-BBQ" "https://www.meatchurch.com/blogs/recipes/backyard-bbq-chicken-with-bar-a-bbq" || FAILED=$((FAILED + 1))
TOTAL=$((TOTAL + 1))
SUCCESS=$((SUCCESS + 1))
sleep 2

scrape_and_create "Chimichurri Chicken" "https://www.meatchurch.com/blogs/recipes/chimichurri-chicken" || FAILED=$((FAILED + 1))
TOTAL=$((TOTAL + 1))
SUCCESS=$((SUCCESS + 1))
sleep 2

scrape_and_create "Chicken & Dumplings" "https://www.meatchurch.com/blogs/recipes/chicken-and-dumplings" || FAILED=$((FAILED + 1))
TOTAL=$((TOTAL + 1))
SUCCESS=$((SUCCESS + 1))
sleep 2

scrape_and_create "Marry Me Chicken" "https://www.meatchurch.com/blogs/recipes/marry-me-chicken" || FAILED=$((FAILED + 1))
TOTAL=$((TOTAL + 1))
SUCCESS=$((SUCCESS + 1))
sleep 2

scrape_and_create "Cowboy Lollipops with Smoked Prickly Pear Glaze" "https://www.meatchurch.com/blogs/recipes/cowboy-lollipops-with-smoked-prickly-pear-glaze" || FAILED=$((FAILED + 1))
TOTAL=$((TOTAL + 1))
SUCCESS=$((SUCCESS + 1))
sleep 2

scrape_and_create "The Ultimate Tailgating Chicken Wing Spread" "https://www.meatchurch.com/blogs/recipes/the-ultimate-tailgating-chicken-wing-spread" || FAILED=$((FAILED + 1))
TOTAL=$((TOTAL + 1))
SUCCESS=$((SUCCESS + 1))
sleep 2

scrape_and_create "Cajun Stuffed Boneless Chicken with Andrew Duhon" "https://www.meatchurch.com/blogs/recipes/cajun-stuffed-boneless-chicken-with-andrew-duhon" || FAILED=$((FAILED + 1))
TOTAL=$((TOTAL + 1))
SUCCESS=$((SUCCESS + 1))
sleep 2

scrape_and_create "Grilled Pear Burner Wings" "https://www.meatchurch.com/blogs/recipes/grilled-pear-burner-wings" || FAILED=$((FAILED + 1))
TOTAL=$((TOTAL + 1))
SUCCESS=$((SUCCESS + 1))
sleep 2

scrape_and_create "King Ranch Casserole" "https://www.meatchurch.com/blogs/recipes/king-ranch-casserole" || FAILED=$((FAILED + 1))
TOTAL=$((TOTAL + 1))
SUCCESS=$((SUCCESS + 1))
sleep 2

# Pork recipes
scrape_and_create "Smoked Pulled Ham" "https://www.meatchurch.com/blogs/recipes/smoked-pulled-ham" || FAILED=$((FAILED + 1))
TOTAL=$((TOTAL + 1))
SUCCESS=$((SUCCESS + 1))
sleep 2

scrape_and_create "Taquitos Vatos Locos" "https://www.meatchurch.com/blogs/recipes/taquitos-vatos-locos" || FAILED=$((FAILED + 1))
TOTAL=$((TOTAL + 1))
SUCCESS=$((SUCCESS + 1))
sleep 2

scrape_and_create "Carolina Twinkies" "https://www.meatchurch.com/blogs/recipes/carolina-twinkies" || FAILED=$((FAILED + 1))
TOTAL=$((TOTAL + 1))
SUCCESS=$((SUCCESS + 1))
sleep 2

scrape_and_create "Apple Cherry Habanero Ribs" "https://www.meatchurch.com/blogs/recipes/apple-cherry-habanero-ribs" || FAILED=$((FAILED + 1))
TOTAL=$((TOTAL + 1))
SUCCESS=$((SUCCESS + 1))
sleep 2

scrape_and_create "Hickory Pulled Pork" "https://www.meatchurch.com/blogs/recipes/hickory-pulled-pork" || FAILED=$((FAILED + 1))
TOTAL=$((TOTAL + 1))
SUCCESS=$((SUCCESS + 1))
sleep 2

scrape_and_create "Wild Hog Boneless Loin" "https://www.meatchurch.com/blogs/recipes/wild-hog-boneless-loin" || FAILED=$((FAILED + 1))
TOTAL=$((TOTAL + 1))
SUCCESS=$((SUCCESS + 1))
sleep 2

scrape_and_create "Holiday Ham with Orange Cranberry Glaze" "https://www.meatchurch.com/blogs/recipes/holiday-ham-with-orange-cranberry-glaze" || FAILED=$((FAILED + 1))
TOTAL=$((TOTAL + 1))
SUCCESS=$((SUCCESS + 1))
sleep 2

scrape_and_create "Magnum Loads" "https://www.meatchurch.com/blogs/recipes/magnum-loads" || FAILED=$((FAILED + 1))
TOTAL=$((TOTAL + 1))
SUCCESS=$((SUCCESS + 1))
sleep 2

scrape_and_create "Party Ribs" "https://www.meatchurch.com/blogs/recipes/party-ribs" || FAILED=$((FAILED + 1))
TOTAL=$((TOTAL + 1))
SUCCESS=$((SUCCESS + 1))
sleep 2

scrape_and_create "Sweet Honey Baby Back Ribs" "https://www.meatchurch.com/blogs/recipes/sweet-honey-baby-back-ribs" || FAILED=$((FAILED + 1))
TOTAL=$((TOTAL + 1))
SUCCESS=$((SUCCESS + 1))
sleep 2

scrape_and_create "Pork Ribs made with Fast Food Restaurant Condiments" "https://www.meatchurch.com/blogs/recipes/pork-ribs-made-with-fast-food-restaurant-condiments" || FAILED=$((FAILED + 1))
TOTAL=$((TOTAL + 1))
SUCCESS=$((SUCCESS + 1))
sleep 2

scrape_and_create "Orange and Soy Glazed Pork Chops" "https://www.meatchurch.com/blogs/recipes/orange-and-soy-glazed-pork-chops" || FAILED=$((FAILED + 1))
TOTAL=$((TOTAL + 1))
SUCCESS=$((SUCCESS + 1))
sleep 2

# Summary
echo ""
echo "========================================="
echo "Meat Church Recipe Import Summary"
echo "========================================="
echo "Total: $TOTAL"
echo "Success: $SUCCESS"
echo "Failed: $FAILED"
echo ""
echo "Process complete!"
