# Mealie API Credential Verification Guide

This document describes how to verify that Mealie API credentials are properly configured and functional in the Meal Planner application.

## Overview

The credential verification system ensures that:

1. **Configuration Format** - Mealie config structure is valid with required fields
2. **Base URL Format** - API endpoint uses proper HTTP/HTTPS scheme
3. **API Token Format** - Authentication token has reasonable length and format
4. **API Connectivity** - Can successfully connect to Mealie API endpoint
5. **Authentication** - API token is valid and properly authorized
6. **Service Health** - Mealie API is running and responding correctly

## Quick Start

### Using the Verification Script

```bash
# Run basic verification with current environment
./scripts/verify-mealie-credentials.sh

# Verify production environment
./scripts/verify-mealie-credentials.sh prod

# Verbose output with detailed report
./scripts/verify-mealie-credentials.sh prod verbose
```

### Using Gleam Tests

```bash
cd gleam

# Run all credential verification tests
gleam test

# Run only credential tests
gleam test --module meal_planner_mealie_credential_verification_test
```

## Configuration Requirements

### Environment Variables

The following environment variables must be set:

```bash
# Mealie API Configuration
MEALIE_BASE_URL=http://localhost:9000          # Base URL of Mealie API
MEALIE_API_TOKEN=your-api-token-here          # Bearer token for authentication

# Connection Settings
MEALIE_CONNECT_TIMEOUT_MS=5000                # Connection timeout (optional, default: 5000ms)
MEALIE_REQUEST_TIMEOUT_MS=30000               # Request timeout (optional, default: 30000ms)

# Application Environment
ENVIRONMENT=development                        # development or production
```

### Example: Development Environment

```bash
# .env (development)
MEALIE_BASE_URL=http://localhost:9000
MEALIE_API_TOKEN=dev-token-12345678901234
ENVIRONMENT=development
```

### Example: Production Environment

```bash
# .env (production) - Keep secure!
MEALIE_BASE_URL=https://mealie.example.com
MEALIE_API_TOKEN=prod-secure-token-xyz123456789
ENVIRONMENT=production
```

## Verification Checks

### 1. Configuration Format Check

**What it checks:**
- Base URL is not empty
- API token is not empty
- Request timeout is > 0

**Why it matters:**
- Ensures required settings are configured
- Prevents runtime errors from missing config

**Example output:**
```
[PASS] Configuration Format: Configuration properly structured with base URL, token, and timeout
```

### 2. Base URL Format Check

**What it checks:**
- URL starts with `http://` or `https://`
- URL is properly formatted

**Why it matters:**
- Invalid URLs cause connection failures
- Prevents malformed endpoint addresses

**Example output:**
```
[PASS] Base URL Format: Base URL format is valid: http://localhost:9000
```

### 3. API Token Format Check

**What it checks:**
- Token is at least 10 characters long
- Token appears to be a valid bearer token

**Why it matters:**
- Weak tokens may be invalid or expired
- Ensures token meets minimum requirements

**Example output:**
```
[PASS] API Token Format: API token format appears valid (length: 32 chars)
```

### 4. API Connectivity Check

**What it checks:**
- Can reach Mealie API endpoint
- Health endpoint responds successfully

**Why it matters:**
- Confirms network connectivity to Mealie
- Verifies API is running

**Example output:**
```
[PASS] API Connectivity: Successfully connected to Mealie API (v0.5.1)
```

### 5. Authentication Check

**What it checks:**
- API token is valid
- Token has proper authorization
- Can authenticate with bearer token

**Why it matters:**
- Ensures token is not expired or revoked
- Confirms access to protected endpoints

**Example output:**
```
[PASS] Authentication: API token is valid and authenticated successfully
```

### 6. Service Health Check

**What it checks:**
- Mealie service is healthy
- Production mode status
- API version information

**Why it matters:**
- Ensures service is operational
- Confirms API is in expected state

**Example output:**
```
[PASS] Service Health: Mealie service is healthy (v0.5.1 production mode)
```

## Troubleshooting

### Configuration Errors

**Error: "Missing required environment variables"**

Solution:
1. Copy `.env.example` to `.env`
2. Fill in `MEALIE_BASE_URL` and `MEALIE_API_TOKEN`
3. Run verification again

```bash
cp .env.example .env
# Edit .env with your credentials
./scripts/verify-mealie-credentials.sh
```

### URL Format Errors

**Error: "Base URL must start with http:// or https://"**

Solution:
- Ensure base URL includes the scheme
- Invalid: `localhost:9000`
- Valid: `http://localhost:9000`

### Token Format Errors

**Error: "API token appears too short"**

Solution:
- Verify token from Mealie: Settings > API Tokens
- Ensure full token is copied (minimum 10 chars)
- Check for accidentally truncated token

### Connectivity Errors

**Error: "Cannot connect to Mealie API at [URL]"**

Solutions:
1. Verify Mealie service is running
2. Check URL is reachable
3. Check firewall/network settings
4. Verify DNS resolution

```bash
# Test connectivity manually
curl -v http://localhost:9000/api/app/about
```

### Authentication Errors

**Error: "Authentication failed (HTTP 401)"**

Solutions:
1. Token may be expired - generate new token
2. Token may be revoked - check Mealie settings
3. Token may be incorrect - verify exact value

