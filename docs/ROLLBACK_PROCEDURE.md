# Rollback Procedure - Database and Code

## Overview

This document provides comprehensive guidance for rolling back deployments in the Meal Planner application, covering both database migrations and application code changes. Rollbacks may be necessary when:

- A migration introduces data corruption or schema conflicts
- Application code contains critical bugs or regressions
- Performance degradation occurs after deployment
- Integration issues arise with Mealie or external services

**Key Principle**: Always rollback database changes BEFORE code changes to maintain consistency.

---

## Part 1: Database Rollback Procedures

### Quick Reference

| Situation | Approach | Risk Level |
|-----------|----------|-----------|
| Single migration failed | Restore from backup | Low |
| Data corruption detected | Point-in-time recovery | Low |
| Need to revert multiple migrations | Rollback scripts + manual verification | Medium |
| Production incident with active users | Live rollback with transaction | High |

### 1.1 Pre-Rollback Checklist

Before starting any rollback:

```bash
# 1. Verify database connectivity
psql -h localhost -U postgres -d meal_planner -c "SELECT version();"

# 2. Check current migration status
psql -h localhost -U postgres -d meal_planner -c "SELECT * FROM schema_migrations ORDER BY version DESC LIMIT 5;"

# 3. List active connections
psql -h localhost -U postgres -d meal_planner -c "SELECT pid, usename, application_name, query FROM pg_stat_activity WHERE datname = 'meal_planner';"

# 4. Backup current state (ALWAYS DO THIS)
pg_dump -h localhost -U postgres -d meal_planner -F custom -f meal_planner_backup_$(date +%Y%m%d_%H%M%S).dump

# 5. Disable application access
# Stop the Gleam backend service to prevent writes during rollback
docker stop meal-planner-gleam
```

### 1.2 Rollback a Single Migration

**Scenario**: Migration 023 introduced a bug and needs to be reverted.

#### Step 1: Stop Application

```bash
# Docker environment
docker-compose stop meal-planner-gleam

# Or native environment
systemctl stop meal-planner-api
```

#### Step 2: Connect to Database

```bash
psql -h localhost -U postgres -d meal_planner
```

#### Step 3: Execute Rollback Script

```sql
-- Check what migration 023 did
SELECT * FROM schema_migrations WHERE version = 23;

-- Start transaction (CRITICAL for safety)
BEGIN;

-- Execute rollback script
\i gleam/migrations_pg/rollback/023_revert_recipe_json_column.sql

-- Verify results
SELECT * FROM auto_meal_plans LIMIT 1;

-- If everything looks good, commit
COMMIT;

-- If something went wrong, ROLLBACK
-- ROLLBACK;
```

#### Step 4: Remove Migration Record

```sql
-- Remove the failed migration from tracking
DELETE FROM schema_migrations WHERE version = 23;

-- Verify
SELECT * FROM schema_migrations ORDER BY version DESC LIMIT 5;
```

#### Step 5: Restart Application

```bash
# Docker environment
docker-compose up -d meal-planner-gleam

# Or native environment
systemctl start meal-planner-api

# Verify health
curl http://localhost:8080/health
```

#### Step 6: Run Smoke Tests

```bash
# Test critical endpoints
curl -X GET http://localhost:8080/api/logs
curl -X GET http://localhost:8080/api/meal-plans
```

### 1.3 Rollback Multiple Consecutive Migrations

**Scenario**: Migrations 021, 022, and 023 need to be reverted in reverse order.

```bash
# Start with backup
pg_dump -h localhost -U postgres -d meal_planner -F custom -f meal_planner_backup_multi_rollback.dump

# Stop application
docker-compose stop meal-planner-gleam

# Connect to database
psql -h localhost -U postgres -d meal_planner
```

```sql
-- Rollback in REVERSE order (most recent first)
BEGIN;

-- Rollback 023
\i gleam/migrations_pg/rollback/023_revert_recipe_json_column.sql

-- Rollback 022
\i gleam/migrations_pg/rollback/022_revert_source_type_rename.sql

-- Rollback 021
\i gleam/migrations_pg/rollback/021_revert_recipe_sources_audit_drop.sql

-- Remove all three from tracking
DELETE FROM schema_migrations WHERE version IN (21, 22, 23);

-- Verify
SELECT * FROM schema_migrations ORDER BY version DESC LIMIT 5;

COMMIT;
```

