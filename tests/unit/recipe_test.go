package unit

import (
	"os"
	"reflect"
	"testing"
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

// Mock functions to test
func readYAMLFile(filename string) ([]byte, error) {
	return os.ReadFile(filename)
}

func testReadYAMLFile(t *testing.T) {
	// Create a temporary test file
	content := []byte(`recipes:
  - name: Test Recipe
    ingredients:
      - name: ingredient1
        quantity: 1 cup
    instructions:
      - Step 1
      - Step 2
`)
	tmpFile, err := os.CreateTemp("", "test-*.yaml")
	if err != nil {
		t.Fatalf("Failed to create temp file: %v", err)
	}
	defer os.Remove(tmpFile.Name())

	if _, err := tmpFile.Write(content); err != nil {
		t.Fatalf("Failed to write to temp file: %v", err)
	}
	if err := tmpFile.Close(); err != nil {
		t.Fatalf("Failed to close temp file: %v", err)
	}

	// Test reading the YAML file
	data, err := readYAMLFile(tmpFile.Name())
	if err != nil {
		t.Fatalf("readYAMLFile() error = %v", err)
	}

	if !reflect.DeepEqual(data, content) {
		t.Errorf("readYAMLFile() = %v, want %v", data, content)
	}

	// Test reading a non-existent file
	_, err = readYAMLFile("nonexistent.yaml")
	if err == nil {
		t.Errorf("readYAMLFile() expected error for non-existent file")
	}
}

func TestRecipeFunctions(t *testing.T) {
	t.Run("TestReadYAMLFile", testReadYAMLFile)
}
