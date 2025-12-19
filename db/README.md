# Database Migrations

This directory contains database migration scripts for the meal-planner application.

## Directory Structure

```
db/
├── README.md                          # This file
├── migration_guide.md                 # Comprehensive migration documentation
├── migrations/
│   └── 001_initial_schema.sql        # Generation Engine & Scheduler schema
└── migrations/rollback/
    └── 001_rollback_initial_schema.sql # Rollback for migration 001
```

## Quick Start

### Run Migration

```bash
# Development/Staging
psql -U meal_planner_user -d meal_planner_db -f db/migrations/001_initial_schema.sql

# Production (with transaction)
psql -U meal_planner_user -d meal_planner_db <<EOF
BEGIN;
\i db/migrations/001_initial_schema.sql
-- Validate output, then:
COMMIT;
EOF
```

### Rollback Migration

```bash
psql -U meal_planner_user -d meal_planner_db -f db/migrations/rollback/001_rollback_initial_schema.sql
```

## Migration 001: Generation Engine & Scheduler

**Purpose:** Establish database schema for automated meal planning system.

**Tables Created:**
- `scheduled_jobs` - Job scheduling and configuration
- `job_executions` - Execution history and audit trail
- `scheduler_config` - Global scheduler settings (singleton)
- `recipe_rotation` - 30-day rotation enforcement for meal variety

**Functions Created:**
- `get_next_pending_job()` - Atomic job queue polling
- `start_job(job_id, trigger_type)` - Mark job as running
- `complete_job(job_id, execution_id, output)` - Mark job as completed
- `fail_job(job_id, execution_id, error_message)` - Mark job as failed with retry
- `calculate_next_schedule(frequency_type, config, from_time)` - Calculate next run time
- `update_recipe_rotation(user_id, recipe_id, meal_type, used_date)` - Track recipe usage
- `get_recipes_on_cooldown(user_id, meal_type, cooldown_days)` - Query cooldown recipes

**Prerequisites:**
- `users` table (from `schema/003_app_tables.sql`)
- `auto_meal_plans` table (from `schema/009_auto_meal_planner.sql`)
- `update_updated_at_column()` function (from `schema/009_auto_meal_planner.sql`)

**Status:** Ready for deployment

## Documentation

For detailed information, see:
- **Migration Guide:** `db/migration_guide.md`
  - Dependencies and migration order
  - Rollback procedures
  - Testing strategy
  - Production deployment checklist
  - Performance considerations
  - Troubleshooting

## Validation

Each migration includes automatic validation. Look for this output:

```
NOTICE:  ========================================
NOTICE:  Migration 001: Validation Report
NOTICE:  ========================================
NOTICE:  Tables created: 4 (expected: 4)
NOTICE:  Indexes created: 13 (expected: 13+)
NOTICE:  Functions created: 7 (expected: 7)
NOTICE:  ========================================
```

## Relationship to schema/ Directory

**Note:** The project has an existing `schema/` directory with migrations 001-030. This `db/migrations/` directory is for Phase 3 (Generation Engine & Scheduler) to keep the new infrastructure separate and explicit.

**Migration Chain:**
```
schema/001_schema_migrations.sql
    ↓
schema/003_app_tables.sql (users table)
    ↓
schema/009_auto_meal_planner.sql (auto_meal_plans, update_updated_at_column)
    ↓
schema/030_fatsecret_oauth.sql
    ↓
db/migrations/001_initial_schema.sql ← THIS MIGRATION
```

**Future Consolidation:** Consider moving all migrations to `db/migrations/` or renaming to align with existing `schema/` directory structure.

## Safety Best Practices

1. **Always Backup Before Migration**
   ```bash
   pg_dump -U meal_planner_user -d meal_planner_db \
     -F c -f backup_$(date +%Y%m%d_%H%M%S).dump
   ```

2. **Test on Staging First**
   - Run migration on staging database
   - Verify application compatibility
   - Run integration tests
   - Monitor performance

3. **Use Transactions in Production**
   ```sql
   BEGIN;
   \i db/migrations/001_initial_schema.sql
   -- Validate output
   COMMIT; -- or ROLLBACK if issues detected
   ```

4. **Monitor After Deployment**
   - Check application logs
   - Monitor query performance
   - Verify scheduled jobs execute correctly
   - Watch for retry loops or errors

## Support

For migration issues:
1. Check PostgreSQL logs: `/var/log/postgresql/`
2. Review `db/migration_guide.md` troubleshooting section
3. Verify prerequisites are met
4. Run validation queries manually

## Future Migrations

When adding new migrations:

1. **Naming Convention:** `NNN_description.sql`
   - Use sequential numbering (002, 003, etc.)
   - Use descriptive names (e.g., `002_add_shopping_list_tables.sql`)

2. **Include in Migration:**
   - Header comment with purpose, dependencies, date
   - CREATE statements with `IF NOT EXISTS`
   - Indexes for performance
   - Helper functions if needed
   - Validation block at end
   - Comments on tables/columns

3. **Create Rollback Script:** `rollback/NNN_rollback_description.sql`
   - Mirror structure of forward migration
   - Include data backup option
   - Validate rollback success

4. **Update Documentation:**
   - Add to `migration_guide.md`
   - Update `README.md` (this file)
   - Document any breaking changes

## Example: Creating a New Migration

```bash
# Create migration file
touch db/migrations/002_add_shopping_list_tables.sql

# Create rollback file
touch db/migrations/rollback/002_rollback_shopping_list_tables.sql

# Edit migration file
cat > db/migrations/002_add_shopping_list_tables.sql <<EOF
-- ============================================================================
-- Migration 002: Shopping List Tables
-- ============================================================================
--
-- Purpose: Add shopping list generation support
-- Dependencies: 001_initial_schema.sql
-- Date: 2025-12-19
--
-- ============================================================================

CREATE TABLE IF NOT EXISTS shopping_lists (
    id BIGSERIAL PRIMARY KEY,
    user_id TEXT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    meal_plan_id INTEGER REFERENCES auto_meal_plans(id) ON DELETE CASCADE,
    generated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    status TEXT NOT NULL DEFAULT 'pending' CHECK(status IN ('pending', 'purchased', 'archived'))
);

-- Indexes
CREATE INDEX IF NOT EXISTS idx_shopping_lists_user_id ON shopping_lists(user_id);
CREATE INDEX IF NOT EXISTS idx_shopping_lists_meal_plan ON shopping_lists(meal_plan_id);

-- Validation
DO $$
BEGIN
    RAISE NOTICE 'Migration 002 complete';
END;
$$ LANGUAGE plpgsql;
EOF

# Test on development database
psql -U dev_user -d dev_db -f db/migrations/002_add_shopping_list_tables.sql
```

## Schema Versioning

**Current Version:** 001 (Generation Engine & Scheduler)

**Previous Versions:** See `schema/` directory (001-030)

**Next Version:** 002 (TBD)

---

**Last Updated:** 2025-12-19
**Phase:** Phase 3 - Database Infrastructure
**Status:** Production Ready
