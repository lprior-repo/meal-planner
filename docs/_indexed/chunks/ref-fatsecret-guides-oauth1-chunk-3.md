---
doc_id: ref/fatsecret/guides-oauth1
chunk_id: ref/fatsecret/guides-oauth1#chunk-3
heading_path: ["FatSecret Platform API - OAuth 1.0 Guide", "Creating the Signature Base String"]
chunk_type: code
tokens: 88
summary: "Creating the Signature Base String"
---

## Creating the Signature Base String

The signature base string is constructed from three components:

### 1. HTTP Method

Uppercase HTTP method (typically `GET` or `POST`).

### 2. Base URL

The request URL without query parameters, URL-encoded:

```text
https%3A%2F%2Fplatform.fatsecret.com%2Frest%2Fserver.api
```text

### 3. Parameter String

All parameters (OAuth + request parameters) sorted alphabetically, URL-encoded:

```bash
format=json&method=foods.search&oauth_consumer_key=YOUR_KEY&oauth_nonce=abc123&oauth_signature_method=HMAC-SHA1&oauth_timestamp=1234567890&oauth_version=1.0&search_expression=chicken
```

### Combining Components

Join the three components with `&`:

```text
GET&https%3A%2F%2Fplatform.fatsecret.com%2Frest%2Fserver.api&format%3Djson%26method%3Dfoods.search%26oauth_consumer_key%3DYOUR_KEY%26oauth_nonce%3Dabc123%26oauth_signature_method%3DHMAC-SHA1%26oauth_timestamp%3D1234567890%26oauth_version%3D1.0%26search_expression%3Dchicken
```text
