package main

import (
	"fmt"
	"os"
)

func InitializeApp() error {
	fmt.Println("🚀 Initializing Meal Planner application...")

	if err := verifyRecipesDirectory(); err != nil {
		return fmt.Errorf("recipes directory verification failed: %w", err)
	}

	if err := verifyDatabase(); err != nil {
		return fmt.Errorf("database verification failed: %w", err)
	}

	if err := verifyEnvironment(); err != nil {
		return fmt.Errorf("environment verification failed: %w", err)
	}

	fmt.Println("✅ Application initialization completed successfully!")
	return nil
}

func verifyRecipesDirectory() error {
	fmt.Println("📁 Verifying recipes directory...")
	
	recipesDir := "recipes"
	if _, err := os.Stat(recipesDir); os.IsNotExist(err) {
		return fmt.Errorf("recipes directory does not exist: %s", recipesDir)
	}

	recipeFiles, err := getRecipeFiles(recipesDir, "")
	if err != nil {
		return fmt.Errorf("failed to read recipe files: %w", err)
	}

	if len(recipeFiles) == 0 {
		return fmt.Errorf("no recipe files found in %s directory", recipesDir)
	}

	fmt.Printf("   Found %d recipe files\n", len(recipeFiles))
	return nil
}

func verifyDatabase() error {
	fmt.Println("🗄️  Verifying database...")

	// Check if BadgerDB exists first
	if !BadgerDatabaseExists() {
		fmt.Println("   BadgerDB not found, creating new database...")
		// If SQLite exists, migrate from it, otherwise migrate from YAML
		if DatabaseExists() {
			fmt.Println("   Found existing SQLite database, migrating to BadgerDB...")
			if err := MigrateSQLiteToBadger(); err != nil {
				return fmt.Errorf("failed to migrate from SQLite to BadgerDB: %w", err)
			}
		} else {
			if err := MigrateYAMLToBadger("recipes"); err != nil {
				return fmt.Errorf("failed to create and migrate BadgerDB: %w", err)
			}
		}
	} else {
		fmt.Println("   BadgerDB exists, checking contents...")
		bdb, err := InitBadgerDatabase()
		if err != nil {
			return fmt.Errorf("failed to connect to BadgerDB: %w", err)
		}
		defer bdb.Close()

		count, err := bdb.RecipeCount()
		if err != nil {
			return fmt.Errorf("failed to get recipe count: %w", err)
		}

		if count == 0 {
			fmt.Println("   BadgerDB is empty, migrating YAML recipes...")
			if err := MigrateYAMLToBadger("recipes"); err != nil {
				return fmt.Errorf("failed to migrate recipes: %w", err)
			}
		} else {
			fmt.Printf("   BadgerDB contains %d recipes\n", count)
		}
	}

	return nil
}

func verifyEnvironment() error {
	fmt.Println("🔧 Verifying environment configuration...")

	envFile := ".env"
	if _, err := os.Stat(envFile); os.IsNotExist(err) {
		fmt.Printf("   Warning: %s file not found - email functionality will be limited\n", envFile)
		return nil
	}

	if err := loadEnv(); err != nil {
		fmt.Printf("   Warning: Environment validation failed - %v\n", err)
		fmt.Println("   Email functionality will be disabled")
		return nil
	}

	fmt.Println("   Environment configuration is valid")
	return nil
}