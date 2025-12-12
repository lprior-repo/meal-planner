#!/bin/bash

# Meal Planner - Database Backup Script
# Backs up both meal_planner and tandoor databases using pg_dump
# Supports compressed backups, versioning, and retention policies

set -e

# Configuration
POSTGRES_USER="${POSTGRES_USER:-postgres}"
POSTGRES_HOST="${POSTGRES_HOST:-localhost}"
POSTGRES_PORT="${POSTGRES_PORT:-5432}"
APP_DB="meal_planner"
TANDOOR_DB="tandoor"
BACKUP_DIR="${BACKUP_DIR:-./backups}"
RETENTION_DAYS="${RETENTION_DAYS:-30}"
COMPRESS="${COMPRESS:-true}"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
DATE=$(date +%Y-%m-%d)

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Logging
log_info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

log_success() {
    echo -e "${GREEN}✓ $1${NC}"
}

log_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

log_error() {
    echo -e "${RED}❌ $1${NC}"
}

# Check if PostgreSQL is running
check_postgres() {
    log_info "Checking PostgreSQL connection..."
    if ! pg_isready -h $POSTGRES_HOST -p $POSTGRES_PORT -U $POSTGRES_USER -q 2>/dev/null; then
        log_error "PostgreSQL is not running or not accessible"
        exit 1
    fi
    log_success "PostgreSQL is accessible"
}

# Create backup directory
setup_backup_dir() {
    if [ ! -d "$BACKUP_DIR" ]; then
        log_info "Creating backup directory: $BACKUP_DIR"
        mkdir -p "$BACKUP_DIR"
    fi

    # Create dated subdirectory
    BACKUP_SUBDIR="$BACKUP_DIR/$DATE"
    if [ ! -d "$BACKUP_SUBDIR" ]; then
        mkdir -p "$BACKUP_SUBDIR"
    fi
}

# Backup single database
backup_database() {
    local db_name=$1
    local filename=$2

    log_info "Backing up database: $db_name"

    if [ "$COMPRESS" = "true" ]; then
        filename="${filename}.sql.gz"
        pg_dump \
            -h $POSTGRES_HOST \
            -p $POSTGRES_PORT \
            -U $POSTGRES_USER \
            -d $db_name \
            --verbose \
            2>&1 | gzip > "$BACKUP_SUBDIR/$filename"
    else
        filename="${filename}.sql"
        pg_dump \
            -h $POSTGRES_HOST \
            -p $POSTGRES_PORT \
            -U $POSTGRES_USER \
            -d $db_name \
            --verbose > "$BACKUP_SUBDIR/$filename" 2>&1
    fi

    local file_path="$BACKUP_SUBDIR/$filename"
    local file_size=$(du -h "$file_path" | cut -f1)

    log_success "Backed up $db_name ($file_size): $filename"
    echo "$file_path"
}

# Backup all databases
backup_all() {
    log_info "Starting full database backup..."

    local app_backup
    local tandoor_backup

    app_backup=$(backup_database "$APP_DB" "${APP_DB}_${TIMESTAMP}")
    tandoor_backup=$(backup_database "$TANDOOR_DB" "${TANDOOR_DB}_${TIMESTAMP}")

    log_success "All databases backed up successfully"
    echo ""
    echo "Backup files:"
    echo "  - App: $app_backup"
    echo "  - Tandoor: $tandoor_backup"
    echo ""
}

# Clean old backups based on retention policy
cleanup_old_backups() {
    log_info "Cleaning backups older than $RETENTION_DAYS days..."

    local deleted_count=0

    find "$BACKUP_DIR" -type f -mtime +$RETENTION_DAYS | while read -r file; do
        log_warning "Removing old backup: $(basename $file)"
        rm -f "$file"
        ((deleted_count++))
    done

    # Remove empty directories
    find "$BACKUP_DIR" -type d -empty -delete 2>/dev/null || true

    if [ $deleted_count -gt 0 ]; then
        log_success "Removed $deleted_count old backup file(s)"
    else
        log_info "No backups to remove"
    fi
}

# List available backups
list_backups() {
    log_info "Available backups in $BACKUP_DIR:"
    echo ""

    if [ ! -d "$BACKUP_DIR" ] || [ -z "$(find $BACKUP_DIR -type f 2>/dev/null)" ]; then
        log_warning "No backups found"
        return
    fi

    find "$BACKUP_DIR" -type f | sort -r | while read -r file; do
        local size=$(du -h "$file" | cut -f1)
        local mtime=$(stat -f "%Sm" -t "%Y-%m-%d %H:%M:%S" "$file" 2>/dev/null || stat -c "%y" "$file" 2>/dev/null | cut -d' ' -f1-2)
        printf "  %-50s %8s  %s\n" "$(basename $file)" "$size" "$mtime"
    done

    echo ""
    echo "Total backup size: $(du -sh $BACKUP_DIR | cut -f1)"
}

