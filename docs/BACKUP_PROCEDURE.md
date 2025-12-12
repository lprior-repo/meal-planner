# Database Backup Procedure

This document describes the backup and recovery procedures for the Meal Planner production database.

## Overview

The Meal Planner application uses PostgreSQL with two separate databases:

- **meal_planner**: Contains the Gleam backend data (USDA foods, user meal logs, macros)
- **tandoor**: Contains Tandoor recipe management system data

Both databases are backed up together using the automated backup script.

## Quick Start

### Create a Backup

```bash
# Basic backup (compresses by default)
./scripts/backup-database.sh backup

# Backup with custom retention (60 days)
./scripts/backup-database.sh backup --retention-days 60

# Backup without compression
./scripts/backup-database.sh backup --no-compress
```

### List Available Backups

```bash
./scripts/backup-database.sh list
```

### Restore from Backup

```bash
./scripts/backup-database.sh restore <backup_file> <database_name>

# Example:
./scripts/backup-database.sh restore ./backups/2025-12-12/meal_planner_20251212_120000.sql.gz meal_planner
```

## Backup Script Details

### Location
`/home/lewis/src/meal-planner/scripts/backup-database.sh`

### Features

1. **Full Database Dumps**: Uses PostgreSQL `pg_dump` for complete database backups
2. **Compression**: Automatically gzip-compresses backups (90%+ size reduction)
3. **Date Versioning**: Backups organized by date with timestamps
4. **Retention Policy**: Automatically removes backups older than 30 days (configurable)
5. **Dual Database Support**: Backs up both meal_planner and tandoor databases
6. **Connection Management**: Properly handles PostgreSQL connections and authentication
7. **Restore Capability**: Includes restore functionality with safety checks

### Backup Directory Structure

```
backups/
├── 2025-12-10/
│   ├── meal_planner_20251210_090000.sql.gz
│   └── tandoor_20251210_090000.sql.gz
├── 2025-12-11/
│   ├── meal_planner_20251211_090000.sql.gz
│   └── tandoor_20251211_090000.sql.gz
└── 2025-12-12/
    ├── meal_planner_20251212_090000.sql.gz
    └── tandoor_20251212_090000.sql.gz
```

## Configuration

### Environment Variables

```bash
# PostgreSQL connection settings
POSTGRES_USER=postgres          # PostgreSQL username
POSTGRES_HOST=localhost         # PostgreSQL host
POSTGRES_PORT=5432             # PostgreSQL port

# Backup settings
BACKUP_DIR=./backups           # Where to store backups
RETENTION_DAYS=30              # Days to keep backups
COMPRESS=true                  # Compress backups (true/false)
```

### Command-Line Options

```bash
--retention-days N       # Override retention days
--no-compress            # Store backups uncompressed
--backup-dir PATH        # Custom backup directory
```

## Usage Examples

### Scheduled Daily Backups

Add to your crontab for automated daily backups at 2 AM:

```bash
# Edit crontab
crontab -e

# Add this line
0 2 * * * cd /home/lewis/src/meal-planner && ./scripts/backup-database.sh backup >> /var/log/meal-planner-backup.log 2>&1
```

### Manual Backup with Extended Retention

For important milestone backups, keep them longer:

```bash
./scripts/backup-database.sh backup --retention-days 180
```

### List All Backups

```bash
./scripts/backup-database.sh list

# Output:
# ℹ️  Available backups in ./backups:
#   meal_planner_20251210_090000.sql.gz      542MB  2025-12-10 09:00:00
#   tandoor_20251210_090000.sql.gz            12MB  2025-12-10 09:00:00
#   meal_planner_20251211_090000.sql.gz      545MB  2025-12-11 09:00:00
#   tandoor_20251211_090000.sql.gz            12MB  2025-12-11 09:00:00
#   meal_planner_20251212_090000.sql.gz      548MB  2025-12-12 09:00:00
#   tandoor_20251212_090000.sql.gz            13MB  2025-12-12 09:00:00
#
# Total backup size: 1.2GB
```

### Restore Database from Backup

Before restoring, stop the application:

```bash
# Stop the application
./run.sh stop

# Restore from backup (will prompt for confirmation)
./scripts/backup-database.sh restore ./backups/2025-12-12/meal_planner_20251212_090000.sql.gz meal_planner

# Start the application
./run.sh start

# Verify data integrity
curl http://localhost:8080/health
```

### Backup to External Location

For additional safety, copy backups to external storage:

```bash
#!/bin/bash
# backup-external.sh

BACKUP_SOURCE="/home/lewis/src/meal-planner/backups"
BACKUP_DEST="/mnt/external-backup/meal-planner"

# Create backup
./scripts/backup-database.sh backup

# Copy to external location
rsync -av --delete "$BACKUP_SOURCE/" "$BACKUP_DEST/"

# Verify
du -sh "$BACKUP_SOURCE" "$BACKUP_DEST"
```

