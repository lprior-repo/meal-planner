# Mealie PostgreSQL Database Setup

## Database Configuration

Mealie has been configured to use PostgreSQL instead of the default SQLite.

### Database Details

- **Database Name**: `mealie`
- **User**: `postgres` (local development)
- **Host**: `localhost`
- **Port**: `5432`
- **Engine**: PostgreSQL 18.1

### Environment Configuration

The `.env` file in the `mealie-app/` directory contains the database configuration:

```bash
DB_ENGINE=postgres
POSTGRES_USER=postgres
POSTGRES_PASSWORD=
POSTGRES_SERVER=localhost
POSTGRES_PORT=5432
POSTGRES_DB=mealie
```

### Database Creation

The `mealie` database has been created in the PostgreSQL instance:

```sql
CREATE DATABASE mealie;
```

### Connection Testing

Verify the connection:

```bash
psql -U postgres -h localhost -d mealie -c "SELECT version();"
```

### Separation from Gleam Backend

As per the integration architecture:
- **Mealie**: Uses the `mealie` database
- **Gleam backend**: Uses the `meal_planner` database
- Both share the same PostgreSQL instance on localhost:5432
- Clean database-level separation ensures no table conflicts

### Running Migrations

When Mealie starts for the first time, it will automatically run Alembic migrations to create its schema:

```bash
# Migrations are located at:
mealie/alembic/versions/

# Alembic will create tables for:
# - Recipes
# - Users
# - Meal plans
# - Shopping lists
# - Categories, tags, etc.
```

### Docker Setup

For production or easier development, use the Docker Compose setup (see `docker-compose.yml` in the root directory) which handles:
- PostgreSQL service
- Mealie service with correct Python version (3.12)
- Automatic database initialization

### Troubleshooting

**Connection refused:**
- Ensure PostgreSQL is running: `systemctl status postgresql`
- Check pg_hba.conf allows local connections

**Database doesn't exist:**
```bash
createdb -U postgres mealie
```

**Permission denied:**
```bash
# Grant permissions if needed
psql -U postgres -c "GRANT ALL PRIVILEGES ON DATABASE mealie TO postgres;"
```

### Next Steps

1. ✅ Database created
2. ✅ Environment configured
3. ⏭️ Set up Docker Compose (see `meal-planner-smyv`)
4. ⏭️ Run Mealie and verify connection
5. ⏭️ Create Gleam API client for Mealie endpoints