Then restart:

```bash
docker-compose up -d meal-planner-gleam
```

### 1.4 Manual Rollback When No Script Exists

**Scenario**: A rollback script doesn't exist yet, but you need to revert the migration.

#### Step 1: Understand the Migration

```bash
# Read the forward migration
cat gleam/migrations_pg/020_drop_recipes_simplified_table.sql

# Output:
# DROP TABLE IF EXISTS recipes_simplified CASCADE;
```

#### Step 2: Create Reverse SQL

```bash
# Create rollback script
cat > gleam/migrations_pg/rollback/020_restore_recipes_simplified_table.sql << 'EOF'
-- Rollback for 020_drop_recipes_simplified_table.sql
-- Restores the recipes_simplified table structure (without data)

CREATE TABLE IF NOT EXISTS recipes_simplified (
    id SERIAL PRIMARY KEY,
    name VARCHAR(255) NOT NULL UNIQUE,
    calories INT NOT NULL,
    protein INT NOT NULL,
    carbs INT NOT NULL,
    fat INT NOT NULL,
    verified BOOLEAN DEFAULT FALSE,
    branded BOOLEAN DEFAULT FALSE,
    category VARCHAR(100) NOT NULL,
    tags TEXT,
    description TEXT,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW()
);

-- Recreate indexes
CREATE INDEX IF NOT EXISTS idx_recipes_simplified_protein ON recipes_simplified(protein);
CREATE INDEX IF NOT EXISTS idx_recipes_simplified_fat ON recipes_simplified(fat);
CREATE INDEX IF NOT EXISTS idx_recipes_simplified_category ON recipes_simplified(category);
CREATE INDEX IF NOT EXISTS idx_recipes_simplified_verified ON recipes_simplified(verified);
CREATE INDEX IF NOT EXISTS idx_recipes_simplified_branded ON recipes_simplified(branded);

-- Note: Original data is not restored. This only recreates the schema.
-- To restore data, you would need to recover from a backup.
EOF
```

#### Step 3: Execute and Verify

```bash
psql -h localhost -U postgres -d meal_planner < gleam/migrations_pg/rollback/020_restore_recipes_simplified_table.sql

# Verify
psql -h localhost -U postgres -d meal_planner -c "SELECT * FROM recipes_simplified LIMIT 1;"
```

### 1.5 Point-in-Time Recovery (PITR)

**Scenario**: Data corruption detected across multiple migrations; need to restore to a known good state.

#### Prerequisites

PostgreSQL must have WAL (Write-Ahead Logging) enabled:

```bash
# Verify WAL archiving is enabled
psql -h localhost -U postgres -d meal_planner -c "SHOW wal_level; SHOW archive_command;"
```

#### Recovery Steps

```bash
# 1. Stop application
docker-compose stop meal-planner-gleam

# 2. Create recovery target
# Example: Recover to 2 hours ago
RECOVERY_TARGET_TIME='2025-12-12 10:00:00'

# 3. Backup current data directory
sudo cp -r /var/lib/postgresql/data /var/lib/postgresql/data.corrupted

# 4. Initiate recovery
# For Docker:
docker-compose stop meal-planner-postgres

# Create recovery configuration
docker exec meal-planner-postgres pg_basebackup \
  -h localhost \
  -U postgres \
  -D /var/lib/postgresql/recovery \
  -Fp -Xs -P

# 5. Edit recovery configuration (inside container)
docker exec meal-planner-postgres tee /etc/postgresql/recovery.conf << EOF
recovery_target_timeline = 'latest'
recovery_target_time = '${RECOVERY_TARGET_TIME}'
recovery_target_inclusive = true
EOF

# 6. Restart PostgreSQL
docker-compose up -d meal-planner-postgres

# 7. Monitor recovery
docker-compose logs -f meal-planner-postgres

# 8. Verify recovery completed
docker exec meal-planner-postgres psql -U postgres -d meal_planner -c "SELECT * FROM schema_migrations ORDER BY version DESC LIMIT 5;"

# 9. Restart application
docker-compose up -d meal-planner-gleam
```

