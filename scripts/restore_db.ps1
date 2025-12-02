# Restore meal_planner database from pg_dump
# Downloads from GitHub Release if not present locally

$DUMP_URL = "https://github.com/lprior-repo/meal-planner/releases/download/v1.0.0/meal_planner.dump"
$DUMP_FILE = "$PSScriptRoot\..\db_export\meal_planner.dump"
$DB_NAME = "meal_planner"

# Check if dump file exists locally
if (-not (Test-Path $DUMP_FILE)) {
    Write-Host "Downloading database dump from GitHub..."
    New-Item -ItemType Directory -Force -Path "$PSScriptRoot\..\db_export" | Out-Null
    Invoke-WebRequest -Uri $DUMP_URL -OutFile $DUMP_FILE
}

Write-Host "Creating database..."
$env:PGPASSWORD = "postgres"
& "C:\Program Files\PostgreSQL\17\bin\psql" -h localhost -U postgres -c "DROP DATABASE IF EXISTS $DB_NAME"
& "C:\Program Files\PostgreSQL\17\bin\psql" -h localhost -U postgres -c "CREATE DATABASE $DB_NAME"

Write-Host "Restoring database (this takes a few minutes)..."
& "C:\Program Files\PostgreSQL\17\bin\pg_restore" -h localhost -U postgres -d $DB_NAME -j 4 $DUMP_FILE

Write-Host "Done! Database restored."
& "C:\Program Files\PostgreSQL\17\bin\psql" -h localhost -U postgres -d $DB_NAME -c "SELECT 'Foods' as table_name, count(*) FROM foods UNION ALL SELECT 'Nutrients', count(*) FROM nutrients UNION ALL SELECT 'Food Nutrients', count(*) FROM food_nutrients"
