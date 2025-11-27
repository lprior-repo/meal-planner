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

// Macros represents nutritional macronutrients per serving
type Macros struct {
	Protein float64 `yaml:"protein" json:"protein"`
	Fat     float64 `yaml:"fat" json:"fat"`
	Carbs   float64 `yaml:"carbs" json:"carbs"`
}

// Calories calculates total calories from macros (4cal/g protein, 9cal/g fat, 4cal/g carbs)
func (m Macros) Calories() float64 {
	return (m.Protein * 4) + (m.Fat * 9) + (m.Carbs * 4)
}

type Recipe struct {
	Name              string       `yaml:"name"`
	Ingredients       []Ingredient `yaml:"ingredients"`
	Instructions      []string     `yaml:"instructions"`
	Macros            Macros       `yaml:"macros"`
	Servings          int          `yaml:"servings"`
	Category          string       `yaml:"category"`
	FodmapLevel       string       `yaml:"fodmap_level"`
	VerticalCompliant bool         `yaml:"vertical_compliant"`
}

// IsVerticalDietCompliant checks if recipe meets Vertical Diet requirements
func (r Recipe) IsVerticalDietCompliant() bool {
	// Must be explicitly marked compliant and have low FODMAP
	return r.VerticalCompliant && (r.FodmapLevel == "low" || r.FodmapLevel == "")
}

// MacrosPerServing returns macros adjusted for serving size (default 1 serving)
func (r Recipe) MacrosPerServing() Macros {
	if r.Servings <= 0 {
		return r.Macros
	}
	return r.Macros
}

// TotalMacros returns total macros for all servings
func (r Recipe) TotalMacros() Macros {
	servings := r.Servings
	if servings <= 0 {
		servings = 1
	}
	return Macros{
		Protein: r.Macros.Protein * float64(servings),
		Fat:     r.Macros.Fat * float64(servings),
		Carbs:   r.Macros.Carbs * float64(servings),
	}
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

func TestMacrosCalories(t *testing.T) {
	tests := []struct {
		name     string
		macros   Macros
		expected float64
	}{
		{
			name:     "standard macros",
			macros:   Macros{Protein: 30, Fat: 10, Carbs: 50},
			expected: 30*4 + 10*9 + 50*4, // 120 + 90 + 200 = 410
		},
		{
			name:     "zero macros",
			macros:   Macros{Protein: 0, Fat: 0, Carbs: 0},
			expected: 0,
		},
		{
			name:     "high protein",
			macros:   Macros{Protein: 50, Fat: 5, Carbs: 20},
			expected: 50*4 + 5*9 + 20*4, // 200 + 45 + 80 = 325
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			got := tt.macros.Calories()
			if got != tt.expected {
				t.Errorf("Macros.Calories() = %v, want %v", got, tt.expected)
			}
		})
	}
}

func TestRecipeIsVerticalDietCompliant(t *testing.T) {
	tests := []struct {
		name     string
		recipe   Recipe
		expected bool
	}{
		{
			name: "compliant with low fodmap",
			recipe: Recipe{
				Name:              "Grass-fed Steak",
				VerticalCompliant: true,
				FodmapLevel:       "low",
			},
			expected: true,
		},
		{
			name: "compliant with empty fodmap (defaults to compliant)",
			recipe: Recipe{
				Name:              "White Rice",
				VerticalCompliant: true,
				FodmapLevel:       "",
			},
			expected: true,
		},
		{
			name: "not marked compliant",
			recipe: Recipe{
				Name:              "Bean Burrito",
				VerticalCompliant: false,
				FodmapLevel:       "low",
			},
			expected: false,
		},
		{
			name: "high fodmap",
			recipe: Recipe{
				Name:              "Garlic Bread",
				VerticalCompliant: true,
				FodmapLevel:       "high",
			},
			expected: false,
		},
		{
			name: "medium fodmap",
			recipe: Recipe{
				Name:              "Some Dish",
				VerticalCompliant: true,
				FodmapLevel:       "medium",
			},
			expected: false,
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			got := tt.recipe.IsVerticalDietCompliant()
			if got != tt.expected {
				t.Errorf("Recipe.IsVerticalDietCompliant() = %v, want %v", got, tt.expected)
			}
		})
	}
}

func TestRecipeTotalMacros(t *testing.T) {
	tests := []struct {
		name     string
		recipe   Recipe
		expected Macros
	}{
		{
			name: "4 servings",
			recipe: Recipe{
				Macros:   Macros{Protein: 30, Fat: 10, Carbs: 50},
				Servings: 4,
			},
			expected: Macros{Protein: 120, Fat: 40, Carbs: 200},
		},
		{
			name: "1 serving",
			recipe: Recipe{
				Macros:   Macros{Protein: 25, Fat: 8, Carbs: 40},
				Servings: 1,
			},
			expected: Macros{Protein: 25, Fat: 8, Carbs: 40},
		},
		{
			name: "zero servings defaults to 1",
			recipe: Recipe{
				Macros:   Macros{Protein: 20, Fat: 5, Carbs: 30},
				Servings: 0,
			},
			expected: Macros{Protein: 20, Fat: 5, Carbs: 30},
		},
		{
			name: "negative servings defaults to 1",
			recipe: Recipe{
				Macros:   Macros{Protein: 15, Fat: 3, Carbs: 25},
				Servings: -1,
			},
			expected: Macros{Protein: 15, Fat: 3, Carbs: 25},
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			got := tt.recipe.TotalMacros()
			if got != tt.expected {
				t.Errorf("Recipe.TotalMacros() = %v, want %v", got, tt.expected)
			}
		})
	}
}
