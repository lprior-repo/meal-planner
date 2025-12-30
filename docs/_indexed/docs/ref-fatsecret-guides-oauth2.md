---
id: ref/fatsecret/guides-oauth2
title: "FatSecret Platform API - OAuth 2.0 Guide"
category: ref
tags: ["fatsecret", "api", "reference", "oauth"]
---

# FatSecret Platform API - OAuth 2.0 Guide

> **Context**: OAuth 2.0 is the recommended authentication method for the FatSecret Platform API.

OAuth 2.0 is the recommended authentication method for the FatSecret Platform API.

## Overview

- **Grant Type:** Client Credentials
- **Token URL:** `https://oauth.fatsecret.com/connect/token`
- **Token Lifetime:** 86400 seconds (24 hours)

## Requesting an Access Token

Access tokens must be requested through a server-side proxy to protect your credentials.

### Token Request

**Endpoint:** `POST https://oauth.fatsecret.com/connect/token`

**Headers:**
- `Content-Type: application/x-www-form-urlencoded`
- `Authorization: Basic {base64(client_id:client_secret)}`

**Body Parameters:**
- `grant_type=client_credentials`
- `scope={space-separated list of scopes}`

## Scopes

Request only the scopes your application needs:

| Scope | Description |
|-------|-------------|
| `basic` | Basic food and nutrition data access |
| `premier` | Premier features (requires subscription) |
| `barcode` | Barcode lookup functionality |
| `localization` | Localized food data by region/language |
| `nlp` | Natural language processing features |
| `image-recognition` | Food image recognition features |

## Code Examples

### cURL

```bash
## Request access token
curl -X POST "https://oauth.fatsecret.com/connect/token" \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -u "YOUR_CLIENT_ID:YOUR_CLIENT_SECRET" \
  -d "grant_type=client_credentials&scope=basic"

## Use access token
curl -X POST "https://platform.fatsecret.com/rest/foods.search.v3" \
  -H "Authorization: Bearer YOUR_ACCESS_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"search_expression": "apple", "max_results": 5}'
```text

### Node.js

```javascript
const axios = require('axios');

async function getAccessToken(clientId, clientSecret) {
  const credentials = Buffer.from(`${clientId}:${clientSecret}`).toString('base64');
  
  const response = await axios.post(
    'https://oauth.fatsecret.com/connect/token',
    'grant_type=client_credentials&scope=basic',
    {
      headers: {
        'Content-Type': 'application/x-www-form-urlencoded',
        'Authorization': `Basic ${credentials}`
      }
    }
  );
  
  return response.data.access_token;
}

async function searchFoods(accessToken, query) {
  const response = await axios.post(
    'https://platform.fatsecret.com/rest/foods.search.v3',
    {
      search_expression: query,
      max_results: 10
    },
    {
      headers: {
        'Authorization': `Bearer ${accessToken}`,
        'Content-Type': 'application/json'
      }
    }
  );
  
  return response.data;
}

// Usage
(async () => {
  const token = await getAccessToken('YOUR_CLIENT_ID', 'YOUR_CLIENT_SECRET');
  const results = await searchFoods(token, 'chicken breast');
  console.log(results);
})();
```text

### C#

```csharp
using System;
using System.Net.Http;
using System.Net.Http.Headers;
using System.Text;
using System.Threading.Tasks;

public class FatSecretClient
{
    private readonly HttpClient _httpClient;
    private readonly string _clientId;
    private readonly string _clientSecret;
    private string _accessToken;

    public FatSecretClient(string clientId, string clientSecret)
    {
        _httpClient = new HttpClient();
        _clientId = clientId;
        _clientSecret = clientSecret;
    }

    public async Task<string> GetAccessTokenAsync()
    {
        var credentials = Convert.ToBase64String(
            Encoding.UTF8.GetBytes($"{_clientId}:{_clientSecret}"));

        var request = new HttpRequestMessage(HttpMethod.Post, 
            "https://oauth.fatsecret.com/connect/token");
        
        request.Headers.Authorization = 
            new AuthenticationHeaderValue("Basic", credentials);
        
        request.Content = new StringContent(
            "grant_type=client_credentials&scope=basic",
            Encoding.UTF8,
            "application/x-www-form-urlencoded");

        var response = await _httpClient.SendAsync(request);
        response.EnsureSuccessStatusCode();

        var json = await response.Content.ReadAsStringAsync();
        // Parse JSON and extract access_token
        // Using System.Text.Json or Newtonsoft.Json
        
        return _accessToken;
    }

    public async Task<string> SearchFoodsAsync(string query)
    {
        var request = new HttpRequestMessage(HttpMethod.Post,
            "https://platform.fatsecret.com/rest/foods.search.v3");
        
        request.Headers.Authorization = 
            new AuthenticationHeaderValue("Bearer", _accessToken);
        
        request.Content = new StringContent(
            $"{{\"search_expression\":\"{query}\",\"max_results\":10}}",
            Encoding.UTF8,
            "application/json");

        var response = await _httpClient.SendAsync(request);
        return await response.Content.ReadAsStringAsync();
    }
}
```text

## Token Response

```json
{
  "access_token": "eyJhbGciOiJSUzI1NiIsInR5cCI6IkpXVCJ9...",
  "token_type": "Bearer",
  "expires_in": 86400,
  "scope": "basic"
}
```

## Best Practices

1. **Cache tokens** - Reuse tokens until they expire (24 hours)
2. **Server-side only** - Never expose credentials in client-side code
3. **Request minimal scopes** - Only request scopes you need
4. **Handle expiration** - Implement automatic token refresh before expiry
5. **Secure storage** - Store tokens securely, never in plain text


## See Also

- [Documentation Index](./COMPASS.md)
