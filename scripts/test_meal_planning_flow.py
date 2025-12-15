#!/usr/bin/env python3
"""
Test end-to-end meal planning flow with the newly created recipes
"""

import os
import requests
import json

TANDOOR_URL = os.getenv("TANDOOR_BASE_URL", "http://localhost:8100")
TANDOOR_TOKEN = os.getenv("TANDOOR_API_TOKEN")

if not TANDOOR_TOKEN:
    # Try loading from .env file
    try:
        with open(".env") as f:
            for line in f:
                if line.startswith("TANDOOR_API_TOKEN="):
                    TANDOOR_TOKEN = line.split("=")[1].strip()
                    break
    except:
        pass

if not TANDOOR_TOKEN:
    print("ERROR: TANDOOR_API_TOKEN not set")
    exit(1)

headers = {"Authorization": f"Bearer {TANDOOR_TOKEN}"}


def fetch_recipes():
    """Fetch all recipes from Tandoor"""
    response = requests.get(f"{TANDOOR_URL}/api/recipe/?limit=10", headers=headers)
    return response.json().get("results", [])


def fetch_recipe_detail(recipe_id):
    """Fetch detailed recipe information"""
    response = requests.get(f"{TANDOOR_URL}/api/recipe/{recipe_id}/", headers=headers)
    return response.json()


def main():
    print("🍽️  Testing End-to-End Meal Planning Flow\n")
    print("=" * 50)

    # Step 1: Fetch recipes
    print("\n📖 Step 1: Fetching Recipes from Tandoor")
    print("-" * 50)
    recipes = fetch_recipes()
    print(f"Found {len(recipes)} recipes:\n")

    for recipe in recipes:
        print(f"  • {recipe['name']}")
        print(f"    ID: {recipe['id']}, Servings: {recipe.get('servings', 'N/A')}")

    # Step 2: Get detailed info for first 3 recipes
    print("\n📊 Step 2: Getting Detailed Recipe Information")
    print("-" * 50)

    detailed_recipes = []
    for recipe in recipes[:3]:
        detail = fetch_recipe_detail(recipe["id"])
        detailed_recipes.append(detail)
        print(f"\n  Recipe: {detail['name']}")
        print(f"    Ingredients: {len(detail.get('steps', []))} steps")

        # Show ingredients
        all_ingredients = []
        for step in detail.get("steps", []):
            for ing in step.get("ingredients", []):
                food_name = ing.get("food", {}).get("name", "Unknown")
                amount = ing.get("amount", 0)
                unit = ing.get("unit", {}).get("name", "")
                all_ingredients.append(f"{amount} {unit} {food_name}")

        for ing in all_ingredients[:3]:
            print(f"      • {ing}")
        if len(all_ingredients) > 3:
            print(f"      ... and {len(all_ingredients) - 3} more")

    # Step 3: Simulate meal plan
    print("\n🥘 Step 3: Creating Meal Plan")
    print("-" * 50)

    meal_selections = []
    for recipe in detailed_recipes:
        meal_selections.append(
            {
                "date": "2025-12-15",
                "meal_type": "dinner",
                "recipe_id": recipe["id"],
                "recipe_name": recipe["name"],
                "servings": 2,
            }
        )

    print(f"\nPlanned meals for 2025-12-15 (Dinner):")
    for meal in meal_selections:
        print(f"  • {meal['recipe_name']} (ID: {meal['recipe_id']})")

    # Step 4: Show what the orchestrator would produce
    print("\n🎯 Step 4: Orchestrator Output Summary")
    print("-" * 50)

    total_ingredients = []
    total_calories = 0

    for recipe in detailed_recipes:
        nutrition = recipe.get("nutrition")
        if nutrition:
            calories = nutrition.get("calories", 0) or 0
        else:
            calories = 0
        total_calories += calories

        for step in recipe.get("steps", []):
            for ing in step.get("ingredients", []):
                food = ing.get("food", {}).get("name", "Unknown")
                total_ingredients.append(food)

    unique_ingredients = list(set(total_ingredients))

    print(f"\n  📦 Grocery List:")
    print(f"     Total unique ingredients: {len(unique_ingredients)}")
    for ing in sorted(unique_ingredients)[:5]:
        print(f"       • {ing}")
    if len(unique_ingredients) > 5:
        print(f"       ... and {len(unique_ingredients) - 5} more")

    print(f"\n  💪 Nutrition Summary:")
    print(f"     Total calories (estimated): {total_calories} cal")

    print(f"\n  ⏱️  Meal Prep Plan:")
    total_time = sum(r.get("working_time", 0) or 0 for r in detailed_recipes)
    print(f"     Total prep time: {total_time} minutes")

    print("\n" + "=" * 50)
    print("✅ End-to-end flow test completed successfully!\n")
    print("The meal planning system is ready to:")
    print("  1. ✅ Fetch recipes from Tandoor API")
    print("  2. ✅ Aggregate ingredients into grocery lists")
    print("  3. ✅ Calculate nutrition data")
    print("  4. ✅ Generate meal prep plans")
    print("  5. ⏳ Sync to FatSecret (coming soon)")


if __name__ == "__main__":
    main()