### 1.6 Emergency Database Reset

**WARNING**: Use only when data is corrupted beyond repair.

```bash
# 1. Backup corrupted database
pg_dump -h localhost -U postgres -d meal_planner -F custom -f meal_planner_corrupted_backup.dump

# 2. Drop corrupted database
psql -h localhost -U postgres -c "DROP DATABASE IF EXISTS meal_planner;"

# 3. Create fresh database
psql -h localhost -U postgres -c "CREATE DATABASE meal_planner;"

# 4. Re-apply all migrations from scratch
for migration in gleam/migrations_pg/00*.sql; do
    echo "Applying $migration..."
    psql -h localhost -U postgres -d meal_planner -f "$migration"
done

# 5. Verify state
psql -h localhost -U postgres -d meal_planner -c "SELECT COUNT(*) FROM schema_migrations;"

# 6. Restore data from backup if available
pg_restore -h localhost -U postgres -d meal_planner -j 4 meal_planner_backup.dump
```

---

## Part 2: Code Rollback Procedures

### 2.1 Git-Based Code Rollback

#### Understanding Current State

```bash
# View recent commits
git log --oneline -10

# View current branch
git branch -v

# Check for uncommitted changes
git status
```

#### Rollback Strategy 1: Revert a Specific Commit

**Scenario**: Commit `abc1234` introduced a bug and needs to be reverted.

```bash
# Option A: Revert (creates new commit, keeps history)
git revert abc1234

# Option B: Reset to previous commit (destructive, use only on feature branches)
git reset --hard HEAD~1

# Push changes
git push origin main
```

#### Rollback Strategy 2: Rollback to Previous Release Tag

**Scenario**: Need to rollback to the last stable release.

```bash
# View available tags
git tag -l --sort=-version:refname | head -10

# Checkout specific tag
git checkout v1.2.0

# Or create a branch from tag for testing
git checkout -b rollback-test v1.2.0

# When ready to deploy
git checkout main
git reset --hard v1.2.0
git push origin main --force
```

#### Rollback Strategy 3: Roll Forward Instead

**Recommended**: Instead of reverting commits, create a fix commit.

```bash
# 1. Create new branch from main
git checkout -b fix/regression-from-abc1234

# 2. Identify and fix the issue
vim gleam/src/meal_planner/web/handlers/meals.gleam

# 3. Run tests
gleam test

# 4. Commit and push
git add gleam/src/meal_planner/web/handlers/meals.gleam
git commit -m "Fix regression from abc1234: Correct meal endpoint validation"
git push origin fix/regression-from-abc1234

# 5. Create PR and merge after review
```

### 2.2 Deployment Rollback

#### Using Docker Compose

```bash
# Stop current deployment
docker-compose down

# View available images (tagged by version)
docker images | grep meal-planner

# Start previous version
GLEAM_VERSION=v1.2.0 docker-compose up -d

# Verify
docker-compose ps
curl http://localhost:8080/health
```

#### Rolling Back with Version Tags

```bash
# Build and tag new version
docker build -f gleam/Dockerfile -t meal-planner-gleam:v1.2.1 .

# In docker-compose.yml, specify tag
# image: meal-planner-gleam:v1.2.1

# Deploy
docker-compose up -d --pull always

# If issues, rollback to previous version
docker-compose down
# Edit docker-compose.yml to use v1.2.0
docker-compose up -d

# Verify
curl http://localhost:8080/health
```

### 2.3 Feature Flag-Based Rollback

**Best Practice**: Use feature flags for safe rollbacks without code changes.

#### Example: Feature Flag Rollback

```gleam
// File: gleam/src/meal_planner/features.gleam
pub fn is_mealie_integration_enabled() -> Bool {
  case env.get("FEATURE_MEALIE_ENABLED") {
    Ok("true") -> True
    _ -> False
  }
}
```

Usage in handlers:

