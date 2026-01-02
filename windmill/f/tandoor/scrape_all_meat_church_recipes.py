#!/usr/bin/env python3
"""Scrape all Meat Church recipes and import into Tandoor"""

import json
import sys
import subprocess


def run_windmill_script(script_name, data):
    """Run a Windmill script and return result"""
    import subprocess

    json_str = json.dumps(data)
    cmd = ["wmill", "script", "run", script_name, "-d", json_str]
    result = subprocess.run(cmd, capture_output=True, text=True)
    return json.loads(result.stdout)


def scrape_recipe(url, tandoor_api):
    """Scrape a single recipe from Meat Church"""
    # Scrape recipe
    scrape_result = run_windmill_script(
        "f/tandoor/scrape_recipe", {"tandoor": "$res:u/admin/tandoor_api", "url": url}
    )

    if not scrape_result.get("success"):
        return {"success": False, "recipe": None, "error": scrape_result.get("error")}

    recipe_data = scrape_result.get("recipe", {})
    recipe_json = json.dumps(recipe_data)

    # Create recipe with Meat Church keywords
    create_result = run_windmill_script(
        "f/tandoor/create_recipe",
        {
            "tandoor": "$res:u/admin/tandoor_api",
            "recipe_json": recipe_json,
            "keywords": ["meat-church", "bbq"],
        },
    )

    return {
        "success": create_result.get("success"),
        "recipe": recipe_data.get("name", "Unknown"),
        "recipe_id": create_result.get("recipe_id"),
        "error": create_result.get("error"),
    }


