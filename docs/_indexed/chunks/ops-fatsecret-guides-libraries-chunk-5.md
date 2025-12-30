---
doc_id: ops/fatsecret/guides-libraries
chunk_id: ops/fatsecret/guides-libraries#chunk-5
heading_path: ["FatSecret Platform API - Third-Party Libraries", "Get food details"]
chunk_type: code
tokens: 154
summary: "Get food details"
---

## Get food details
food = fs.food_get(food_id)
```text

### PHP

#### fatsecret-laravel

A Laravel package for FatSecret API integration.

**Installation:**
```bash
composer require braunson/fatsecret-laravel
```text

**Repository:** [fatsecret-laravel on GitHub](https://github.com/braunson/fatsecret-laravel)

**Usage:**
```php
use Braunson\FatSecret\FatSecret;

$fatsecret = new FatSecret($consumerKey, $consumerSecret);

// Search for foods
$results = $fatsecret->searchIngredients('apple');

// Get food by ID
$food = $fatsecret->getIngredient($foodId);
```text

### Swift

#### FatSecretSwift

A Swift library for iOS and macOS applications.

**Installation (Swift Package Manager):**
```swift
dependencies: [
    .package(url: "https://github.com/nicholasspencer/FatSecretSwift.git", from: "1.0.0")
]
```text

**Repository:** [FatSecretSwift on GitHub](https://github.com/nicholasspencer/FatSecretSwift)

**Usage:**
```swift
import FatSecretSwift

let client = FatSecretClient(
    consumerKey: "YOUR_KEY",
    consumerSecret: "YOUR_SECRET"
)

// Search for foods
client.searchFoods(query: "banana") { result in
    switch result {
    case .success(let foods):
        print(foods)
    case .failure(let error):
        print(error)
    }
}
```