# Restore from backup
restore_from_backup() {
    local backup_file=$1
    local target_db=$2

    if [ -z "$backup_file" ] || [ -z "$target_db" ]; then
        log_error "Usage: restore <backup_file> <database_name>"
        exit 1
    fi

    if [ ! -f "$backup_file" ]; then
        log_error "Backup file not found: $backup_file"
        exit 1
    fi

    log_warning "This will restore database '$target_db' from: $backup_file"
    read -p "Are you sure? (type 'yes' to confirm): " confirm

    if [ "$confirm" != "yes" ]; then
        log_info "Restore cancelled"
        return
    fi

    log_info "Restoring database: $target_db"

    # Drop existing database connections
    psql -h $POSTGRES_HOST -p $POSTGRES_PORT -U $POSTGRES_USER -d postgres \
        -c "SELECT pg_terminate_backend(pg_stat_activity.pid) FROM pg_stat_activity WHERE pg_stat_activity.datname = '$target_db' AND pid <> pg_backend_pid();" 2>/dev/null || true

    # Drop and recreate database
    dropdb -h $POSTGRES_HOST -p $POSTGRES_PORT -U $POSTGRES_USER --if-exists $target_db
    createdb -h $POSTGRES_HOST -p $POSTGRES_PORT -U $POSTGRES_USER $target_db

    # Restore from backup
    if [[ "$backup_file" == *.gz ]]; then
        gunzip -c "$backup_file" | psql -h $POSTGRES_HOST -p $POSTGRES_PORT -U $POSTGRES_USER -d $target_db
    else
        psql -h $POSTGRES_HOST -p $POSTGRES_PORT -U $POSTGRES_USER -d $target_db < "$backup_file"
    fi

    log_success "Database restored successfully: $target_db"
}

# Show help
show_help() {
    cat << EOF
Meal Planner - Database Backup Script

Usage: ./backup-database.sh [command] [options]

Commands:
  backup      - Create backup of all databases (default)
  list        - List all available backups
  restore     - Restore database from backup
  cleanup     - Remove backups older than retention days
  help        - Show this help message

Options:
  --retention-days N   - Days to keep backups (default: 30)
  --no-compress        - Store backups uncompressed
  --backup-dir PATH    - Custom backup directory (default: ./backups)

Environment Variables:
  POSTGRES_USER        - PostgreSQL username (default: postgres)
  POSTGRES_HOST        - PostgreSQL host (default: localhost)
  POSTGRES_PORT        - PostgreSQL port (default: 5432)
  RETENTION_DAYS       - Days to keep backups (default: 30)
  COMPRESS             - Compress backups (default: true)

Examples:
  # Create backup
  ./backup-database.sh backup

  # Create backup with 60-day retention
  ./backup-database.sh backup --retention-days 60

  # List available backups
  ./backup-database.sh list

  # Restore specific backup
  ./backup-database.sh restore ./backups/2025-12-12/meal_planner_20251212_120000.sql.gz meal_planner

  # Clean old backups
  ./backup-database.sh cleanup --retention-days 30

EOF
}

# Parse command line arguments
parse_args() {
    local cmd=${1:-backup}
    shift || true

    while [[ $# -gt 0 ]]; do
        case $1 in
            --retention-days)
                RETENTION_DAYS=$2
                shift 2
                ;;
            --no-compress)
                COMPRESS=false
                shift
                ;;
            --backup-dir)
                BACKUP_DIR=$2
                shift 2
                ;;
            *)
                echo "Unknown option: $1"
                show_help
                exit 1
                ;;
        esac
    done

    echo "$cmd"
}

# Main execution
main() {
    local cmd=$(parse_args "$@")

    case "$cmd" in
        backup)
            check_postgres
            setup_backup_dir
            backup_all
            cleanup_old_backups
            ;;
        list)
            list_backups
            ;;
        restore)
            check_postgres
            # Get backup file and target database from remaining args
            local backup_file="${2:-}"
            local target_db="${3:-}"
            restore_from_backup "$backup_file" "$target_db"
            ;;
        cleanup)
            cleanup_old_backups
            ;;
        help)
            show_help
            ;;
        *)
            log_error "Unknown command: $cmd"
            show_help
            exit 1
            ;;
    esac
}

# Run main function with all arguments
main "$@"