## Recovery Procedures

### Complete Database Recovery

If the meal_planner database becomes corrupted:

```bash
# 1. Stop the application
./run.sh stop

# 2. Restore the backup
./scripts/backup-database.sh restore ./backups/2025-12-12/meal_planner_20251212_090000.sql.gz meal_planner

# 3. Start the application
./run.sh start

# 4. Verify the data
curl http://localhost:8080/health
```

### Restore Specific Database

To restore only the Tandoor database while preserving meal_planner:

```bash
./scripts/backup-database.sh restore ./backups/2025-12-12/tandoor_20251212_090000.sql.gz tandoor
```

### Point-in-Time Recovery

To restore from a specific point in time, find the backup from that date:

```bash
# List backups from a specific date
ls -lh ./backups/2025-12-10/

# Restore the backup you want
./scripts/backup-database.sh restore ./backups/2025-12-10/meal_planner_20251210_150000.sql.gz meal_planner
```

## Backup Verification

### Check Backup File Integrity

```bash
# Verify the backup can be decompressed
gzip -t ./backups/2025-12-12/meal_planner_20251212_090000.sql.gz

# If successful, no output is shown
# If corrupted, you'll get an error
```

### Test Restore to Temporary Database

For mission-critical backups, test restores before relying on them:

```bash
# Create a test database
createdb meal_planner_test

# Restore backup to test database
gunzip -c ./backups/2025-12-12/meal_planner_20251212_090000.sql.gz | \
  psql -U postgres -d meal_planner_test

# Verify the data
psql -U postgres -d meal_planner_test -c "SELECT COUNT(*) FROM foods;"

# Drop test database when done
dropdb meal_planner_test
```

## Backup Retention Policy

The script automatically manages backup retention:

- **Default**: 30 days
- **Configuration**: Set `RETENTION_DAYS` environment variable or use `--retention-days` flag
- **Cleanup**: Automatically runs after each backup
- **Manual Cleanup**: Run `./scripts/backup-database.sh cleanup` anytime

### Storage Estimates

Based on typical data:

- **meal_planner DB**: ~500-600 MB (compressed)
- **tandoor DB**: ~10-15 MB (compressed)
- **Per backup**: ~550 MB total
- **30-day retention**: ~16.5 GB total storage

Adjust `RETENTION_DAYS` if storage becomes constrained:

```bash
# Keep only 14 days of backups
./scripts/backup-database.sh cleanup --retention-days 14
```

## Monitoring and Alerting

### Check Backup Success

```bash
# View backup logs (if you added a cron job)
tail -f /var/log/meal-planner-backup.log

# Check recent backups
ls -lh ./backups/$(date +%Y-%m-%d)/
```

### Monitor Backup Directory Size

```bash
# Current backup directory size
du -sh ./backups/

# Monitor growth over time
du -sh ./backups/ | tee -a /var/log/backup-size.log
```

### Automated Alerts (Optional)

You can extend the script to send alerts on failure:

```bash
#!/bin/bash
# Add this to your backup script

if ! ./scripts/backup-database.sh backup; then
    # Send alert (email, webhook, etc.)
    curl -X POST https://alerts.example.com/backup-failed
    exit 1
fi
```

## Troubleshooting

### PostgreSQL Connection Issues

```bash
# Check if PostgreSQL is running
pg_isready

# Check connection parameters
echo "User: $POSTGRES_USER, Host: $POSTGRES_HOST, Port: $POSTGRES_PORT"

# Manual connection test
psql -h localhost -U postgres -d postgres -c "SELECT version();"
```

### Out of Disk Space

```bash
# Check disk usage
df -h ./backups/

# Clean old backups
./scripts/backup-database.sh cleanup --retention-days 7

# Or move backups to external storage
mv ./backups ./backups-archive
```

### Restore Permission Issues

Ensure the PostgreSQL user has permission to drop/create databases:

```bash
psql -U postgres -c "ALTER USER postgres WITH SUPERUSER;"
```

### Large Backup Files

If backups are taking too long, disable compression:

```bash
./scripts/backup-database.sh backup --no-compress
```

(Note: This will use significantly more disk space)

## Best Practices

1. **Regular Testing**: Test restore procedures quarterly
2. **Offsite Storage**: Keep copies on external/cloud storage
3. **Retention Policy**: Balance retention with storage costs
4. **Monitoring**: Set up alerts for backup failures
5. **Documentation**: Keep recovery procedures documented
6. **Access Control**: Restrict backup directory permissions
7. **Encryption**: Consider encrypting backups at rest
8. **Versioning**: Keep labeled backups for important milestones

## Additional Resources

- [PostgreSQL pg_dump Documentation](https://www.postgresql.org/docs/current/app-pgdump.html)
- [PostgreSQL Recovery Documentation](https://www.postgresql.org/docs/current/backup-dump.html)
- [Meal Planner Setup Guide](./SETUP.md)
