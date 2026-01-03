---
doc_id: ops/fatsecret/impl-scope-food-brands-get
chunk_id: ops/fatsecret/impl-scope-food-brands-get#chunk-9
heading_path: ["Implementation Scope: food.brands.get.v2", "Implementation Notes"]
chunk_type: code
tokens: 189
summary: "Implementation Notes"
---

## Implementation Notes

### Serde Considerations

1. **Single vs Array**: Use `deserialize_single_or_vec` for the `brand` field to handle both single objects and arrays
2. **Empty Results**: The `default` attribute ensures empty responses parse correctly
3. **Opaque IDs**: `BrandId` is transparent (serializes as string) but type-safe

### Brand Type Serialization

```rust
impl BrandType {
    pub fn to_api_string(&self) -> &'static str {
        match self {
            BrandType::Manufacturer => "manufacturer",
            BrandType::Restaurant => "restaurant",
            BrandType::Supermarket => "supermarket",
        }
    }
}

impl Serialize for BrandType {
    fn serialize<S>(&self, serializer: S) -> Result<S::Ok, S::Error>
    where
        S: serde::Serializer,
    {
        serializer.serialize_str(self.to_api_string())
    }
}
```

### Request Building

```rust
let mut params = HashMap::new();
params.insert("starts_with".to_string(), starts_with.to_string());

if let Some(bt) = brand_type {
    params.insert("brand_type".to_string(), bt.to_api_string().to_string());
}

if let Some(r) = region {
    params.insert("region".to_string(), r.to_string());
}

if let Some(l) = language {
    params.insert("language".to_string(), l.to_string());
}

let response_json = make_api_request(config, "food_brands.get.v2", params).await?;
let wrapper: BrandsWrapper = serde_json::from_str(&response_json)?;
Ok(wrapper.brands)
```