```gleam
// File: gleam/src/meal_planner/web/handlers/meals.gleam
pub fn get_meals(req: Request(Connection)) -> Response(String) {
  case features.is_mealie_integration_enabled() {
    True -> mealie.get_meals()  // New code path
    False -> legacy.get_meals() // Fallback code path
  }
}
```

Rollback without code changes:

```bash
# Set environment variable
export FEATURE_MEALIE_ENABLED=false

# Restart application
docker-compose restart meal-planner-gleam

# Verify
curl http://localhost:8080/api/meals

# Logs should show using legacy path
docker-compose logs meal-planner-gleam | grep "using legacy"
```

### 2.4 Canary Rollback Strategy

**For Large Deployments**: Gradually roll back by adjusting traffic distribution.

```bash
# Current state: 100% traffic to new version
# Load balancer config points all traffic to v1.2.1

# Step 1: Reduce traffic to new version
# 90% → old version (v1.2.0)
# 10% → new version (v1.2.1)
# Monitor for issues...

# Step 2: Further reduce
# 99% → old version
# 1% → new version
# Monitor error rates...

# Step 3: Complete rollback if needed
# 100% → old version
# Remove v1.2.1 from load balancer
```

Implementation with Docker Compose:

```yaml
# docker-compose.yml with multiple instances
services:
  meal-planner-gleam-v1:
    image: meal-planner-gleam:v1.2.0
    ports:
      - "8080:8080"
    environment:
      - INSTANCE_ID=v1

  meal-planner-gleam-v2:
    image: meal-planner-gleam:v1.2.1
    ports:
      - "8081:8080"
    environment:
      - INSTANCE_ID=v2

  nginx:
    image: nginx:latest
    ports:
      - "8000:80"
    volumes:
      - ./nginx.conf:/etc/nginx/nginx.conf:ro
```

nginx.conf:

```nginx
upstream meal_planner_new {
    server meal-planner-gleam-v2:8080 weight=10;
}

upstream meal_planner_old {
    server meal-planner-gleam-v1:8080 weight=90;
}

server {
    listen 80;
    location / {
        proxy_pass http://meal_planner_old;
        proxy_pass http://meal_planner_new;
    }
}
```

### 2.5 Application State Considerations

#### Clearing Caches

```bash
# Redis cache (if used)
docker exec meal-planner-redis redis-cli FLUSHALL

# File-based cache
rm -rf /var/cache/meal-planner/*

# Browser cache (client-side)
# Users should clear browser cache or use Ctrl+Shift+Delete
```

#### Clearing Sessions

```bash
# If session data stored in PostgreSQL
psql -h localhost -U postgres -d meal_planner -c "DELETE FROM sessions WHERE created_at < NOW() - INTERVAL '1 hour';"

# If using Redis
docker exec meal-planner-redis redis-cli --scan --pattern "session:*" | xargs redis-cli DEL
```

#### Configuration Reloads

```bash
# Reload without restarting
curl -X POST http://localhost:8080/admin/reload-config

# Or restart with preserved data
docker-compose restart meal-planner-gleam
```

---

## Part 3: Combined Database + Code Rollback

### 3.1 Full System Rollback Scenario

**Scenario**: Deploy v1.2.1 that includes migration 023. Issues discovered. Need full rollback.

#### Timeline of Events

```
12:00 - Deploy v1.2.1 with migration 023
12:15 - Users report issues with meal plans
12:30 - Investigation shows migration 023 corrupted data
12:45 - Decision: Full rollback
```

#### Rollback Procedure

```bash
# Step 1: Notify users (if applicable)
# Post message: "Experiencing issues, initiating rollback"

# Step 2: Stop application
docker-compose down

# Step 3: Backup current state
pg_dump -h localhost -U postgres -d meal_planner -F custom -f meal_planner_incident_backup.dump

# Step 4: Rollback database
docker-compose up -d meal-planner-postgres
sleep 5

psql -h localhost -U postgres -d meal_planner << EOF
BEGIN;
\i gleam/migrations_pg/rollback/023_revert_recipe_json_column.sql
DELETE FROM schema_migrations WHERE version = 23;
COMMIT;
EOF

# Step 5: Verify database state
psql -h localhost -U postgres -d meal_planner -c "SELECT * FROM schema_migrations ORDER BY version DESC LIMIT 5;"

# Step 6: Deploy previous code version
git checkout v1.2.0

# Step 7: Rebuild and start
docker-compose up --build -d meal-planner-gleam

# Step 8: Verify application health
sleep 10
curl http://localhost:8080/health

# Step 9: Run smoke tests
bash scripts/smoke-tests.sh

# Step 10: Update status
# Post message: "Rollback complete, system restored to v1.2.0"
```

