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
CREATE INDEX IF NOT EXISTS idx_recipes_simplified_tags ON recipes_simplified USING gin(to_tsvector('english', tags));

-- Note: Original data is not restored. This only recreates the schema.
-- To restore data, you would need to recover from a backup.
