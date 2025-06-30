package main

import (
	"database/sql"
	"fmt"
	"os"

	_ "github.com/mattn/go-sqlite3"
)

const (
	DatabaseFile = "recipes.db"
	CreateRecipesTable = `
	CREATE TABLE IF NOT EXISTS recipes (
		id INTEGER PRIMARY KEY AUTOINCREMENT,
		name TEXT NOT NULL,
		created_at DATETIME DEFAULT CURRENT_TIMESTAMP
	);`
	
	CreateIngredientsTable = `
	CREATE TABLE IF NOT EXISTS ingredients (
		id INTEGER PRIMARY KEY AUTOINCREMENT,
		recipe_id INTEGER NOT NULL,
		name TEXT NOT NULL,
		quantity TEXT NOT NULL,
		FOREIGN KEY (recipe_id) REFERENCES recipes (id) ON DELETE CASCADE
	);`
	
	CreateInstructionsTable = `
	CREATE TABLE IF NOT EXISTS instructions (
		id INTEGER PRIMARY KEY AUTOINCREMENT,
		recipe_id INTEGER NOT NULL,
		step_number INTEGER NOT NULL,
		instruction TEXT NOT NULL,
		FOREIGN KEY (recipe_id) REFERENCES recipes (id) ON DELETE CASCADE
	);`
)

type Database struct {
	*sql.DB
}

func InitDatabase() (*Database, error) {
	db, err := sql.Open("sqlite3", DatabaseFile)
	if err != nil {
		return nil, fmt.Errorf("failed to open database: %w", err)
	}

	if err := db.Ping(); err != nil {
		return nil, fmt.Errorf("failed to ping database: %w", err)
	}

	database := &Database{db}
	if err := database.createTables(); err != nil {
		return nil, fmt.Errorf("failed to create tables: %w", err)
	}

	return database, nil
}

func (db *Database) createTables() error {
	tables := []string{CreateRecipesTable, CreateIngredientsTable, CreateInstructionsTable}
	
	for _, table := range tables {
		if _, err := db.Exec(table); err != nil {
			return fmt.Errorf("failed to create table: %w", err)
		}
	}
	
	return nil
}

func (db *Database) InsertRecipe(recipe Recipe) error {
	tx, err := db.Begin()
	if err != nil {
		return fmt.Errorf("failed to begin transaction: %w", err)
	}
	defer tx.Rollback()

	result, err := tx.Exec("INSERT INTO recipes (name) VALUES (?)", recipe.Name)
	if err != nil {
		return fmt.Errorf("failed to insert recipe: %w", err)
	}

	recipeID, err := result.LastInsertId()
	if err != nil {
		return fmt.Errorf("failed to get recipe ID: %w", err)
	}

	for _, ingredient := range recipe.Ingredients {
		_, err := tx.Exec("INSERT INTO ingredients (recipe_id, name, quantity) VALUES (?, ?, ?)",
			recipeID, ingredient.Name, ingredient.Quantity)
		if err != nil {
			return fmt.Errorf("failed to insert ingredient: %w", err)
		}
	}

	for i, instruction := range recipe.Instructions {
		_, err := tx.Exec("INSERT INTO instructions (recipe_id, step_number, instruction) VALUES (?, ?, ?)",
			recipeID, i+1, instruction)
		if err != nil {
			return fmt.Errorf("failed to insert instruction: %w", err)
		}
	}

	return tx.Commit()
}

func (db *Database) GetAllRecipes() ([]Recipe, error) {
	rows, err := db.Query(`
		SELECT DISTINCT r.id, r.name 
		FROM recipes r
		ORDER BY r.name
	`)
	if err != nil {
		return nil, fmt.Errorf("failed to query recipes: %w", err)
	}
	defer rows.Close()

	var recipes []Recipe
	for rows.Next() {
		var recipeID int
		var recipe Recipe
		
		if err := rows.Scan(&recipeID, &recipe.Name); err != nil {
			return nil, fmt.Errorf("failed to scan recipe: %w", err)
		}

		ingredients, err := db.getIngredients(recipeID)
		if err != nil {
			return nil, fmt.Errorf("failed to get ingredients for recipe %d: %w", recipeID, err)
		}
		recipe.Ingredients = ingredients

		instructions, err := db.getInstructions(recipeID)
		if err != nil {
			return nil, fmt.Errorf("failed to get instructions for recipe %d: %w", recipeID, err)
		}
		recipe.Instructions = instructions

		recipes = append(recipes, recipe)
	}

	return recipes, nil
}

func (db *Database) getIngredients(recipeID int) ([]Ingredient, error) {
	rows, err := db.Query("SELECT name, quantity FROM ingredients WHERE recipe_id = ? ORDER BY id", recipeID)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	var ingredients []Ingredient
	for rows.Next() {
		var ingredient Ingredient
		if err := rows.Scan(&ingredient.Name, &ingredient.Quantity); err != nil {
			return nil, err
		}
		ingredients = append(ingredients, ingredient)
	}

	return ingredients, nil
}

func (db *Database) getInstructions(recipeID int) ([]string, error) {
	rows, err := db.Query("SELECT instruction FROM instructions WHERE recipe_id = ? ORDER BY step_number", recipeID)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	var instructions []string
	for rows.Next() {
		var instruction string
		if err := rows.Scan(&instruction); err != nil {
			return nil, err
		}
		instructions = append(instructions, instruction)
	}

	return instructions, nil
}

func (db *Database) RecipeCount() (int, error) {
	var count int
	err := db.QueryRow("SELECT COUNT(*) FROM recipes").Scan(&count)
	return count, err
}

func DatabaseExists() bool {
	_, err := os.Stat(DatabaseFile)
	return !os.IsNotExist(err)
}

func MigrateYAMLRecipes(recipesDir string) error {
	db, err := InitDatabase()
	if err != nil {
		return fmt.Errorf("failed to initialize database: %w", err)
	}
	defer db.Close()

	count, err := db.RecipeCount()
	if err != nil {
		return fmt.Errorf("failed to get recipe count: %w", err)
	}

	if count > 0 {
		fmt.Printf("Database already contains %d recipes. Skipping migration.\n", count)
		return nil
	}

	recipes, err := loadRecipes(recipesDir, "")
	if err != nil {
		return fmt.Errorf("failed to load YAML recipes: %w", err)
	}

	fmt.Printf("Migrating %d recipes to database...\n", len(recipes))
	
	for _, recipe := range recipes {
		if err := db.InsertRecipe(recipe); err != nil {
			return fmt.Errorf("failed to insert recipe %s: %w", recipe.Name, err)
		}
	}

	fmt.Printf("Successfully migrated %d recipes to database.\n", len(recipes))
	return nil
}