### 3.2 Coordinated Multi-Service Rollback

**Scenario**: Changes affect both Gleam app and Mealie integration.

```bash
# Check all services status
docker-compose ps

# Stop all services
docker-compose down

# Backup databases
pg_dump -h localhost -U postgres -d meal_planner -F custom -f meal_planner_backup.dump
pg_dump -h localhost -U postgres -d mealie -F custom -f mealie_backup.dump

# Start PostgreSQL only
docker-compose up -d meal-planner-postgres

# Run database rollbacks
psql -h localhost -U postgres -d meal_planner -c "..."
psql -h localhost -U postgres -d mealie -c "..."

# Revert code
git checkout v1.2.0

# Restart all services
docker-compose up --build -d

# Verify all services
curl http://localhost:8080/health
curl http://localhost:9000/api/about
```

---

## Part 4: Testing Rollbacks

### 4.1 Pre-Deployment Rollback Testing

Before deploying, test the rollback procedure:

```bash
# On staging environment
docker-compose -f docker-compose.staging.yml up -d

# Simulate production state
psql -h localhost -U postgres -d meal_planner < backup_staging.sql

# Test forward migration
psql -h localhost -U postgres -d meal_planner -f gleam/migrations_pg/023_add_recipe_json_to_auto_meal_plans.sql

# Test rollback
psql -h localhost -U postgres -d meal_planner -f gleam/migrations_pg/rollback/023_revert_recipe_json_column.sql

# Verify consistency
psql -h localhost -U postgres -d meal_planner -c "SELECT COUNT(*) FROM auto_meal_plans;"
```

### 4.2 Rollback Documentation Template

Create this for every risky migration:

```markdown
# Migration 023: Add recipe_json to auto_meal_plans

## Forward Description
Adds JSONB column to cache recipe data and improve query performance.

## Rollback Procedure
```bash
psql -h localhost -U postgres -d meal_planner << EOF
BEGIN;
ALTER TABLE auto_meal_plans DROP COLUMN IF EXISTS recipe_json;
DROP INDEX IF EXISTS idx_auto_meal_plans_recipe_json;
COMMIT;
EOF
```

## Risk Factors
- Minimal risk: Only adds column, no data changes
- Can be rolled back anytime

## Testing
- [ ] Tested in staging
- [ ] Rollback tested in staging
- [ ] Data consistency verified
```

---

## Part 5: Monitoring and Alerting

### 5.1 Post-Rollback Verification

```bash
# Check application health
curl -v http://localhost:8080/health

# Monitor logs for errors
docker-compose logs --tail=100 meal-planner-gleam | grep -i error

# Verify database integrity
psql -h localhost -U postgres -d meal_planner -c "
SELECT
    tablename,
    ROUND(pg_total_relation_size(schemaname||'.'||tablename) / 1024 / 1024) AS size_mb
FROM pg_tables
WHERE schemaname = 'public'
ORDER BY pg_total_relation_size(schemaname||'.'||tablename) DESC
LIMIT 10;
"

# Check migration history
psql -h localhost -U postgres -d meal_planner -c "SELECT version, success, installed_on FROM schema_migrations ORDER BY installed_on DESC LIMIT 20;"

# Verify key tables have data
psql -h localhost -U postgres -d meal_planner -c "
SELECT 'food_logs' as table_name, COUNT(*) as rows FROM food_logs
UNION ALL
SELECT 'meals', COUNT(*) FROM meals
UNION ALL
SELECT 'auto_meal_plans', COUNT(*) FROM auto_meal_plans
UNION ALL
SELECT 'meal_selections', COUNT(*) FROM meal_selections;
"
```

