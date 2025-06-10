package integration

import (
	"os"
	"path/filepath"
	"reflect"
	"strings"
	"testing"
	"gopkg.in/yaml.v3"
)

// Define the same structs as in main.go for testing
type Ingredient struct {
	Name     string `yaml:"name"`
	Quantity string `yaml:"quantity"`
}

type Recipe struct {
	Name         string       `yaml:"name"`
	Ingredients  []Ingredient `yaml:"ingredients"`
	Instructions []string     `yaml:"instructions"`
}

type RecipeCollection struct {
	Recipes []Recipe `yaml:"recipes"`
}

// Integration test for loading recipes from actual files
func TestLoadRecipes(t *testing.T) {
	// Setup test directory with test recipe files
	testDir := setupTestRecipeDir(t)
	defer os.RemoveAll(testDir)

	// Test loading recipes
	recipes, err := loadRecipes(testDir, "excluded.yaml")
	if err != nil {
		t.Fatalf("loadRecipes() error = %v", err)
	}

	// Verify we have the expected number of recipes
	if len(recipes) != 3 {
		t.Errorf("loadRecipes() returned %d recipes, want 3", len(recipes))
	}

	// Verify recipe names
	recipeNames := []string{}
	for _, recipe := range recipes {
		recipeNames = append(recipeNames, recipe.Name)
	}

	expectedNames := []string{"Test Recipe 1", "Test Recipe 2", "Test Recipe 3"}
	for _, name := range expectedNames {
		found := false
		for _, actual := range recipeNames {
			if name == actual {
				found = true
				break
			}
		}
		if !found {
			t.Errorf("loadRecipes() did not return recipe named %s", name)
		}
	}

	// Test that excluded file was indeed excluded
	for _, name := range recipeNames {
		if name == "Excluded Recipe" {
			t.Errorf("loadRecipes() should not have returned the excluded recipe")
		}
	}
}

// Helper function to create test recipe directory with test files
func setupTestRecipeDir(t *testing.T) string {
	t.Helper()

	// Create temp directory
	testDir, err := os.MkdirTemp("", "recipe-test-*")
	if err != nil {
		t.Fatalf("Failed to create temp directory: %v", err)
	}

	// Create test recipe files
	recipeFiles := map[string]RecipeCollection{
		"test1.yaml": {
			Recipes: []Recipe{
				{
					Name: "Test Recipe 1",
					Ingredients: []Ingredient{
						{Name: "ingredient1", Quantity: "1 cup"},
					},
					Instructions: []string{"Step 1", "Step 2"},
				},
			},
		},
		"test2.yaml": {
			Recipes: []Recipe{
				{
					Name: "Test Recipe 2",
					Ingredients: []Ingredient{
						{Name: "ingredient2", Quantity: "2 cups"},
					},
					Instructions: []string{"Step 1", "Step 2"},
				},
			},
		},
		"test3.yml": { // Test .yml extension too
			Recipes: []Recipe{
				{
					Name: "Test Recipe 3",
					Ingredients: []Ingredient{
						{Name: "ingredient3", Quantity: "3 cups"},
					},
					Instructions: []string{"Step 1", "Step 2"},
				},
			},
		},
		"excluded.yaml": {
			Recipes: []Recipe{
				{
					Name: "Excluded Recipe",
					Ingredients: []Ingredient{
						{Name: "excluded", Quantity: "1 cup"},
					},
					Instructions: []string{"This should be excluded"},
				},
			},
		},
		"notayaml.txt": {}, // This should be ignored
	}

	for filename, collection := range recipeFiles {
		createTestYamlFile(t, testDir, filename, collection)
	}

	return testDir
}

// Helper to create YAML test files
func createTestYamlFile(t *testing.T, dir, filename string, collection RecipeCollection) {
	t.Helper()

	data, err := yaml.Marshal(collection)
	if err != nil {
		t.Fatalf("Failed to marshal recipe collection: %v", err)
	}

	err = os.WriteFile(filepath.Join(dir, filename), data, 0644)
	if err != nil {
		t.Fatalf("Failed to write test file %s: %v", filename, err)
	}
}

// Test implementation of loadRecipes similar to main.go
func loadRecipes(dir, excludeFile string) ([]Recipe, error) {
	recipeFiles, err := getRecipeFiles(dir, excludeFile)
	if err != nil {
		return nil, err
	}
	var allRecipes []Recipe
	for _, file := range recipeFiles {
		data, err := os.ReadFile(file)
		if err != nil {
			continue
		}
		var recipeCollection RecipeCollection
		if err := yaml.Unmarshal(data, &recipeCollection); err != nil {
			continue
		}
		allRecipes = append(allRecipes, recipeCollection.Recipes...)
	}
	return allRecipes, nil
}

func getRecipeFiles(dir, excludeFile string) ([]string, error) {
	var yamlFiles []string
	entries, err := os.ReadDir(dir)
	if err != nil {
		return nil, err
	}
	for _, entry := range entries {
		if entry.IsDir() {
			continue
		}
		ext := strings.ToLower(filepath.Ext(entry.Name()))
		if (ext == ".yaml" || ext == ".yml") && entry.Name() != excludeFile {
			yamlFiles = append(yamlFiles, filepath.Join(dir, entry.Name()))
		}
	}
	return yamlFiles, nil
}