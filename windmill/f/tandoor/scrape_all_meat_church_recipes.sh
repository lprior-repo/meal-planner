import subprocess
import json
import sys

def main(args):
    """Import all Meat Church recipes into Tandoor"""
    
    # Hardcoded Tandoor API credentials (will retrieve from env in Windmill)
    # For local testing without Windmill:
    # tandoor = {
    #     "base_url": "http://localhost:8090",
    #     "api_token": "test"
    # }
    # For Windmill:
    tandoor = args.get('tandoor', {})
    
    if isinstance(tandoor, dict) and 'base_url' in tandoor and 'api_token' in tandoor:
        base_url = tandoor['base_url']
        api_token = tandoor['api_token']
    else:
        print(json.dumps({'success': False, 'error': 'tandoor resource must be a dict with base_url and api_token'}), file=sys.stderr)
        sys.exit(1)
    
    # List of Meat Church recipes to import
    recipes = [
        # Beef
        ("Eye of Round", "https://www.meatchurch.com/blogs/recipes/eye-of-round"),
        ("Brisket Flat", "https://www.meatchurch.com/blogs/recipes/brisket-flat"),
        ("Brisket Cheesesteak", "https://www.meatchurch.com/blogs/recipes/brisket-cheesesteak"),
        ("Pastrami Brisket with B4 Barbeque", "https://www.meatchurch.com/blogs/recipes/pastrami-brisket-with-b4-barbeque"),
        ("Thor's Hammer AKA Beef Shank", "https://www.meatchurch.com/blogs/recipes/thors-hammer-aka-beef-shank"),
        ("Cottage Pie", "https://www.meatchurch.com/blogs/recipes/cottage-pie"),
        ("Red Wine Braised Short Ribs", "https://www.meatchurch.com/blogs/recipes/red-wine-braised-short-ribs"),
        ("Beef Party Ribs with Bourbon BBQ Sauce", "https://www.meatchurch.com/blogs/recipes/beef-party-ribs-with-bourbon-bbq-sauce"),
        ("How to make Beef Tallow", "https://www.meatchurch.com/blogs/recipes/how-to-make-beef-tallow"),
        ("Roasted Sloppy Joe Stuffed Bell Peppers", "https://www.meatchurch.com/blogs/recipes/roasted-sloppy-joe-stuffed-bell-peppers"),
        ("Smoking a Select Grade Brisket", "https://www.meatchurch.com/blogs/recipes/smoking-a-select-grade-brisket"),
        ("Poor Man's Burnt Ends", "https://www.meatchurch.com/blogs/recipes/poor-mans-burnt-ends"),
        
        # Chicken
        ("Mexican Street Corn White Chicken Chili", "https://www.meatchurch.com/blogs/recipes/mexican-street-corn-white-chicken-chili"),
        ("Mexican Chicken Wings", "https://www.meatchurch.com/blogs/recipes/mexican-chicken-wings"),
        ("0 - 400 Chicken Wings", "https://www.meatchurch.com/blogs/recipes/0-400-chicken-wings"),
        ("Backyard BBQ Chicken with Bar-A-BBQ", "https://www.meatchurch.com/blogs/recipes/backyard-bbq-chicken-with-bar-a-bbq"),
        ("Chimichurri Chicken", "https://www.meatchurch.com/blogs/recipes/chimichurri-chicken"),
        ("Chicken & Dumplings", "https://www.meatchurch.com/blogs/recipes/chicken-and-dumplings"),
        ("Marry Me Chicken", "https://www.meatchurch.com/blogs/recipes/marry-me-chicken"),
        ("Cowboy Lollipops with Smoked Prickly Pear Glaze", "https://www.meatchurch.com/blogs/recipes/cowboy-lollipops-with-smoked-prickly-pear-glaze"),
        ("The Ultimate Tailgating Chicken Wing Spread", "https://www.meatchurch.com/blogs/recipes/the-ultimate-tailgating-chicken-wing-spread"),
        ("Cajun Stuffed Boneless Chicken with Andrew Duhon", "https://www.meatchurch.com/blogs/recipes/cajun-stuffed-boneless-chicken-with-andrew-duhon"),
        ("Grilled Pear Burner Wings", "https://www.meatchurch.com/blogs/recipes/grilled-pear-burner-wings"),
        ("King Ranch Casserole", "https://www.meatchurch.com/blogs/recipes/king-ranch-casserole"),
        
        # Pork
        ("Smoked Pulled Ham", "https://www.meatchurch.com/blogs/recipes/smoked-pulled-ham"),
        ("Taquitos Vatos Locos", "https://www.meatchurch.com/blogs/recipes/taquitos-vatos-locos"),
        ("Carolina Twinkies", "https://www.meatchurch.com/blogs/recipes/carolina-twinkies"),
        ("Apple Cherry Habanero Ribs", "https://www.meatchurch.com/blogs/recipes/apple-cherry-habanero-ribs"),
        ("Hickory Pulled Pork", "https://www.meatchurch.com/blogs/recipes/hickory-pulled-pork"),
        ("Wild Hog Boneless Loin", "https://www.meatchurch.com/blogs/recipes/wild-hog-boneless-loin"),
        ("Holiday Ham with Orange Cranberry Glaze", "https://www.meatchurch.com/blogs/recipes/holiday-ham-with-orange-cranberry-glaze"),
        ("Magnum Loads", "https://www.meatchurch.com/blogs/recipes/magnum-loads"),
        ("Party Ribs", "https://www.meatchurch.com/blogs/recipes/party-ribs"),
        ("Sweet Honey Baby Back Ribs", "https://www.meatchurch.com/blogs/recipes/sweet-honey-baby-back-ribs"),
        ("Pork Ribs made with Fast Food Restaurant Condiments", "https://www.meatchurch.com/blogs/recipes/pork-ribs-made-with-fast-food-restaurant-condiments"),
        ("Orange and Soy Glazed Pork Chops", "https://www.meatchurch.com/blogs/recipes/orange-and-soy-glazed-pork-chops"),
    ]
    
    total = len(recipes)
    success = 0
    failed_recipes = []
    
    for i, (name, url) in enumerate(recipes):
        print(f"Processing {i+1}/{total}: {name}...", file=sys.stderr, flush=True)
        
        # Scrape recipe using existing binary
        scrape_cmd = [
            'wmill', 'script', 'run', 'f/tandoor/scrape_recipe',
            '-d', json.dumps({
                'tandoor': tandoor,
                'url': url
            })
        ]
        scrape_result = subprocess.run(scrape_cmd, capture_output=True, text=True)
        
        if not scrape_result.stdout.strip():
            error_msg = scrape_result.stdout.strip() or scrape_result.stderr.strip()
            print(f"  ✗ Failed to scrape {name}: {error_msg}", file=sys.stderr)
            failed_recipes.append({'name': name, 'error': error_msg})
            continue
        
        try:
            scrape_data = json.loads(scrape_result.stdout)
        except json.JSONDecodeError as e:
            print(f"  ✗ Failed to parse scrape result for {name}: {e}", file=sys.stderr)
            failed_recipes.append({'name': name, 'error': str(e)})
            continue
        
        if not scrape_data.get('success'):
            print(f"  ✗ Failed to create: {name}: {scrape_data.get('error')}", file=sys.stderr)
            failed_recipes.append({'name': name, 'error': scrape_data.get('error')})
            continue
        
        # Create recipe with keywords
        recipe_json = json.dumps(scrape_data.get('recipe', {}))
        create_cmd = [
            'wmill', 'script', 'run', 'f/tandoor/create_recipe',
            '-d', json.dumps({
                'tandoor': tandoor,
                'recipe_json': recipe_json,
                'keywords': ['meat-church', 'bbq']
            })
        ]
        create_result = subprocess.run(create_cmd, capture_output=True, text=True)
        
        try:
            create_data = json.loads(create_result.stdout)
        except json.JSONDecodeError as e:
            print(f"  ✗ Failed to create: {name}: {create_result.stdout.strip()}", file=sys.stderr)
            failed_recipes.append({'name': name, 'error': create_result.stdout.strip()})
            continue
        
        if not create_data.get('success'):
            print(f"  ✗ Failed to create: {name}: {create_data.get('error')}", file=sys.stderr)
            failed_recipes.append({'name': name, 'error': create_data.get('error')})
            continue
        
        if create_data.get('success'):
            recipe_id = create_data.get('recipe_id')
            print(f"  ✓ Imported: {name} (ID: {recipe_id})", file=sys.stderr, flush=True)
            success += 1
        
        # Rate limiting
        if i < 10:
            import time.sleep(3)
        else:
            import time.sleep(2)
    
    print(f"\n{'='*60}", file=sys.stderr, flush=True)
    print(f"Summary: {success}/{total} successful", file=sys.stderr, flush=True)
    if failed_recipes:
        print(f"Failed recipes:", file=sys.stderr, flush=True)
        for failed in failed_recipes:
            print(f"  - {failed['name']}: {failed['error']}", file=sys.stderr, flush=True)
    
    result = {
        'success': True,
        'total': total,
        'successful': success,
        'failed': len(failed_recipes),
        'failed_list': failed_recipes
    }
    
    print(json.dumps(result, indent=2))

if __name__ == '__main__':
    main()