### 5.2 Alerting Setup

Create monitoring for rollback scenarios:

```bash
# File: scripts/monitor-rollback.sh
#!/bin/bash

# Alert thresholds
MAX_ERROR_RATE=5  # 5% errors
MIN_RESPONSE_TIME=5000  # 5 seconds

# Check error rates
ERROR_COUNT=$(docker-compose logs meal-planner-gleam | grep -i error | wc -l)
TOTAL_REQUESTS=$(docker-compose logs meal-planner-gleam | grep -i request | wc -l)

if [ $TOTAL_REQUESTS -gt 0 ]; then
    ERROR_RATE=$((ERROR_COUNT * 100 / TOTAL_REQUESTS))
    if [ $ERROR_RATE -gt $MAX_ERROR_RATE ]; then
        echo "ALERT: High error rate detected: ${ERROR_RATE}%"
        # Trigger rollback automation
    fi
fi

# Check response time
RESPONSE_TIME=$(curl -o /dev/null -s -w '%{time_total}' http://localhost:8080/health)
if (( $(echo "$RESPONSE_TIME > ${MIN_RESPONSE_TIME}" | bc -l) )); then
    echo "ALERT: Slow response time: ${RESPONSE_TIME}ms"
fi
```

---

## Part 6: Emergency Contacts and Escalation

### Rollback Decision Tree

```
Is there data corruption?
├─ YES → Use Point-in-Time Recovery or Emergency Reset
└─ NO → Check severity...

Is application code broken?
├─ YES → Revert commit or use feature flags
└─ NO → Check if users affected...

Are users experiencing issues?
├─ YES → Proceed with rollback
└─ NO → Monitor and investigate

Ready to rollback?
├─ Backup database? → YES: Continue
├─ Stop app? → YES: Continue
├─ Execute rollback? → YES: Continue
└─ Verify? → Test all systems
```

### Communication Template

```
SUBJECT: System Rollback in Progress

We have detected an issue with the recent deployment and are executing a
controlled rollback to the previous stable version.

Timeline:
- [TIME]: Issue detected
- [TIME]: Rollback initiated
- [TIME]: System restored
- [TIME]: Verification complete
- [TIME]: Service restored

During this time, the meal planner may be unavailable or show inconsistent data.

We apologize for any inconvenience. Thank you for your patience.

Questions? Contact: [SUPPORT EMAIL]
```

---

## Part 7: Lessons Learned Documentation

After every rollback, document:

1. **What Went Wrong**
   - Root cause
   - Detection timeline
   - Impact assessment

2. **What Worked**
   - Which rollback procedures were effective
   - Communication that resonated
   - Team coordination successes

3. **What To Improve**
   - Prevention strategies for future
   - Monitoring enhancements needed
   - Process improvements

4. **Action Items**
   - [ ] Add additional monitoring
   - [ ] Improve testing procedures
   - [ ] Update documentation
   - [ ] Schedule post-mortem with team

---

## Quick Reference Commands

```bash
# Backup before anything else
pg_dump -h localhost -U postgres -d meal_planner -F custom -f backup_$(date +%s).dump

# Stop app
docker-compose stop meal-planner-gleam

# Connect to database
psql -h localhost -U postgres -d meal_planner

# Verify current migrations
SELECT version FROM schema_migrations ORDER BY version DESC;

# Remove migration
DELETE FROM schema_migrations WHERE version = XX;

# Rollback code
git reset --hard v1.2.0

# Restart app
docker-compose up -d meal-planner-gleam

# Check health
curl http://localhost:8080/health
```

---

## Additional Resources

- [PostgreSQL WAL and Recovery](https://www.postgresql.org/docs/current/wal-intro.html)
- [Docker Compose Best Practices](https://docs.docker.com/compose/production/)
- [Git Revert vs Reset](https://git-scm.com/docs/git-revert)
- [Feature Flags Best Practices](https://martinfowler.com/articles/feature-toggles.html)

---

**Document Version**: 1.0
**Last Updated**: 2025-12-12
**Maintained By**: Development Team
