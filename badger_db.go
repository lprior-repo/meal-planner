package main

import (
	"encoding/json"
	"fmt"
	"os"
	"strconv"

	"github.com/dgraph-io/badger/v4"
)

const (
	BadgerDBPath = "badger_data"
	RecipePrefix = "recipe:"
	CounterKey   = "recipe_counter"
)

type BadgerDatabase struct {
	db *badger.DB
}

func InitBadgerDatabase() (*BadgerDatabase, error) {
	opts := badger.DefaultOptions(BadgerDBPath)
	opts.Logger = nil // Disable logging for cleaner output
	
	db, err := badger.Open(opts)
	if err != nil {
		return nil, fmt.Errorf("failed to open BadgerDB: %w", err)
	}

	return &BadgerDatabase{db: db}, nil
}

func (bdb *BadgerDatabase) Close() error {
	return bdb.db.Close()
}

func (bdb *BadgerDatabase) getNextRecipeID() (int, error) {
	var counter int
	err := bdb.db.View(func(txn *badger.Txn) error {
		item, err := txn.Get([]byte(CounterKey))
		if err != nil {
			if err == badger.ErrKeyNotFound {
				counter = 0
				return nil
			}
			return err
		}
		
		return item.Value(func(val []byte) error {
			counter, err = strconv.Atoi(string(val))
			return err
		})
	})
	
	if err != nil {
		return 0, err
	}
	
	counter++
	
	// Update counter
	err = bdb.db.Update(func(txn *badger.Txn) error {
		return txn.Set([]byte(CounterKey), []byte(strconv.Itoa(counter)))
	})
	
	return counter, err
}

func (bdb *BadgerDatabase) InsertRecipe(recipe Recipe) error {
	recipeID, err := bdb.getNextRecipeID()
	if err != nil {
		return fmt.Errorf("failed to get next recipe ID: %w", err)
	}

	// Create a recipe with ID for storage
	type StoredRecipe struct {
		ID           int          `json:"id"`
		Name         string       `json:"name"`
		Ingredients  []Ingredient `json:"ingredients"`
		Instructions []string     `json:"instructions"`
	}

	storedRecipe := StoredRecipe{
		ID:           recipeID,
		Name:         recipe.Name,
		Ingredients:  recipe.Ingredients,
		Instructions: recipe.Instructions,
	}

	data, err := json.Marshal(storedRecipe)
	if err != nil {
		return fmt.Errorf("failed to marshal recipe: %w", err)
	}

	key := RecipePrefix + strconv.Itoa(recipeID)
	
	return bdb.db.Update(func(txn *badger.Txn) error {
		return txn.Set([]byte(key), data)
	})
}

func (bdb *BadgerDatabase) GetAllRecipes() ([]Recipe, error) {
	var recipes []Recipe

	err := bdb.db.View(func(txn *badger.Txn) error {
		opts := badger.DefaultIteratorOptions
		opts.PrefetchSize = 10
		it := txn.NewIterator(opts)
		defer it.Close()

		prefix := []byte(RecipePrefix)
		for it.Seek(prefix); it.ValidForPrefix(prefix); it.Next() {
			item := it.Item()
			
			err := item.Value(func(val []byte) error {
				type StoredRecipe struct {
					ID           int          `json:"id"`
					Name         string       `json:"name"`
					Ingredients  []Ingredient `json:"ingredients"`
					Instructions []string     `json:"instructions"`
				}

				var storedRecipe StoredRecipe
				if err := json.Unmarshal(val, &storedRecipe); err != nil {
					return fmt.Errorf("failed to unmarshal recipe: %w", err)
				}

				recipe := Recipe{
					Name:         storedRecipe.Name,
					Ingredients:  storedRecipe.Ingredients,
					Instructions: storedRecipe.Instructions,
				}

				recipes = append(recipes, recipe)
				return nil
			})
			
			if err != nil {
				return err
			}
		}
		return nil
	})

	return recipes, err
}

func (bdb *BadgerDatabase) RecipeCount() (int, error) {
	count := 0

	err := bdb.db.View(func(txn *badger.Txn) error {
		opts := badger.DefaultIteratorOptions
		opts.PrefetchValues = false // We only need keys for counting
		it := txn.NewIterator(opts)
		defer it.Close()

		prefix := []byte(RecipePrefix)
		for it.Seek(prefix); it.ValidForPrefix(prefix); it.Next() {
			count++
		}
		return nil
	})

	return count, err
}

func BadgerDatabaseExists() bool {
	_, err := os.Stat(BadgerDBPath)
	return !os.IsNotExist(err)
}

func MigrateYAMLToBadger(recipesDir string) error {
	bdb, err := InitBadgerDatabase()
	if err != nil {
		return fmt.Errorf("failed to initialize BadgerDB: %w", err)
	}
	defer bdb.Close()

	count, err := bdb.RecipeCount()
	if err != nil {
		return fmt.Errorf("failed to get recipe count: %w", err)
	}

	if count > 0 {
		fmt.Printf("BadgerDB already contains %d recipes. Skipping migration.\n", count)
		return nil
	}

	recipes, err := loadRecipes(recipesDir, "")
	if err != nil {
		return fmt.Errorf("failed to load YAML recipes: %w", err)
	}

	fmt.Printf("Migrating %d recipes to BadgerDB...\n", len(recipes))
	
	for _, recipe := range recipes {
		if err := bdb.InsertRecipe(recipe); err != nil {
			return fmt.Errorf("failed to insert recipe %s: %w", recipe.Name, err)
		}
	}

	fmt.Printf("Successfully migrated %d recipes to BadgerDB.\n", len(recipes))
	return nil
}

func MigrateSQLiteToBadger() error {
	// Initialize SQLite database
	sqliteDB, err := InitDatabase()
	if err != nil {
		return fmt.Errorf("failed to initialize SQLite database: %w", err)
	}
	defer sqliteDB.Close()

	// Initialize BadgerDB
	badgerDB, err := InitBadgerDatabase()
	if err != nil {
		return fmt.Errorf("failed to initialize BadgerDB: %w", err)
	}
	defer badgerDB.Close()

	// Check if BadgerDB already has data
	count, err := badgerDB.RecipeCount()
	if err != nil {
		return fmt.Errorf("failed to get BadgerDB recipe count: %w", err)
	}

	if count > 0 {
		fmt.Printf("BadgerDB already contains %d recipes. Skipping SQLite migration.\n", count)
		return nil
	}

	// Get all recipes from SQLite
	recipes, err := sqliteDB.GetAllRecipes()
	if err != nil {
		return fmt.Errorf("failed to get recipes from SQLite: %w", err)
	}

	if len(recipes) == 0 {
		fmt.Println("No recipes found in SQLite database.")
		return nil
	}

	fmt.Printf("Migrating %d recipes from SQLite to BadgerDB...\n", len(recipes))
	
	for _, recipe := range recipes {
		if err := badgerDB.InsertRecipe(recipe); err != nil {
			return fmt.Errorf("failed to insert recipe %s into BadgerDB: %w", recipe.Name, err)
		}
	}

	fmt.Printf("Successfully migrated %d recipes from SQLite to BadgerDB.\n", len(recipes))
	return nil
}