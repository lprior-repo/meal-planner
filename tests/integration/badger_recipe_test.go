package integration

import (
	"encoding/json"
	"reflect"
	"testing"

	"github.com/dgraph-io/badger/v4"
)

// Test BadgerDB recipe storage integration
func TestBadgerRecipeStorage(t *testing.T) {
	// Create a temporary directory for testing
	tempDir := t.TempDir()
	
	// Initialize BadgerDB
	opts := badger.DefaultOptions(tempDir)
	opts.Logger = nil
	
	db, err := badger.Open(opts)
	if err != nil {
		t.Fatalf("Failed to open BadgerDB: %v", err)
	}
	defer db.Close()

	// Test recipe data
	testRecipes := []Recipe{
		{
			Name: "Test Recipe 1",
			Ingredients: []Ingredient{
				{Name: "ingredient1", Quantity: "1 cup"},
				{Name: "ingredient2", Quantity: "2 tbsp"},
			},
			Instructions: []string{"Step 1", "Step 2", "Step 3"},
		},
		{
			Name: "Test Recipe 2", 
			Ingredients: []Ingredient{
				{Name: "ingredient3", Quantity: "500g"},
			},
			Instructions: []string{"Step A", "Step B"},
		},
	}

	// Test storing recipes
	for i, recipe := range testRecipes {
		// Create stored recipe with ID
		type StoredRecipe struct {
			ID           int          `json:"id"`
			Name         string       `json:"name"`
			Ingredients  []Ingredient `json:"ingredients"`
			Instructions []string     `json:"instructions"`
		}

		storedRecipe := StoredRecipe{
			ID:           i + 1,
			Name:         recipe.Name,
			Ingredients:  recipe.Ingredients,
			Instructions: recipe.Instructions,
		}

		data, err := json.Marshal(storedRecipe)
		if err != nil {
			t.Fatalf("Failed to marshal recipe: %v", err)
		}

		key := "recipe:" + string(rune(i+1+'0'))
		
		err = db.Update(func(txn *badger.Txn) error {
			return txn.Set([]byte(key), data)
		})
		if err != nil {
			t.Fatalf("Failed to store recipe: %v", err)
		}
	}

	// Test retrieving recipes
	var retrievedRecipes []Recipe
	err = db.View(func(txn *badger.Txn) error {
		opts := badger.DefaultIteratorOptions
		it := txn.NewIterator(opts)
		defer it.Close()

		prefix := []byte("recipe:")
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
					return err
				}

				recipe := Recipe{
					Name:         storedRecipe.Name,
					Ingredients:  storedRecipe.Ingredients,
					Instructions: storedRecipe.Instructions,
				}

				retrievedRecipes = append(retrievedRecipes, recipe)
				return nil
			})
			
			if err != nil {
				return err
			}
		}
		return nil
	})
	if err != nil {
		t.Fatalf("Failed to retrieve recipes: %v", err)
	}

	// Verify we retrieved the correct number of recipes
	if len(retrievedRecipes) != len(testRecipes) {
		t.Errorf("Expected %d recipes, got %d", len(testRecipes), len(retrievedRecipes))
	}

	// Verify recipe data (order might be different, so check by name)
	recipeMap := make(map[string]Recipe)
	for _, recipe := range retrievedRecipes {
		recipeMap[recipe.Name] = recipe
	}

	for _, originalRecipe := range testRecipes {
		retrievedRecipe, exists := recipeMap[originalRecipe.Name]
		if !exists {
			t.Errorf("Recipe %s not found in retrieved recipes", originalRecipe.Name)
			continue
		}

		if !reflect.DeepEqual(originalRecipe, retrievedRecipe) {
			t.Errorf("Recipe %s data mismatch.\nExpected: %+v\nGot: %+v", 
				originalRecipe.Name, originalRecipe, retrievedRecipe)
		}
	}
}

// Test counter functionality
func TestBadgerCounter(t *testing.T) {
	// Create a temporary directory for testing
	tempDir := t.TempDir()
	
	// Initialize BadgerDB
	opts := badger.DefaultOptions(tempDir)
	opts.Logger = nil
	
	db, err := badger.Open(opts)
	if err != nil {
		t.Fatalf("Failed to open BadgerDB: %v", err)
	}
	defer db.Close()

	counterKey := "recipe_counter"
	
	// Test initial counter (should not exist)
	var counter int
	err = db.View(func(txn *badger.Txn) error {
		_, err := txn.Get([]byte(counterKey))
		if err == badger.ErrKeyNotFound {
			counter = 0
			return nil
		}
		return err
	})
	if err != nil {
		t.Fatalf("Failed to check initial counter: %v", err)
	}
	
	if counter != 0 {
		t.Errorf("Expected initial counter to be 0, got %d", counter)
	}

	// Test setting and retrieving counter
	expectedCounter := 5
	err = db.Update(func(txn *badger.Txn) error {
		return txn.Set([]byte(counterKey), []byte("5"))
	})
	if err != nil {
		t.Fatalf("Failed to set counter: %v", err)
	}

	// Retrieve counter
	err = db.View(func(txn *badger.Txn) error {
		item, err := txn.Get([]byte(counterKey))
		if err != nil {
			return err
		}
		
		return item.Value(func(val []byte) error {
			counter = int(val[0] - '0') // Simple conversion for single digit
			return nil
		})
	})
	if err != nil {
		t.Fatalf("Failed to get counter: %v", err)
	}
	
	if counter != expectedCounter {
		t.Errorf("Expected counter to be %d, got %d", expectedCounter, counter)
	}
}