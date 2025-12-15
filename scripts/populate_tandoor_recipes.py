#!/usr/bin/env python3
"""
Populate Tandoor with sample recipes via API
Creates basic recipes: Grilled Chicken, Pasta Carbonara, Caesar Salad
"""

import os
import json
import requests
from datetime import datetime

# Configuration
TANDOOR_URL = os.getenv("TANDOOR_BASE_URL", "http://localhost:8100")
TANDOOR_TOKEN = os.getenv("TANDOOR_API_TOKEN")

if not TANDOOR_TOKEN:
    print("ERROR: TANDOOR_API_TOKEN not set")
    exit(1)

headers = {
    "Authorization": f"Bearer {TANDOOR_TOKEN}",
    "Content-Type": "application/json",
}

# Sample recipes
recipes = [
    {
        "name": "Grilled Chicken Breast",
        "description": "Simple grilled chicken breast with herbs and seasoning",
        "servings": 2,
        "working_time": 15,
        "waiting_time": 0,
        "steps": [
            {
                "step": 1,
                "instruction": "Preheat grill to medium-high heat",
                "ingredients": [],
            },
            {
                "step": 2,
                "instruction": "Season chicken breasts with salt, pepper, and herbs",
                "ingredients": [
                    {
                        "food": {"name": "Chicken Breast"},
                        "unit": {"name": "grams"},
                        "amount": 400,
                        "note": "2 breasts",
                    },
                    {
                        "food": {"name": "Salt"},
                        "unit": {"name": "teaspoons"},
                        "amount": 0.5,
                    },
                    {
                        "food": {"name": "Black Pepper"},
                        "unit": {"name": "teaspoons"},
                        "amount": 0.25,
                    },
                ],
            },
            {
                "step": 3,
                "instruction": "Grill for 6-7 minutes per side until cooked through",
                "ingredients": [],
            },
        ],
    },
    {
        "name": "Spaghetti Carbonara",
        "description": "Classic Italian pasta with eggs, cheese, and pancetta",
        "servings": 2,
        "working_time": 20,
        "waiting_time": 0,
        "steps": [
            {
                "step": 1,
                "instruction": "Cook spaghetti according to package directions",
                "ingredients": [
                    {
                        "food": {"name": "Spaghetti"},
                        "unit": {"name": "grams"},
                        "amount": 200,
                    },
                ],
            },
            {
                "step": 2,
                "instruction": "Fry pancetta until crispy",
                "ingredients": [
                    {
                        "food": {"name": "Pancetta"},
                        "unit": {"name": "grams"},
                        "amount": 100,
                    },
                ],
            },
            {
                "step": 3,
                "instruction": "Mix eggs with cheese",
                "ingredients": [
                    {
                        "food": {"name": "Eggs"},
                        "unit": {"name": "whole"},
                        "amount": 2,
                    },
                    {
                        "food": {"name": "Parmesan Cheese"},
                        "unit": {"name": "grams"},
                        "amount": 100,
                    },
                ],
            },
            {
                "step": 4,
                "instruction": "Combine pasta, pancetta, and egg mixture",
                "ingredients": [],
            },
        ],
    },
    {
        "name": "Caesar Salad",
        "description": "Crisp romaine lettuce with Caesar dressing and croutons",
        "servings": 2,
        "working_time": 10,
        "waiting_time": 0,
        "steps": [
            {
                "step": 1,
                "instruction": "Wash and chop romaine lettuce",
                "ingredients": [
                    {
                        "food": {"name": "Romaine Lettuce"},
                        "unit": {"name": "grams"},
                        "amount": 300,
                    },
                ],
            },
            {
                "step": 2,
                "instruction": "Prepare Caesar dressing with mayonnaise, garlic, lemon",
                "ingredients": [
                    {
                        "food": {"name": "Mayonnaise"},
                        "unit": {"name": "tablespoons"},
                        "amount": 3,
                    },
                    {
                        "food": {"name": "Garlic"},
                        "unit": {"name": "cloves"},
                        "amount": 2,
                    },
                    {
                        "food": {"name": "Lemon"},
                        "unit": {"name": "whole"},
                        "amount": 0.5,
                    },
                ],
            },
            {
                "step": 3,
                "instruction": "Toss lettuce with dressing and add croutons",
                "ingredients": [
                    {
                        "food": {"name": "Croutons"},
                        "unit": {"name": "grams"},
                        "amount": 50,
                    },
                    {
                        "food": {"name": "Parmesan Cheese"},
                        "unit": {"name": "grams"},
                        "amount": 30,
                    },
                ],
            },
        ],
    },
]


def create_recipe(recipe_data):
    """Create a recipe via Tandoor API"""
    url = f"{TANDOOR_URL}/api/recipe/"

    try:
        response = requests.post(url, json=recipe_data, headers=headers, timeout=10)
        if response.status_code == 201:
            result = response.json()
            print(f"✅ Created recipe: {recipe_data['name']} (ID: {result.get('id')})")
            return True
        else:
            print(f"❌ Failed to create {recipe_data['name']}: {response.status_code}")
            print(f"   Response: {response.text}")
            return False
    except Exception as e:
        print(f"❌ Error creating recipe: {e}")
        return False


def main():
    print("🍽️  Populating Tandoor with sample recipes...\n")

    created = 0
    for recipe in recipes:
        if create_recipe(recipe):
            created += 1

    print(f"\n📊 Result: {created}/{len(recipes)} recipes created")


if __name__ == "__main__":
    main()
