# Mealie API Troubleshooting Guide

Common issues when using Mealie with meal-planner and how to resolve them.

## Configuration Issues

### "ConfigError: Mealie base URL and API token are required"

**Root Causes:**
1. Environment variables not set
2. Empty or whitespace-only variable values
3. Variables set in wrong shell/terminal

**Solutions:**
```bash
echo "Base URL: $MEALIE_BASE_URL"
echo "API Token: $MEALIE_API_TOKEN"

# If blank, set them
export MEALIE_BASE_URL="http://localhost:8080"
export MEALIE_API_TOKEN="your-api-token-here"
```

## Connection Issues

### "HttpError: HTTP request failed: connection refused"

**Root Causes:**
1. Mealie server not running
2. Incorrect hostname or port
3. Firewall blocking access

**Solutions:**
```bash
# Verify Mealie is running
docker ps | grep mealie

# Test connectivity
curl http://localhost:8080

# Check URL format (no trailing slash)
echo $MEALIE_BASE_URL
```

### "DnsResolutionFailed: Couldn't resolve hostname"

**Root Causes:**
1. DNS server not responding
2. Hostname spelled wrong
3. Hostname not in DNS

**Solutions:**
```bash
# Test DNS resolution
nslookup mealie.example.com

# Try with IP address temporarily
export MEALIE_BASE_URL="http://192.168.1.100:8080"
```

## Authentication Issues

### "ApiError: HTTP 401 Unauthorized"

**Root Causes:**
1. API token is incorrect
2. API token has expired
3. Token lacks required permissions

**Solutions:**
```bash
# Verify token value (check for spaces)
echo "Token length: ${#MEALIE_API_TOKEN}"

# Generate new token in Mealie
# Settings > Profile > API Tokens > Create Token

export MEALIE_API_TOKEN="new-token-value-here"
```

### "ApiError: HTTP 403 Forbidden"

**Root Causes:**
1. Token lacks permissions for endpoint
2. Recipe is private/restricted
3. User permissions changed

**Solutions:**
- Check token permissions in Mealie settings
- Create "All permissions" token for testing
- Verify recipe exists and is shared

## Timeout Issues

### "NetworkTimeout: Request exceeded timeout"

**Root Causes:**
1. Mealie server is slow
2. Network is slow
3. Timeout setting too aggressive

**Solutions:**
```bash
# Increase timeout
export MEALIE_REQUEST_TIMEOUT_MS="10000"

# Test direct request timing
time curl http://localhost:8080/api/recipes

# Check network latency
ping mealie.example.com
```

**Recommended timeout values:**
- Local development: `3000`
- Local network: `5000` (default)
- WAN/Internet: `10000-15000`

## Data Issues

### "RecipeNotFound: Recipe not found with the given slug"

**Root Causes:**
1. Recipe slug is wrong
2. Recipe was deleted from Mealie
3. Wrong case in slug

**Solutions:**
```bash
# List all recipes to find slug
curl -H "Authorization: Bearer $MEALIE_API_TOKEN" \
  http://localhost:8080/api/recipes

# Use correct slug (lowercase, hyphens)
# Example: grilled-chicken-breast
```

### "ApiError: Invalid JSON response from Mealie"

**Root Causes:**
1. Mealie API response format changed
2. Older Mealie version with different API
3. Malformed response from Mealie

**Solutions:**
```bash
# Check Mealie version
curl http://localhost:8080/api/system/info

# Get raw API response
curl -H "Authorization: Bearer $MEALIE_API_TOKEN" \
  http://localhost:8080/api/recipes | python3 -m json.tool
```

## Service Availability Issues

### "MealieUnavailable: Mealie service unavailable or unreachable"

**Root Causes:**
1. Mealie crashed or stopped
2. Server restart in progress
3. Disk/memory full

**Solutions:**
```bash
# Check Mealie is running
docker ps | grep mealie

# Restart if needed
docker restart mealie

# Check resources
free -h
df -h
```

## Network Issues

### Connection hangs or is very slow

**Solutions:**
```bash
# Set lower timeout to fail faster
export MEALIE_REQUEST_TIMEOUT_MS="3000"

# Test direct routing (if Mealie is remote)
mtr mealie.example.com

# Restart network connection
sudo systemctl restart networking
```

## Quick Diagnostic Script

```bash
#!/bin/bash

echo "=== Mealie Connectivity Test ==="

echo "1. Configuration:"
echo "   MEALIE_BASE_URL: $MEALIE_BASE_URL"
echo "   MEALIE_API_TOKEN: ${MEALIE_API_TOKEN:0:20}..."

echo -e "\n2. DNS Resolution:"
nslookup $(echo $MEALIE_BASE_URL | sed 's|http://||' | cut -d: -f1)

echo -e "\n3. Connectivity:"
curl -v "$MEALIE_BASE_URL/api/recipes" 2>&1 | head -20

echo -e "\n=== Test Complete ==="
```

Save as `test-mealie.sh` and run:
```bash
chmod +x test-mealie.sh
./test-mealie.sh
```

## Getting Help

If issues persist after trying these solutions:

1. **Check logs:**
   - Mealie logs: `docker logs mealie`
   - System logs: `journalctl -xe`

2. **Collect information:**
   - Mealie version
   - Exact error message
   - Network details

3. **Resources:**
   - Mealie docs: https://docs.mealie.io/
   - Project GitHub: Report issue with collected info