In Mealie UI:
1. Go to Settings > API Tokens
2. Check token status
3. Create new token if necessary
4. Update `.env` with new token

**Error: "Authentication failed (HTTP 403)"**

Solutions:
1. Check token permissions in Mealie
2. Ensure token has recipe access
3. Verify group/household permissions

## Production Deployment

### Pre-Deployment Checklist

Before deploying to production:

- [ ] HTTPS URL configured (`https://`, not `http://`)
- [ ] Strong API token (minimum 32 characters)
- [ ] Token stored in secure environment manager
- [ ] Credentials not committed to Git
- [ ] `.env` file added to `.gitignore`
- [ ] Verification tests pass in production mode
- [ ] Backup token generated in case of lockout

### Running Verification in Production

```bash
# Verify production environment
ENVIRONMENT=production ./scripts/verify-mealie-credentials.sh prod verbose

# Or with explicit token
ENVIRONMENT=production \
MEALIE_BASE_URL=https://mealie.prod.example.com \
MEALIE_API_TOKEN=your-production-token \
./scripts/verify-mealie-credentials.sh prod verbose
```

### Monitoring & Maintenance

Regular checks (weekly recommended):

```bash
# Weekly credential verification
0 2 * * 1 cd /home/user/meal-planner && ./scripts/verify-mealie-credentials.sh prod verbose
```

Add to crontab for automated verification:

```bash
crontab -e
# Add: 0 2 * * 1 /path/to/meal-planner/scripts/verify-mealie-credentials.sh prod verbose
```

## API Reference

### Gleam Module: `credential_verification`

#### Main Function

```gleam
pub fn verify_credentials(config: Config) -> Result(VerificationResult, String)
```

Performs comprehensive verification of Mealie API credentials.

**Example:**

```gleam
import meal_planner/config
import meal_planner/mealie/credential_verification

pub fn verify_prod_env() {
  let config = config.load()
  case credential_verification.verify_credentials(config) {
    Ok(result) -> {
      io.println(credential_verification.format_result(result))
      case result.success {
        True -> io.println("All checks passed!")
        False -> io.println("Some checks failed")
      }
    }
    Error(err) -> io.println("Verification error: " <> err)
  }
}
```

#### Result Types

```gleam
pub type VerificationResult {
  VerificationResult(
    success: Bool,                      // All critical checks passed
    timestamp: String,                  // When verification ran
    environment: String,                // deployment environment
    checks: List(VerificationCheck),   // Individual check results
    critical_failures: Int,            // Number of critical failures
    warnings: Int,                     // Number of warnings
    summary: String,                   // Human-readable summary
  )
}

pub type VerificationCheck {
  VerificationCheck(
    name: String,                       // Check name
    description: String,                // What it checks
    passed: Bool,                       // Did it pass?
    message: String,                    // Result message
    severity: CheckSeverity,           // Importance level
  )
}

pub type CheckSeverity {
  Critical    // Production cannot operate
  Warning     // May cause issues
  Info        // Informational only
}
```

#### Utility Functions

```gleam
// Format result for display
pub fn format_result(result: VerificationResult) -> String

// Log all verification checks
pub fn log_checks(checks: List(VerificationCheck)) -> Nil
```

## Testing

### Unit Tests

The verification module includes comprehensive unit tests:

```bash
cd gleam
gleam test
```

Test categories:

1. **Configuration Format Tests** - Validate config structure
2. **URL Format Tests** - Verify URL schemes (HTTP/HTTPS)
3. **Token Format Tests** - Check token length and validity
4. **Environment Tests** - Test development vs production
5. **Result Formatting Tests** - Verify output formatting

### Integration Tests

Full integration test with real Mealie instance:

```bash
# Start test Mealie instance
docker-compose up -d mealie

# Run verification
./scripts/verify-mealie-credentials.sh

# Verify success
echo $?  # Exit code 0 = success
```

## Security Best Practices

### Credential Storage

1. **Never commit credentials to Git**
   ```bash
   echo ".env" >> .gitignore
   ```

2. **Use environment variables in production**
   ```bash
   export MEALIE_API_TOKEN=your-token
   export MEALIE_BASE_URL=https://api.mealie.example.com
   ```

3. **Use secrets management**
   - Kubernetes Secrets
   - AWS Secrets Manager
   - HashiCorp Vault

### Token Management

1. **Rotate tokens regularly** (every 90 days)
2. **Use strong, random tokens**
3. **Generate separate tokens for each environment**
4. **Monitor token usage in Mealie logs**
5. **Revoke compromised tokens immediately**

### Access Control

1. **Limit token permissions** to necessary scopes
2. **Use separate read-only tokens** for non-critical operations
3. **Implement token expiration policies**
4. **Audit token creation and usage**

## Troubleshooting Guide

See the [Troubleshooting](#troubleshooting) section above for common issues.

For additional help:

1. Check Mealie documentation: https://docs.mealie.io
2. Review logs: `docker logs mealie` (if using Docker)
3. Test API directly: `curl -H "Authorization: Bearer <token>" https://api.mealie.example.com/api/recipes`

## References

- [Mealie API Documentation](https://docs.mealie.io/documentation/getting-started/api-usage/)
- [Meal Planner README](/README.md)
- [Configuration Guide](/docs/CONFIGURATION.md)