def main():
    """Main function"""
    # List of Meat Church recipe URLs to scrape
    # From Beef category
    recipes = [
        # Beef recipes
        ("Eye of Round", "https://www.meatchurch.com/blogs/recipes/eye-of-round"),
        ("Brisket Flat", "https://www.meatchurch.com/blogs/recipes/brisket-flat"),
        (
            "Brisket Cheesesteak",
            "https://www.meatchurch.com/blogs/recipes/brisket-cheesesteak",
        ),
        (
            "Pastrami Brisket with B4 Barbeque",
            "https://www.meatchurch.com/blogs/recipes/pastrami-brisket-with-b4-barbeque",
        ),
        (
            "Thor's Hammer AKA Beef Shank",
            "https://www.meatchurch.com/blogs/recipes/thors-hammer-aka-beef-shank",
        ),
        ("Cottage Pie", "https://www.meatchurch.com/blogs/recipes/cottage-pie"),
        (
            "Red Wine Braised Short Ribs",
            "https://www.meatchurch.com/blogs/recipes/red-wine-braised-short-ribs",
        ),
        (
            "Beef Party Ribs with Bourbon BBQ Sauce",
            "https://www.meatchurch.com/blogs/recipes/beef-party-ribs-with-bourbon-bbq-sauce",
        ),
        (
            "How to make Beef Tallow",
            "https://www.meatchurch.com/blogs/recipes/how-to-make-beef-tallow",
        ),
        (
            "Roasted Sloppy Joe Stuffed Bell Peppers",
            "https://www.meatchurch.com/blogs/recipes/roasted-sloppy-joe-stuffed-bell-peppers",
        ),
        (
            "Smoking a Select Grade Brisket",
            "https://www.meatchurch.com/blogs/recipes/smoking-a-select-grade-brisket",
        ),
        (
            "Poor Man's Burnt Ends",
            "https://www.meatchurch.com/blogs/recipes/poor-mans-burnt-ends",
        ),
        # Chicken recipes
        (
            "Mexican Street Corn White Chicken Chili",
            "https://www.meatchurch.com/blogs/recipes/mexican-street-corn-white-chicken-chili",
        ),
        (
            "Mexican Chicken Wings",
            "https://www.meatchurch.com/blogs/recipes/mexican-chicken-wings",
        ),
        (
            "0 - 400 Chicken Wings",
            "https://www.meatchurch.com/blogs/recipes/0-400-chicken-wings",
        ),
        (
            "Backyard BBQ Chicken with Bar-A-BBQ",
            "https://www.meatchurch.com/blogs/recipes/backyard-bbq-chicken-with-bar-a-bbq",
        ),
        (
            "Chimichurri Chicken",
            "https://www.meatchurch.com/blogs/recipes/chimichurri-chicken",
        ),
        (
            "Chicken & Dumplings",
            "https://www.meatchurch.com/blogs/recipes/chicken-and-dumplings",
        ),
        (
            "Marry Me Chicken",
            "https://www.meatchurch.com/blogs/recipes/marry-me-chicken",
        ),
        (
            "Cowboy Lollipops with Smoked Prickly Pear Glaze",
            "https://www.meatchurch.com/blogs/recipes/cowboy-lollipops-with-smoked-prickly-pear-glaze",
        ),
        (
            "The Ultimate Tailgating Chicken Wing Spread",
            "https://www.meatchurch.com/blogs/recipes/the-ultimate-tailgating-chicken-wing-spread",
        ),
        (
            "Cajun Stuffed Boneless Chicken with Andrew Duhon",
            "https://www.meatchurch.com/blogs/recipes/cajun-stuffed-boneless-chicken-with-andrew-duhon",
        ),
        (
            "Grilled Pear Burner Wings",
            "https://www.meatchurch.com/blogs/recipes/grilled-pear-burner-wings",
        ),
        (
            "King Ranch Casserole",
            "https://www.meatchurch.com/blogs/recipes/king-ranch-casserole",
        ),
        # Pork recipes
        (
            "Smoked Pulled Ham",
            "https://www.meatchurch.com/blogs/recipes/smoked-pulled-ham",
        ),
        (
            "Taquitos Vatos Locos",
            "https://www.meatchurch.com/blogs/recipes/taquitos-vatos-locos",
        ),
        (
            "Carolina Twinkies",
            "https://www.meatchurch.com/blogs/recipes/carolina-twinkies",
        ),
        (
            "Apple Cherry Habanero Ribs",
            "https://www.meatchurch.com/blogs/recipes/apple-cherry-habanero-ribs",
        ),
        (
            "Hickory Pulled Pork",
            "https://www.meatchurch.com/blogs/recipes/hickory-pulled-pork",
        ),
        (
            "Wild Hog Boneless Loin",
            "https://www.meatchurch.com/blogs/recipes/wild-hog-boneless-loin",
        ),
        (
            "Holiday Ham with Orange Cranberry Glaze",
            "https://www.meatchurch.com/blogs/recipes/holiday-ham-with-orange-cranberry-glaze",
        ),
        ("Magnum Loads", "https://www.meatchurch.com/blogs/recipes/magnum-loads"),
        ("Party Ribs", "https://www.meatchurch.com/blogs/recipes/party-ribs"),
        (
            "Sweet Honey Baby Back Ribs",
            "https://www.meatchurch.com/blogs/recipes/sweet-honey-baby-back-ribs",
        ),
        (
            "Pork Ribs made with Fast Food Restaurant Condiments",
            "https://www.meatchurch.com/blogs/recipes/pork-ribs-made-with-fast-food-restaurant-condiments",
        ),
        (
            "Orange and Soy Glazed Pork Chops",
            "https://www.meatchurch.com/blogs/recipes/orange-and-soy-glazed-pork-chops",
        ),
    ]

    results = {"total": len(recipes), "recipes": []}

    for i, (name, url) in enumerate(recipes, 1):
        print(f"Scraping {i}/{len(recipes)}: {name}...", file=sys.stderr, flush=True)

        result = scrape_recipe(url, "$res:u/admin/tandoor_api")

        if result["success"]:
            results["recipes"].append(
                {
                    "name": name,
                    "success": True,
                    "recipe_id": result["recipe_id"],
                    "error": None,
                }
            )
            print(f"  ✓ Imported: {name} (ID: {result['recipe_id']})", file=sys.stderr)
        else:
            results["recipes"].append(
                {
                    "name": name,
                    "success": False,
                    "recipe_id": None,
                    "error": result.get("error"),
                }
            )
            print(f"  ✗ Failed: {name} - {result.get('error')}", file=sys.stderr)

    print(
        f"\nCompleted: {sum(1 for r in results['recipes'] if r['success'])}/{len(recipes)} successful",
        file=sys.stderr,
    )

    print(json.dumps(results, indent=2))


if __name__ == "__main__":
    main()
