-- Existing nutrition tracking tables (from storage.gleam)
CREATE TABLE IF NOT EXISTS nutrition_state (
    date TEXT PRIMARY KEY,
    protein REAL NOT NULL,
    fat REAL NOT NULL,
    carbs REAL NOT NULL,
    calories REAL NOT NULL,
    synced_at TEXT NOT NULL DEFAULT ''
);

CREATE TABLE IF NOT EXISTS nutrition_goals (
    id INTEGER PRIMARY KEY CHECK (id = 1),
    daily_protein REAL NOT NULL,
    daily_fat REAL NOT NULL,
    daily_carbs REAL NOT NULL,
    daily_calories REAL NOT NULL
);
