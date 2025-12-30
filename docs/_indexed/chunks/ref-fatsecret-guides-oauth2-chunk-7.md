---
doc_id: ref/fatsecret/guides-oauth2
chunk_id: ref/fatsecret/guides-oauth2#chunk-7
heading_path: ["FatSecret Platform API - OAuth 2.0 Guide", "Use access token"]
chunk_type: code
tokens: 326
summary: "Use access token"
---

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
