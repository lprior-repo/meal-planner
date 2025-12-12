# Tandoor Setup - Completed

## Status: COMPLETE

Both tasks have been completed successfully:
- `meal-planner-lzeq`: Install Tandoor via Docker (port 8000) ✅
- `meal-planner-7am3`: Create Tandoor API token and test access ✅

## Setup Summary

### 1. Tandoor Installation via Docker

**Status:** Running on localhost:8000

The Tandoor container was started via the automated startup process:
```bash
./run.sh start
```

**Service Details:**
- Container: `meal-planner-tandoor`
- Image: `vabene1111/recipes:latest`
- Port: 8000 (http://localhost:8000)
- Database: PostgreSQL `tandoor` database
- URL: http://localhost:8000

**Verification:**
```bash
./run.sh status
# Output: ✅ Tandoor: Running (http://localhost:8000)
```

### 2. Tandoor API Token Creation

**Admin User Created:**
- Username: `admin`
- Email: `admin@example.com`
- Password: Set to `admin123` (for development only)
- Status: Superuser

**API Token Generated:**
```
Token: d76c5811bf89759fcd3f0a5eb7dbd9595c837eaf
```

**Token Location:**
- Database Table: `authtoken_token`
- User ID: 1 (admin user)
- Created: 2025-12-12 23:11:45.730235+00

### 3. API Access & Testing

**API Endpoints Available:**
- Base URL: `http://localhost:8000/api/`
- Recipe List: `GET /api/recipe/`
- Authentication: Token-based via `Authorization: Token <token>`

**Test Command:**
```bash
curl -H "Authorization: Token d76c5811bf89759fcd3f0a5eb7dbd9595c837eaf" \
     -H "Accept: application/json" \
     http://localhost:8000/api/recipe/
```

**Frontend Access:**
- Tandoor Web UI: http://localhost:8000
- Login with: username=`admin`, password=`admin123`

### 4. Database Verification

Token stored in PostgreSQL:
```sql
SELECT user_id, key, created FROM authtoken_token
WHERE user_id = (SELECT id FROM auth_user WHERE username='admin');

 user_id |                   key                    |            created
---------+------------------------------------------+-------------------------------
       1 | d76c5811bf89759fcd3f0a5eb7dbd9595c837eaf | 2025-12-12 23:11:45.730235+00
```

## Service Architecture

### Services Running
1. **PostgreSQL** (Port 5432)
   - Databases: `meal_planner` (app), `tandoor` (Tandoor)
   - Status: ✅ Running

2. **Tandoor** (Port 8000)
   - Status: ✅ Running
   - Backend: Django + Gunicorn (Unix socket)
   - Frontend: Vite (JavaScript/Vue3)
   - Webserver: Nginx (reverse proxy)

3. **Gleam API Server** (Port 8080)
   - Status: ✅ Running
   - Purpose: AI meal planning + macro calculations

## Ready for Integration

The Tandoor setup is now ready for:
- Recipe data synchronization from existing systems
- API integration with Gleam backend
- Testing meal planning algorithms
- Recipe management workflows

## Notes

- Tandoor defaults to development configuration (SECRET_KEY="changeme-insecure-key-for-dev")
- For production, update `TANDOOR_SECRET_KEY` in environment variables
- Two separate databases allow independent scaling and backup
- API token format: 40-character hex string (Django REST Framework standard)

## Next Steps

1. Document Tandoor API endpoints (see `TANDOOR_API_ENDPOINTS.md`)
2. Test recipe CRUD operations via API
3. Implement Gleam ↔ Tandoor integration
4. Create data migration utilities if needed
