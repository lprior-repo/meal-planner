---
id: ops/windmill/deployment-guide
title: "Windmill Deployment Guide"
category: ops
tags: ["operations", "advanced", "windmill", "oauth"]
---

<!--
<doc_metadata>
  <type>guide</type>
  <category>deployment</category>
  <title>Windmill Deployment Guide</title>
  <description>Complete guide for deploying meal-planner Windmill infrastructure including resources, variables, schedules, OAuth, and monitoring</description>
  <created_at>2025-12-28T00:00:00Z</created_at>
  <updated_at>2025-12-29T00:00:00Z</updated_at>
  <language>en</language>
  <sections count="9">
    <section name="Prerequisites" level="1"/>
    <section name="Windmill Setup" level="1"/>
    <section name="Resources Configuration" level="1"/>
    <section name="Variables and Secrets" level="1"/>
    <section name="Schedules" level="1"/>
    <section name="OAuth Configuration" level="1"/>
    <section name="Database Migrations" level="1"/>
    <section name="Monitoring and Alerting" level="1"/>
    <section name="Runbook: Common Issues" level="1"/>
  </sections>
  <features>
    <feature>wmill_cli</feature>
    <feature>windmill_resources</feature>
    <feature>oauth</feature>
    <feature>schedules</feature>
    <feature>monitoring</feature>
    <feature>troubleshooting</feature>
  </features>
  <dependencies>
    <dependency type="tool">wmill_cli</dependency>
    <dependency type="service">postgres</dependency>
    <dependency type="service">tandoor</dependency>
    <dependency type="service">fatsecret</dependency>
  </dependencies>
  <code_examples count="15</code_examples>
  <difficulty_level>advanced</difficulty_level>
  <estimated_reading_time>30</estimated_reading_time>
  <tags>windmill,deployment,devops,infrastructure,monitoring,oauth,schedules</tags>
</doc_metadata>
-->

# Windmill Deployment Guide

> **Context**: <!-- <doc_metadata> <type>guide</type> <category>deployment</category> <title>Windmill Deployment Guide</title> <description>Complete guide for deploy

This guide covers deploying the meal-planner Windmill infrastructure, including resources, variables, schedules, OAuth configuration, database migrations, monitoring, and troubleshooting.

---

## Table of Contents

