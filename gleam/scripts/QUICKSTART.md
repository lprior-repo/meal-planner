# USDA Database Import - Quick Start Guide

## TL;DR - Just Run This

```bash
cd /home/lewis/src/meal-planner/gleam/scripts
./setup-usda-database.sh
```

Enter your PostgreSQL password when prompted. That's it!

## What Happens

1. Downloads ~2GB of USDA food data
2. Imports ~300k foods and 4.5M nutrient values
3. Takes 10-30 minutes depending on your system
4. Creates searchable food database

## Prerequisites

- PostgreSQL running
- 5GB free disk space
- Internet connection

## Common Issues

### "Cannot connect to database"
```bash
# Make sure PostgreSQL is running
sudo systemctl start postgresql

# Or on macOS:
brew services start postgresql
```

### "Permission denied"
```bash
# Make scripts executable
chmod +x *.sh
```

### Want to use different database?
```bash
# Set environment variables
export DB_NAME=my_database
export DB_USER=myuser
export DB_PASSWORD=mypass
./setup-usda-database.sh
```

## After Import

Verify it worked:
```bash
psql -d meal_planner -c "SELECT COUNT(*) FROM foods;"
# Should show ~300,000

psql -d meal_planner -c "SELECT description FROM foods LIMIT 5;"
# Should show food names
```

## Need Help?

Read the full [README.md](README.md) for detailed documentation.
