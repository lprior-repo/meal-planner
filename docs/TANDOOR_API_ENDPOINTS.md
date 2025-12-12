# Tandoor API Endpoint Mappings

**Last Updated:** 2025-12-12
**Purpose:** Document Tandoor API endpoints for Mealie → Tandoor migration

## Overview

Tandoor uses Django REST Framework with standard RESTful conventions. The API provides integrated documentation at `/api/` and OpenAPI schema at `/openapi/`.

## Authentication

- Token-based authentication (Django REST Framework)
- OAuth2 support available
- Documentation: [Tandoor Authentication](https://docs.tandoor.dev/features/authentication/)

## Core Recipe Endpoints

### Recipes
- **List recipes**: `GET /api/recipe/`
- **Create recipe**: `POST /api/recipe/`
- **Retrieve recipe**: `GET /api/recipe/{id}/`
- **Update recipe**: `PUT /api/recipe/{id}/` or `PATCH /api/recipe/{id}/`
- **Delete recipe**: `DELETE /api/recipe/{id}/`

### Expected Request/Response Format

Tandoor follows Django REST Framework patterns with ViewSets and Serializers. The exact schema should be retrieved from the live `/openapi/` endpoint.

## Migration Mapping: Mealie → Tandoor

| Mealie Endpoint | Tandoor Equivalent | Notes |
|-----------------|-------------------|-------|
| `/api/recipes` | `/api/recipe/` | Note singular vs plural |
| Recipe ID field | TBD | Verify ID field name |
| Recipe JSON structure | TBD | Requires live API inspection |

## Setup Complete

1. ✅ Read general Tandoor API documentation
2. ✅ Set up Tandoor container locally (running on localhost:8000)
3. ⏳ Access live `/api/` browser requires authentication (deferred to testing phase)
4. ⏳ Access `/openapi/` schema requires authentication (deferred to testing phase)
5. ⏳ Document complete endpoint mappings (next step: manual CRUD testing)
6. ⏳ Test CRUD operations manually (requires authentication setup)

## Sources

- [Tandoor API Discussion](https://github.com/TandoorRecipes/recipes/discussions/818)
- [Tandoor Documentation](https://docs.tandoor.dev/)
- [Contributing Guidelines](https://docs.tandoor.dev/contribute/guidelines/)
- [GitHub Repository](https://github.com/TandoorRecipes/recipes)
