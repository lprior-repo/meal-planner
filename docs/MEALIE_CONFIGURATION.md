# Mealie Configuration Guide

Complete reference for configuring meal-planner to work with Mealie recipe server.

## Environment Variables

The application requires two essential environment variables to connect to a Mealie server:

### MEALIE_BASE_URL (Required)

The base URL of your Mealie server instance.

**Format:**
```bash
export MEALIE_BASE_URL="http://hostname:port"
```

**Examples:**
```bash
# Local development
export MEALIE_BASE_URL="http://localhost:8080"

# Remote server
export MEALIE_BASE_URL="http://mealie.example.com"
export MEALIE_BASE_URL="https://recipes.yourcompany.com"
```

**Important Notes:**
- Do NOT include trailing slash
- Use `http://` for local development
- Use `https://` for production servers
- The application will normalize the URL automatically

### MEALIE_API_TOKEN (Required)

API token for authentication with the Mealie server.

**How to Generate:**

1. Open your Mealie instance in a browser
2. Go to Settings > Profile > API Tokens
3. Click "Create Token"
4. Copy the token value

**Token Security:**
- Never commit tokens to version control
- Rotate tokens periodically
- Use environment variables or secrets management
- Use different tokens for different environments

### MEALIE_REQUEST_TIMEOUT_MS (Optional)

Timeout for HTTP requests to Mealie in milliseconds.

**Default:** 5000ms (5 seconds)

**When to Adjust:**
- Increase if you get frequent timeouts
- Decrease if you want faster failure detection
- Set to 0 for infinite timeout (not recommended)

## Setting Up Environment Variables

### For Local Development

**Create a `.env` file:**
```bash
MEALIE_BASE_URL=http://localhost:8080
MEALIE_API_TOKEN=your-api-token-here
MEALIE_REQUEST_TIMEOUT_MS=5000
```

**Load before running:**
```bash
source .env
gleam run
```

### For Docker

**In docker-compose.yml:**
```yaml
services:
  meal-planner:
    environment:
      MEALIE_BASE_URL: http://mealie:8080
      MEALIE_API_TOKEN: your-api-token-here
```

### For Systemd Service

**In `/etc/systemd/system/meal-planner.service`:**
```ini
Environment="MEALIE_BASE_URL=http://localhost:8080"
Environment="MEALIE_API_TOKEN=your-api-token-here"
```

## Mealie Server Setup

### Docker Installation

**Start a Mealie server locally:**
```bash
docker run -d --name mealie -p 8080:80 \
  ghcr.io/mealie-recipes/mealie:latest
```

**Verify it's running:**
```bash
curl http://localhost:8080
```

## Verifying Configuration

### Test Connection

**Using curl:**
```bash
curl -H "Authorization: Bearer $MEALIE_API_TOKEN" \
  "$MEALIE_BASE_URL/api/recipes"
```

**Expected response:** JSON with recipe data

**If you get an error:**
- `Connection refused` - Mealie server not running
- `401 Unauthorized` - Invalid or missing token
- `404 Not Found` - Wrong base URL

## Configuration Validation Checklist

- [ ] MEALIE_BASE_URL is set
- [ ] MEALIE_API_TOKEN is valid
- [ ] Network connectivity verified
- [ ] No trailing slashes in MEALIE_BASE_URL
- [ ] Environment variables exported before running
- [ ] Token is not in version control

## Troubleshooting

### "ConfigError: Mealie base URL and API token are required"

**Solution:**
```bash
export MEALIE_BASE_URL="http://localhost:8080"
export MEALIE_API_TOKEN="your-token-here"
```

### "Connection refused"

**Solution:**
```bash
# Verify Mealie is running
docker ps | grep mealie

# Check URL is correct
echo $MEALIE_BASE_URL
```

### "401 Unauthorized"

**Solution:**
- Verify MEALIE_API_TOKEN is correct
- Generate new token in Mealie settings
- Verify token has read access

### "Request timed out"

**Solution:**
```bash
# Increase timeout
export MEALIE_REQUEST_TIMEOUT_MS="10000"
```

## Production Best Practices

1. **Use strong HTTPS URLs**
2. **Rotate tokens regularly**
3. **Use service accounts for applications**
4. **Store tokens securely (secrets management)**
5. **Never log full tokens**
6. **Have fallback plan for Mealie downtime**
