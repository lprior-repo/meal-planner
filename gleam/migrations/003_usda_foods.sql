-- USDA FoodData Central schema
-- Source: https://fdc.nal.usda.gov/download-datasets/

-- Nutrient definitions (from nutrient.csv)
CREATE TABLE IF NOT EXISTS nutrients (
    id INTEGER PRIMARY KEY,
    name TEXT NOT NULL,
    unit_name TEXT NOT NULL,
    nutrient_nbr TEXT,
    rank INTEGER
);

-- Food items (from food.csv)
CREATE TABLE IF NOT EXISTS foods (
    fdc_id INTEGER PRIMARY KEY,
    data_type TEXT NOT NULL,
    description TEXT NOT NULL,
    food_category_id INTEGER,
    publication_date TEXT
);

-- Food nutrient values (from food_nutrient.csv)
-- Links foods to their nutrient amounts
CREATE TABLE IF NOT EXISTS food_nutrients (
    id INTEGER PRIMARY KEY,
    fdc_id INTEGER NOT NULL,
    nutrient_id INTEGER NOT NULL,
    amount REAL,
    FOREIGN KEY (fdc_id) REFERENCES foods(fdc_id),
    FOREIGN KEY (nutrient_id) REFERENCES nutrients(id)
);

-- Indexes for fast lookups
CREATE INDEX IF NOT EXISTS idx_foods_description ON foods(description);
CREATE INDEX IF NOT EXISTS idx_food_nutrients_fdc_id ON food_nutrients(fdc_id);
CREATE INDEX IF NOT EXISTS idx_food_nutrients_nutrient_id ON food_nutrients(nutrient_id);

-- Full-text search for food descriptions
CREATE VIRTUAL TABLE IF NOT EXISTS foods_fts USING fts5(
    description,
    content='foods',
    content_rowid='fdc_id'
);

-- Triggers to keep FTS in sync
CREATE TRIGGER IF NOT EXISTS foods_ai AFTER INSERT ON foods BEGIN
    INSERT INTO foods_fts(rowid, description) VALUES (new.fdc_id, new.description);
END;

CREATE TRIGGER IF NOT EXISTS foods_ad AFTER DELETE ON foods BEGIN
    INSERT INTO foods_fts(foods_fts, rowid, description) VALUES('delete', old.fdc_id, old.description);
END;

CREATE TRIGGER IF NOT EXISTS foods_au AFTER UPDATE ON foods BEGIN
    INSERT INTO foods_fts(foods_fts, rowid, description) VALUES('delete', old.fdc_id, old.description);
    INSERT INTO foods_fts(rowid, description) VALUES (new.fdc_id, new.description);
END;
