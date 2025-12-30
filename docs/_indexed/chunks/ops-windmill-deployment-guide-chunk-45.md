---
doc_id: ops/windmill/deployment-guide
chunk_id: ops/windmill/deployment-guide#chunk-45
heading_path: ["Windmill Deployment Guide", "Database Migrations"]
chunk_type: code
tokens: 200
summary: "Database Migrations"
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