1. [Prerequisites](#prerequisites)
2. [Windmill Setup](#windmill-setup)
3. [Resources Configuration](#resources-configuration)
4. [Variables and Secrets](#variables-and-secrets)
5. [Schedules](#schedules)
6. [OAuth Configuration](#oauth-configuration)
7. [Database Migrations](#database-migrations)
8. [Monitoring and Alerting](#monitoring-and-alerting)
9. [Runbook: Common Issues](#runbook-common-issues)

---

## Prerequisites

### Required Tools

```bash
## Install Windmill CLI
npm install -g windmill-cli

## Verify installation
wmill --version

## Upgrade to latest
wmill upgrade
```

### Environment Setup

Ensure these environment variables are configured:

```bash
## Windmill instance
WINDMILL_BASE_URL=https://your-windmill-instance.com
WINDMILL_TOKEN=your_windmill_api_token
WINDMILL_WORKSPACE=meal-planner

## Database
DATABASE_HOST=localhost
DATABASE_PORT=5432
DATABASE_NAME=meal_planner
DATABASE_USER=postgres
DATABASE_PASSWORD=your_secure_password

## External APIs
TANDOOR_BASE_URL=http://localhost:8100
TANDOOR_API_TOKEN=your_tandoor_token
FATSECRET_CONSUMER_KEY=your_consumer_key
FATSECRET_CONSUMER_SECRET=your_consumer_secret
OAUTH_ENCRYPTION_KEY=your_64_char_hex_key
```

---

## Windmill Setup

### 1. Configure Workspace

```bash
## Add workspace (development)
wmill workspace add meal-planner-dev meal-planner http://localhost:8200

## Add workspace (staging)
wmill workspace add meal-planner-staging meal-planner https://staging.windmill.dev

## Add workspace (production)
wmill workspace add meal-planner-prod meal-planner https://app.windmill.dev

## Switch to target workspace
wmill workspace switch meal-planner-dev

## Verify current workspace
wmill workspace whoami
```

### 2. Initialize Project

```bash
cd /home/lewis/src/meal-planner/windmill

## Initialize wmill configuration
wmill init
```

### 3. Project Structure

```
windmill/
├── f/meal-planner/           # Scripts and flows
│   ├── events/               # Event-driven foundation
│   │   ├── schemas/          # Event type definitions
│   │   ├── producers/        # Event emitters
│   │   └── consumers/        # Event handlers
│   ├── patterns/             # EDA patterns
│   │   ├── idempotency/
│   │   ├── dlq/
│   │   ├── circuit_breaker/
│   │   ├── retry/
│   │   └── saga/
│   ├── handlers/             # Business logic
│   │   ├── recipes/
│   │   ├── meal_planning/
│   │   ├── nutrition/
│   │   ├── shopping_list/
│   │   ├── fatsecret/
│   │   └── tandoor/
│   └── workflows/            # Flow orchestrations
├── resources/                # Resource definitions
├── variables/                # Variable definitions
└── wmill.yaml                # CLI configuration
```

### 4. wmill.yaml Configuration

```yaml
## wmill.yaml - Multi-environment configuration
defaultTs: bun
includes:
  - f/**
excludes: []
codebases: []
skipVariables: false
skipResources: false
skipResourceTypes: false
skipSecrets: true       # Keep secrets manual for security
includeSchedules: true
includeTriggers: true
```

---

## Resources Configuration

### Create Resource Types

Resources store configuration and credentials for external services.

#### PostgreSQL Database

```bash
## Create PostgreSQL resource
wmill resource push - f/meal-planner/database/postgres <<EOF
{
  "host": "\$var:f/meal-planner/vars/db_host",
  "port": 5432,
  "user": "\$var:f/meal-planner/vars/db_user",
  "password": "\$var:f/meal-planner/vars/db_password",
  "dbname": "meal_planner",
  "sslmode": "prefer"
}
EOF
```

### Tandoor API

```bash
## Create Tandoor resource
wmill resource push - f/meal-planner/external_apis/tandoor <<EOF
{
  "base_url": "\$var:f/meal-planner/vars/tandoor_url",
  "api_token": "\$var:f/meal-planner/vars/tandoor_token"
}
EOF
```

### FatSecret API

```bash
## Create FatSecret OAuth resource
wmill resource push - f/meal-planner/external_apis/fatsecret <<EOF
{
  "consumer_key": "\$var:f/meal-planner/vars/fatsecret_key",
  "consumer_secret": "\$var:f/meal-planner/vars/fatsecret_secret",
  "encryption_key": "\$var:f/meal-planner/vars/oauth_encryption_key"
}
EOF
```

### Verify Resources

```bash
## List all resources
wmill resource

## Get specific resource
wmill resource get f/meal-planner/database/postgres
```

---

## Variables and Secrets

### Create Variables

Variables store configuration values. Use secrets for sensitive data.

```bash
## Database configuration
wmill variable add f/meal-planner/vars/db_host --value="localhost"
wmill variable add f/meal-planner/vars/db_user --value="postgres"
wmill variable add f/meal-planner/vars/db_password --value="your_password" --secret

## Tandoor configuration
wmill variable add f/meal-planner/vars/tandoor_url --value="http://localhost:8100"
wmill variable add f/meal-planner/vars/tandoor_token --value="your_token" --secret

## FatSecret configuration
wmill variable add f/meal-planner/vars/fatsecret_key --value="your_key" --secret
wmill variable add f/meal-planner/vars/fatsecret_secret --value="your_secret" --secret
wmill variable add f/meal-planner/vars/oauth_encryption_key --value="your_64_hex_key" --secret
```

### Environment-Specific Variables

Use branch-specific items or separate workspaces for different environments:

```bash
## Development
wmill workspace switch meal-planner-dev
wmill variable add f/meal-planner/vars/environment --value="development"

## Staging
wmill workspace switch meal-planner-staging
wmill variable add f/meal-planner/vars/environment --value="staging"

## Production
wmill workspace switch meal-planner-prod
wmill variable add f/meal-planner/vars/environment --value="production"
```

### Accessing Variables in Scripts

**Python:**
```python
import wmill

## Get variable
db_host = wmill.get_variable("f/meal-planner/vars/db_host")

## Get secret (automatically decrypted)
db_password = wmill.get_variable("f/meal-planner/vars/db_password")
```

**Rust:**
```rust
// Pass as typed resource parameter
fn main(postgres: Postgresql) -> Result<(), Error> {
    let conn = postgres.connect()?;
    // ...
}
```

---

## Schedules

### Create Schedules

Schedules run scripts or flows at specified intervals using cron syntax.

```bash
## Daily meal plan generation (8:00 AM)
wmill schedule create \
  --path f/meal-planner/schedules/daily_meal_plan \
  --schedule "0 0 8 * * *" \
  --timezone "America/Los_Angeles" \
  --script-path f/meal-planner/handlers/meal_planning/generate_plan \
  --args '{"days": 7, "regenerate": false}'

## Hourly FatSecret sync
wmill schedule create \
  --path f/meal-planner/schedules/fatsecret_sync \
  --schedule "0 0 * * * *" \
  --timezone "UTC" \
  --script-path f/meal-planner/handlers/fatsecret/sync_foods \
  --args '{"full_sync": false}'

## Weekly nutrition report (Sunday 9:00 PM)
wmill schedule create \
  --path f/meal-planner/schedules/weekly_nutrition_report \
  --schedule "0 0 21 * * 0" \
  --timezone "America/Los_Angeles" \
  --script-path f/meal-planner/handlers/nutrition/generate_report \
  --args '{"period": "weekly"}'
```

### Schedule with Error Handler

```bash
## Create schedule with Slack error notification
wmill schedule create \
  --path f/meal-planner/schedules/critical_sync \
  --schedule "0 */15 * * * *" \
  --timezone "UTC" \
  --script-path f/meal-planner/handlers/tandoor/sync \
  --args '{}' \
  --on-failure f/meal-planner/handlers/notifications/slack_error
```

### Manage Schedules

```bash
## List all schedules
wmill schedule list

## Enable/disable schedule
wmill schedule enable f/meal-planner/schedules/daily_meal_plan
wmill schedule disable f/meal-planner/schedules/daily_meal_plan

## Delete schedule
wmill schedule delete f/meal-planner/schedules/old_schedule
```

### Cron Syntax Reference

| Expression | Meaning |
|------------|---------|
| `0 0 * * * *` | Every hour |
| `0 0 8 * * *` | Daily at 8:00 AM |
| `0 0 8 * * 1-5` | Weekdays at 8:00 AM |
| `0 0 8 1 * *` | Monthly on 1st at 8:00 AM |
| `0 */15 * * * *` | Every 15 minutes |

Note: Windmill uses 6-field cron (seconds included).

---

## OAuth Configuration

### FatSecret OAuth 1.0a Setup

FatSecret uses 3-legged OAuth 1.0a authentication.

#### 1. Register Application

1. Go to [FatSecret Platform](https://platform.fatsecret.com)
2. Create a new application
3. Note the Consumer Key and Consumer Secret

#### 2. Configure Callback URLs

**Development:**
```
http://localhost:6969/api/oauth/fatsecret/callback
```

**Staging:**
```
https://staging.meal-planner.example.com/api/oauth/fatsecret/callback
```

**Production:**
```
https://meal-planner.example.com/api/oauth/fatsecret/callback
```

#### 3. OAuth Flow Implementation

```rust
// Windmill script: f/meal-planner/handlers/fatsecret/oauth_start
use oauth1_twitter_api::OAuth1;

pub fn main(user_id: String) -> Result<String, Error> {
    let consumer_key = wmill::get_variable("f/meal-planner/vars/fatsecret_key")?;
    let consumer_secret = wmill::get_variable("f/meal-planner/vars/fatsecret_secret")?;

    let oauth = OAuth1::new(consumer_key, consumer_secret);
    let request_token = oauth.get_request_token(CALLBACK_URL)?;

    // Store request token temporarily
    store_request_token(user_id, &request_token)?;

    // Return authorization URL
    Ok(oauth.get_authorize_url(&request_token))
}
```

#### 4. Token Storage Schema

```sql
CREATE TABLE oauth_tokens (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id),
    provider VARCHAR(50) NOT NULL,
    access_token_encrypted BYTEA NOT NULL,
    access_token_secret_encrypted BYTEA,
    refresh_token_encrypted BYTEA,
    expires_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(user_id, provider)
);

CREATE INDEX idx_oauth_tokens_user_provider ON oauth_tokens(user_id, provider);
```

#### 5. Encryption Key Generation

```bash
## Generate a 32-byte (256-bit) encryption key
openssl rand -hex 32
## Output: 499f19656b0ad170fc111dade27baadb53460157003a864ece78ea692f9e2aaa

## Set as Windmill secret
wmill variable add f/meal-planner/vars/oauth_encryption_key \
  --value="499f19656b0ad170fc111dade27baadb53460157003a864ece78ea692f9e2aaa" \
  --secret
```

---

## Database Migrations

### Migration Files Structure

```
src/db/migrations/
├── 001_initial_schema.sql
├── 002_add_oauth_tokens.sql
├── 003_add_meal_plans.sql
└── 004_add_nutrition_goals.sql
```

### OAuth Tokens Migration

```sql
-- migrations/002_add_oauth_tokens.sql
-- Up Migration

CREATE TABLE IF NOT EXISTS oauth_tokens (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL,
    provider VARCHAR(50) NOT NULL,
    access_token_encrypted BYTEA NOT NULL,
    access_token_secret_encrypted BYTEA,
    refresh_token_encrypted BYTEA,
    token_type VARCHAR(50),
    scope TEXT,
    expires_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    CONSTRAINT fk_user FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    CONSTRAINT uq_user_provider UNIQUE(user_id, provider)
);

CREATE INDEX idx_oauth_tokens_user ON oauth_tokens(user_id);
CREATE INDEX idx_oauth_tokens_provider ON oauth_tokens(provider);
CREATE INDEX idx_oauth_tokens_expires ON oauth_tokens(expires_at);

-- Trigger for updated_at
CREATE OR REPLACE FUNCTION update_oauth_tokens_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER tr_oauth_tokens_updated_at
    BEFORE UPDATE ON oauth_tokens
    FOR EACH ROW
    EXECUTE FUNCTION update_oauth_tokens_updated_at();

-- Down Migration (for rollback)
-- DROP TABLE IF EXISTS oauth_tokens CASCADE;
```

### Running Migrations

```bash
## Using psql directly
psql -h $DATABASE_HOST -U $DATABASE_USER -d $DATABASE_NAME \
  -f src/db/migrations/002_add_oauth_tokens.sql

## Or via Windmill script
wmill script run f/meal-planner/db/run_migrations \
  -d '{"migration": "002_add_oauth_tokens"}'
```

### Windmill Migration Script

```rust
// f/meal-planner/db/run_migrations/script.rs
use sqlx::postgres::PgPool;

pub async fn main(postgres: Postgresql, migration: String) -> Result<String, Error> {
    let pool = PgPool::connect(&postgres.connection_string()).await?;

    let migration_sql = include_str!(concat!("../migrations/", migration, ".sql"));

    sqlx::query(migration_sql)
        .execute(&pool)
        .await?;

    Ok(format!("Migration {} completed successfully", migration))
}
```

---

## Monitoring and Alerting

### Workspace Error Handler

Configure workspace-level error handling in Windmill Settings > Error Handler.

#### Slack Integration

```bash
## 1. Connect Slack to workspace (via UI)
## 2. Configure error handler
wmill workspace update --error-handler-slack-channel "meal-planner-alerts"
```

### Custom Error Handler Script

```typescript
// f/meal-planner/handlers/notifications/workspace_error_handler.ts
export async function main(
    workspace_id: string,
    job_id: string,
    path: string,
    is_flow: boolean,
    started_at: string,
    email: string,
    schedule_path?: string
) {
    const run_type = is_flow ? 'flow' : 'script';

    // Send to monitoring system
    await fetch('https://monitoring.example.com/api/alerts', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
            severity: 'error',
            source: 'windmill',
            title: `${run_type} ${path} failed`,
            workspace: workspace_id,
            job_id,
            started_at,
            triggered_by: email,
            schedule: schedule_path
        })
    });

    return { handled: true };
}
```

### Schedule Error Handlers

```bash
## Add error handler to critical schedules
wmill schedule update f/meal-planner/schedules/critical_sync \
  --on-failure f/meal-planner/handlers/notifications/slack_error \
  --on-recovery f/meal-planner/handlers/notifications/slack_recovery
```

### Health Check Endpoints

Create a health check script for monitoring:

```rust
// f/meal-planner/handlers/health/check.rs
use serde_json::json;

pub async fn main(postgres: Postgresql, tandoor: Tandoor) -> Result<serde_json::Value, Error> {
    let mut status = json!({
        "status": "healthy",
        "timestamp": chrono::Utc::now().to_rfc3339(),
        "checks": {}
    });

    // Database check
    let db_ok = check_database(&postgres).await.is_ok();
    status["checks"]["database"] = json!({
        "status": if db_ok { "up" } else { "down" }
    });

    // Tandoor check
    let tandoor_ok = check_tandoor(&tandoor).await.is_ok();
    status["checks"]["tandoor"] = json!({
        "status": if tandoor_ok { "up" } else { "down" }
    });

    if !db_ok || !tandoor_ok {
        status["status"] = json!("degraded");
    }

    Ok(status)
}
```

### Metrics Collection

```rust
// f/meal-planner/handlers/metrics/collect.rs
pub async fn main(postgres: Postgresql) -> Result<serde_json::Value, Error> {
    let pool = postgres.connect().await?;

    let metrics = json!({
        "timestamp": chrono::Utc::now().to_rfc3339(),
        "recipes_count": count_recipes(&pool).await?,
        "meal_plans_count": count_meal_plans(&pool).await?,
        "active_users": count_active_users(&pool).await?,
        "jobs_last_hour": count_jobs_last_hour().await?
    });

    // Push to monitoring
    push_to_prometheus(&metrics).await?;

    Ok(metrics)
}
```

### Alerting Rules

| Metric | Threshold | Action |
|--------|-----------|--------|
| Job failure rate | > 5% in 1h | Slack alert |
| Database connection errors | > 3 in 5m | PagerDuty |
| API response time | > 5s avg | Warning log |
| OAuth token expiry | < 24h | Email reminder |
| Disk usage | > 80% | Slack warning |

---

## Runbook: Common Issues

### Issue: Script Fails to Start

**Symptoms:** Script shows "queued" but never runs

**Diagnosis:**
```bash
## Check worker status
wmill worker list

## Check job queue
wmill job list --status=queued
```

**Resolution:**
1. Verify workers are running: `docker ps | grep windmill-worker`
2. Check worker logs: `docker logs windmill-worker-1`
3. Restart workers if needed: `docker-compose restart windmill-worker`

---

### Issue: Resource Connection Failed

**Symptoms:** "Failed to connect to database" or similar

**Diagnosis:**
```bash
## Verify resource configuration
wmill resource get f/meal-planner/database/postgres

## Test connection manually
psql -h $DB_HOST -U $DB_USER -d $DB_NAME -c "SELECT 1"
```

**Resolution:**
1. Check variable values are correct
2. Verify network connectivity (firewall, security groups)
3. Check credentials haven't expired
4. Update resource with correct values:
   ```bash
   wmill variable update f/meal-planner/vars/db_password --value="new_password"
   ```

---

### Issue: OAuth Token Expired

**Symptoms:** "401 Unauthorized" from FatSecret API

**Diagnosis:**
```sql
SELECT user_id, provider, expires_at
FROM oauth_tokens
WHERE provider = 'fatsecret'
  AND expires_at < NOW();
```

**Resolution:**
1. Trigger token refresh flow
2. If refresh fails, prompt user to re-authorize
3. Clear expired tokens:
   ```sql
   DELETE FROM oauth_tokens
   WHERE expires_at < NOW() - INTERVAL '30 days';
   ```

---

### Issue: Schedule Not Running

**Symptoms:** Scheduled job shows no recent runs

**Diagnosis:**
```bash
## Check schedule status
wmill schedule get f/meal-planner/schedules/daily_meal_plan

## View schedule runs
wmill run list --schedule=f/meal-planner/schedules/daily_meal_plan
```

**Resolution:**
1. Verify schedule is enabled
2. Check cron expression is valid
3. Verify timezone is correct
4. Re-enable schedule:
   ```bash
   wmill schedule disable f/meal-planner/schedules/daily_meal_plan
   wmill schedule enable f/meal-planner/schedules/daily_meal_plan
   ```

---

### Issue: Sync Push Conflicts

**Symptoms:** `wmill sync push` shows conflicts

**Diagnosis:**
```bash
## Pull first to see remote changes
wmill sync pull --show-diffs
```

**Resolution:**
1. Review conflicts in diff output
2. Decide which version to keep
3. Use `--yes` to force push (destructive):
   ```bash
   wmill sync push --yes
   ```
4. Or merge changes manually and push

---

### Issue: Memory/Timeout Errors

**Symptoms:** Job fails with "out of memory" or "timeout"

**Diagnosis:**
```bash
## Check job details
wmill job get <job_id>
```

**Resolution:**
1. Increase worker memory limits in docker-compose
2. Increase job timeout:
   ```yaml
   # In script metadata
   timeout: 600  # 10 minutes
   ```
3. Optimize script to process data in chunks
4. Use dedicated workers for heavy jobs:
   ```yaml
   tag: heavy-compute
   ```

---

### Issue: Secrets Not Accessible

**Symptoms:** "Permission denied" accessing secrets

**Diagnosis:**
```bash
## Check variable permissions
wmill variable get f/meal-planner/vars/db_password

## Check user permissions
wmill user whoami
```

**Resolution:**
1. Verify variable path permissions match user/group
2. Add user to appropriate group:
   ```bash
   wmill group add-user devops <username>
   ```
3. Update variable permissions:
   ```bash
   wmill variable update f/meal-planner/vars/db_password \
     --add-group g/devops
   ```

---

### Issue: Deployment Failed

**Symptoms:** `wmill sync push` shows errors

**Diagnosis:**
```bash
## Check for syntax errors
wmill script generate-metadata

## Validate flow YAML
wmill flow validate f/meal-planner/workflows/main.flow.yaml
```

**Resolution:**
1. Fix syntax errors in scripts
2. Regenerate metadata:
   ```bash
   wmill script generate-metadata
   wmill flow generate-locks
   ```
3. Push again:
   ```bash
   wmill sync push
   ```

---

## Quick Reference

### Common CLI Commands

```bash
## Workspace management
wmill workspace list
wmill workspace switch <name>
wmill workspace whoami

## Scripts
wmill script list
wmill script push <path>
wmill script run <path> -d '{"arg": "value"}'

## Flows
wmill flow list
wmill flow push <file> <path>

## Resources
wmill resource list
wmill resource get <path>
wmill resource push <file> <path>

## Variables
wmill variable list
wmill variable add <path> --value=<val> [--secret]
wmill variable update <path> --value=<val>

## Schedules
wmill schedule list
wmill schedule create --path <path> --schedule "<cron>" --script-path <script>
wmill schedule enable/disable <path>

## Sync
wmill sync pull [--show-diffs]
wmill sync push [--yes]

## Jobs
wmill job list
wmill job get <id>
wmill job cancel <id>
```

### Environment Checklist

- [ ] Windmill CLI installed and updated
- [ ] Workspace configured and accessible
- [ ] PostgreSQL resource created
- [ ] Tandoor API resource configured
- [ ] FatSecret OAuth credentials set
- [ ] Encryption keys generated and stored
- [ ] Database migrations applied
- [ ] Schedules configured and enabled
- [ ] Error handlers configured
- [ ] Monitoring endpoints set up

---

## Support

- Windmill Documentation: https://www.windmill.dev/docs
- Windmill Hub (scripts/resources): https://hub.windmill.dev
- GitHub Issues: https://github.com/windmill-labs/windmill/issues
- Discord Community: https://discord.gg/windmill


## See Also

- [Prerequisites](#prerequisites)
- [Windmill Setup](#windmill-setup)
- [Resources Configuration](#resources-configuration)
- [Variables and Secrets](#variables-and-secrets)
- [Schedules](#schedules)
