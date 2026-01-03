---
doc_id: ops/fatsecret/impl-scope-food-brands-get
chunk_id: ops/fatsecret/impl-scope-food-brands-get#chunk-10
heading_path: ["Implementation Scope: food.brands.get.v2", "Use Cases"]
chunk_type: code
tokens: 159
summary: "Use Cases"
---

## Use Cases

### Primary Use Case: Brand Autocomplete

```rust
// User types "Kel" in search
let brands = search_brands_simple(&config, "Kel").await?;

for brand in brands.brands {
    println!("{}: {} ({})", brand.brand_id, brand.brand_name, brand.brand_type);
}
// Output:
// 1234: Kellogg's (manufacturer)
// 5678: Keebler (manufacturer)
```

### Filter by Type

```rust
// Find restaurant chains starting with "Mc"
let restaurants = get_food_brands(
    &config,
    "Mc",
    Some(BrandType::Restaurant),
    None,
    None
).await?;
```

### Use Brand ID for Food Search

After getting a brand ID, it can be used to filter food searches:

```rust
// Get brand ID from brand search
let brands = search_brands_simple(&config, "Kell").await?;
let kelloggs_id = &brands.brands[0].brand_id;

// Use brand ID in food search (not yet implemented)
// let foods = search_foods_by_brand(&config, kelloggs_id, "corn flakes").await?;
```
