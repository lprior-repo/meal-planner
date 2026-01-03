---
id: ops/fatsecret/guides-libraries
title: "FatSecret Platform API - Third-Party Libraries"
category: ops
tags: ["api", "fatsecret", "operations"]
---

<!--
<doc_metadata>
  <type>guide</type>
  <category>api</category>
  <title>FatSecret Platform API - Third-Party Libraries</title>
  <description>Community-maintained libraries and resources for integrating with the FatSecret Platform API.</description>
  <created_at>2026-01-02T19:55:26.862903</created_at>
  <updated_at>2026-01-02T19:55:26.862903</updated_at>
  <language>en</language>
  <sections count="14">
    <section name="Official Resources" level="2"/>
    <section name="Postman Collection" level="3"/>
    <section name="Third-Party Libraries" level="2"/>
    <section name="Python" level="3"/>
    <section name="pyfatsecret" level="4"/>
    <section name="PHP" level="3"/>
    <section name="fatsecret-laravel" level="4"/>
    <section name="Swift" level="3"/>
    <section name="FatSecretSwift" level="4"/>
    <section name="Community Support" level="2"/>
  </sections>
  <features>
    <feature>community_support</feature>
    <feature>contributing_libraries</feature>
    <feature>developer_forum</feature>
    <feature>disclaimer</feature>
    <feature>fatsecret-laravel</feature>
    <feature>fatsecretswift</feature>
    <feature>js_client</feature>
    <feature>js_error</feature>
    <feature>js_foods</feature>
    <feature>official_resources</feature>
    <feature>postman_collection</feature>
    <feature>pyfatsecret</feature>
    <feature>python</feature>
    <feature>swift</feature>
    <feature>third-party_libraries</feature>
  </features>
  <dependencies>
    <dependency type="library">requests</dependency>
  </dependencies>
  <examples count="6">
    <example type="code">Code examples included</example>
  </examples>
  <difficulty_level>intermediate</difficulty_level>
  <estimated_reading_time>2</estimated_reading_time>
  <tags>api,fatsecret,operations</tags>
</doc_metadata>
-->

# FatSecret Platform API - Third-Party Libraries

> **Context**: Community-maintained libraries and resources for integrating with the FatSecret Platform API.

Community-maintained libraries and resources for integrating with the FatSecret Platform API.

## Official Resources

### Postman Collection

A Postman collection for testing and exploring the API is available on GitHub.

**Repository:** [FatSecret Postman Collection](https://github.com/fatsecret/postman)

Features:
- Pre-configured requests for all API endpoints
- OAuth 1.0 and OAuth 2.0 authentication examples
- Environment variables for easy configuration
- Request/response examples

## Third-Party Libraries

### Python

#### pyfatsecret

A Python wrapper for the FatSecret Platform API.

**Installation:**
```bash
pip install fatsecret
```text

**Repository:** [pyfatsecret on GitHub](https://github.com/borucsan/pyfatsecret)

**Usage:**
```python
from fatsecret import Fatsecret

fs = Fatsecret(consumer_key, consumer_secret)

## Search for foods
foods = fs.foods_search("chicken breast")

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

## Community Support

### Developer Forum

The FatSecret Platform developer community on Google Groups provides:
- Technical support and troubleshooting
- API usage discussions
- Feature requests and feedback
- Code examples and best practices

**Forum:** [FatSecret Platform API Google Group](https://groups.google.com/g/fatsecret-platform-api)

### Tips for Getting Help

1. Search existing discussions before posting
2. Include relevant code snippets
3. Provide error messages and response data
4. Specify your authentication method (OAuth 1.0 or 2.0)
5. Include your programming language and platform

## Contributing Libraries

If you've created a library for the FatSecret Platform API:

1. Ensure it handles both OAuth 1.0 and OAuth 2.0
2. Include comprehensive documentation
3. Provide usage examples
4. Add proper error handling
5. Share it on the developer forum

## Disclaimer

Third-party libraries are community-maintained and not officially supported by FatSecret. Always:

- Review the library code before use
- Check the license for compatibility
- Verify the library is actively maintained
- Test thoroughly before production use


## See Also

- [Documentation Index](./COMPASS.md)
