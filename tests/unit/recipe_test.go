package unit

import (
	"os"
	"reflect"
	"strings"
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

// UserProfile represents user data for macro calculations
type UserProfile struct {
	Bodyweight    float64 `json:"bodyweight"`     // in pounds
	ActivityLevel string  `json:"activity_level"` // sedentary, moderate, active
	Goal          string  `json:"goal"`           // gain, maintain, lose
	MealsPerDay   int     `json:"meals_per_day"`  // typically 3-4
}

// DailyProteinTarget calculates protein target (0.8-1g per lb bodyweight)
// Returns higher end for active/gain, lower for sedentary/lose
func (u UserProfile) DailyProteinTarget() float64 {
	multiplier := 0.9 // default moderate
	if u.ActivityLevel == "active" || u.Goal == "gain" {
		multiplier = 1.0
	} else if u.ActivityLevel == "sedentary" || u.Goal == "lose" {
		multiplier = 0.8
	}
	return u.Bodyweight * multiplier
}

// DailyFatTarget calculates fat target (0.3g per lb bodyweight)
func (u UserProfile) DailyFatTarget() float64 {
	return u.Bodyweight * 0.3
}

// DailyCarbTarget calculates carb target based on remaining calories
// After protein (4cal/g) and fat (9cal/g), fill rest with carbs (4cal/g)
func (u UserProfile) DailyCarbTarget() float64 {
	totalCalories := u.DailyCalorieTarget()
	proteinCalories := u.DailyProteinTarget() * 4
	fatCalories := u.DailyFatTarget() * 9
	remainingCalories := totalCalories - proteinCalories - fatCalories
	if remainingCalories < 0 {
		remainingCalories = 0
	}
	return remainingCalories / 4
}

// DailyCalorieTarget estimates daily calorie needs
func (u UserProfile) DailyCalorieTarget() float64 {
	// Base: 15 cal/lb for moderate activity
	baseMultiplier := 15.0
	if u.ActivityLevel == "sedentary" {
		baseMultiplier = 12.0
	} else if u.ActivityLevel == "active" {
		baseMultiplier = 18.0
	}

	base := u.Bodyweight * baseMultiplier

	// Adjust for goal
	switch u.Goal {
	case "gain":
		return base * 1.15 // 15% surplus
	case "lose":
		return base * 0.85 // 15% deficit
	default:
		return base // maintain
	}
}

// DailyMacroTargets returns complete macro targets
func (u UserProfile) DailyMacroTargets() Macros {
	return Macros{
		Protein: u.DailyProteinTarget(),
		Fat:     u.DailyFatTarget(),
		Carbs:   u.DailyCarbTarget(),
	}
}

// MacrosPerMeal divides daily targets by meals per day
func (u UserProfile) MacrosPerMeal() Macros {
	meals := u.MealsPerDay
	if meals <= 0 {
		meals = 3
	}
	daily := u.DailyMacroTargets()
	return Macros{
		Protein: daily.Protein / float64(meals),
		Fat:     daily.Fat / float64(meals),
		Carbs:   daily.Carbs / float64(meals),
	}
}

func TestUserProfileDailyProteinTarget(t *testing.T) {
	tests := []struct {
		name     string
		profile  UserProfile
		expected float64
	}{
		{
			name:     "active gain - max protein",
			profile:  UserProfile{Bodyweight: 180, ActivityLevel: "active", Goal: "gain"},
			expected: 180.0, // 1.0 * 180
		},
		{
			name:     "sedentary lose - min protein",
			profile:  UserProfile{Bodyweight: 180, ActivityLevel: "sedentary", Goal: "lose"},
			expected: 144.0, // 0.8 * 180
		},
		{
			name:     "moderate maintain - mid protein",
			profile:  UserProfile{Bodyweight: 200, ActivityLevel: "moderate", Goal: "maintain"},
			expected: 180.0, // 0.9 * 200
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			got := tt.profile.DailyProteinTarget()
			if got != tt.expected {
				t.Errorf("DailyProteinTarget() = %v, want %v", got, tt.expected)
			}
		})
	}
}

func TestUserProfileDailyFatTarget(t *testing.T) {
	profile := UserProfile{Bodyweight: 180}
	expected := 54.0 // 0.3 * 180
	got := profile.DailyFatTarget()
	if got != expected {
		t.Errorf("DailyFatTarget() = %v, want %v", got, expected)
	}
}

func TestUserProfileDailyCalorieTarget(t *testing.T) {
	tests := []struct {
		name     string
		profile  UserProfile
		expected float64
	}{
		{
			name:     "moderate maintain",
			profile:  UserProfile{Bodyweight: 180, ActivityLevel: "moderate", Goal: "maintain"},
			expected: 2700.0, // 180 * 15
		},
		{
			name:     "active gain",
			profile:  UserProfile{Bodyweight: 180, ActivityLevel: "active", Goal: "gain"},
			expected: 3726.0, // 180 * 18 * 1.15
		},
		{
			name:     "sedentary lose",
			profile:  UserProfile{Bodyweight: 180, ActivityLevel: "sedentary", Goal: "lose"},
			expected: 1836.0, // 180 * 12 * 0.85
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			got := tt.profile.DailyCalorieTarget()
			// Use tolerance for floating point comparison
			diff := got - tt.expected
			if diff < 0 {
				diff = -diff
			}
			if diff > 0.01 {
				t.Errorf("DailyCalorieTarget() = %v, want %v", got, tt.expected)
			}
		})
	}
}

func TestUserProfileMacrosPerMeal(t *testing.T) {
	profile := UserProfile{
		Bodyweight:    180,
		ActivityLevel: "moderate",
		Goal:          "maintain",
		MealsPerDay:   4,
	}

	macros := profile.MacrosPerMeal()

	// Daily: Protein=162 (0.9*180), Fat=54 (0.3*180)
	// Calories: 2700, ProteinCal=648, FatCal=486, CarbCal=1566, Carbs=391.5
	// Per meal (4): Protein=40.5, Fat=13.5, Carbs=97.875

	expectedProtein := 40.5
	expectedFat := 13.5

	if macros.Protein != expectedProtein {
		t.Errorf("MacrosPerMeal().Protein = %v, want %v", macros.Protein, expectedProtein)
	}
	if macros.Fat != expectedFat {
		t.Errorf("MacrosPerMeal().Fat = %v, want %v", macros.Fat, expectedFat)
	}
}

// Meal represents a single meal with its recipe and portion info
type Meal struct {
	Recipe      Recipe  `json:"recipe"`
	PortionSize float64 `json:"portion_size"` // multiplier (1.0 = one serving)
}

// Macros returns the macros for this meal adjusted for portion size
func (m Meal) Macros() Macros {
	return Macros{
		Protein: m.Recipe.Macros.Protein * m.PortionSize,
		Fat:     m.Recipe.Macros.Fat * m.PortionSize,
		Carbs:   m.Recipe.Macros.Carbs * m.PortionSize,
	}
}

// DailyPlan represents meals for a single day
type DailyPlan struct {
	DayName string `json:"day_name"` // Monday, Tuesday, etc.
	Meals   []Meal `json:"meals"`
}

// TotalMacros calculates sum of all meal macros for the day
func (d DailyPlan) TotalMacros() Macros {
	total := Macros{}
	for _, meal := range d.Meals {
		m := meal.Macros()
		total.Protein += m.Protein
		total.Fat += m.Fat
		total.Carbs += m.Carbs
	}
	return total
}

// WeeklyMealPlan represents a full week of meal planning
type WeeklyMealPlan struct {
	Days         [7]DailyPlan `json:"days"`
	ShoppingList []Ingredient `json:"shopping_list"`
	UserProfile  UserProfile  `json:"user_profile"`
}

// TotalMacros calculates sum of all daily macros for the week
func (w WeeklyMealPlan) TotalMacros() Macros {
	total := Macros{}
	for _, day := range w.Days {
		m := day.TotalMacros()
		total.Protein += m.Protein
		total.Fat += m.Fat
		total.Carbs += m.Carbs
	}
	return total
}

// AverageDailyMacros returns average macros per day
func (w WeeklyMealPlan) AverageDailyMacros() Macros {
	total := w.TotalMacros()
	return Macros{
		Protein: total.Protein / 7,
		Fat:     total.Fat / 7,
		Carbs:   total.Carbs / 7,
	}
}

// GenerateShoppingList creates a consolidated shopping list from all meals
func (w *WeeklyMealPlan) GenerateShoppingList() {
	ingredientMap := make(map[string]Ingredient)
	for _, day := range w.Days {
		for _, meal := range day.Meals {
			for _, ing := range meal.Recipe.Ingredients {
				// Simple aggregation by name (quantities would need parsing for real use)
				if existing, ok := ingredientMap[ing.Name]; ok {
					existing.Quantity = existing.Quantity + ", " + ing.Quantity
					ingredientMap[ing.Name] = existing
				} else {
					ingredientMap[ing.Name] = ing
				}
			}
		}
	}

	w.ShoppingList = make([]Ingredient, 0, len(ingredientMap))
	for _, ing := range ingredientMap {
		w.ShoppingList = append(w.ShoppingList, ing)
	}
}

// IsWithinMacroTargets checks if average daily macros are within tolerance of targets
func (w WeeklyMealPlan) IsWithinMacroTargets(tolerance float64) bool {
	avg := w.AverageDailyMacros()
	targets := w.UserProfile.DailyMacroTargets()

	proteinDiff := (avg.Protein - targets.Protein) / targets.Protein
	fatDiff := (avg.Fat - targets.Fat) / targets.Fat
	carbsDiff := (avg.Carbs - targets.Carbs) / targets.Carbs

	// Make differences absolute
	if proteinDiff < 0 {
		proteinDiff = -proteinDiff
	}
	if fatDiff < 0 {
		fatDiff = -fatDiff
	}
	if carbsDiff < 0 {
		carbsDiff = -carbsDiff
	}

	return proteinDiff <= tolerance && fatDiff <= tolerance && carbsDiff <= tolerance
}

func TestMealMacros(t *testing.T) {
	meal := Meal{
		Recipe: Recipe{
			Macros: Macros{Protein: 30, Fat: 10, Carbs: 50},
		},
		PortionSize: 1.5,
	}

	expected := Macros{Protein: 45, Fat: 15, Carbs: 75}
	got := meal.Macros()

	if got != expected {
		t.Errorf("Meal.Macros() = %v, want %v", got, expected)
	}
}

func TestDailyPlanTotalMacros(t *testing.T) {
	day := DailyPlan{
		DayName: "Monday",
		Meals: []Meal{
			{Recipe: Recipe{Macros: Macros{Protein: 30, Fat: 10, Carbs: 50}}, PortionSize: 1.0},
			{Recipe: Recipe{Macros: Macros{Protein: 40, Fat: 15, Carbs: 60}}, PortionSize: 1.0},
			{Recipe: Recipe{Macros: Macros{Protein: 35, Fat: 12, Carbs: 55}}, PortionSize: 1.0},
		},
	}

	expected := Macros{Protein: 105, Fat: 37, Carbs: 165}
	got := day.TotalMacros()

	if got != expected {
		t.Errorf("DailyPlan.TotalMacros() = %v, want %v", got, expected)
	}
}

func TestWeeklyMealPlanTotalMacros(t *testing.T) {
	// Create a simple weekly plan with same macros each day
	dailyMacros := Macros{Protein: 100, Fat: 50, Carbs: 200}
	meal := Meal{
		Recipe:      Recipe{Macros: dailyMacros},
		PortionSize: 1.0,
	}
	day := DailyPlan{Meals: []Meal{meal}}

	plan := WeeklyMealPlan{}
	for i := 0; i < 7; i++ {
		plan.Days[i] = day
	}

	expected := Macros{Protein: 700, Fat: 350, Carbs: 1400}
	got := plan.TotalMacros()

	if got != expected {
		t.Errorf("WeeklyMealPlan.TotalMacros() = %v, want %v", got, expected)
	}
}

func TestWeeklyMealPlanAverageDailyMacros(t *testing.T) {
	dailyMacros := Macros{Protein: 140, Fat: 70, Carbs: 280}
	meal := Meal{
		Recipe:      Recipe{Macros: dailyMacros},
		PortionSize: 1.0,
	}
	day := DailyPlan{Meals: []Meal{meal}}

	plan := WeeklyMealPlan{}
	for i := 0; i < 7; i++ {
		plan.Days[i] = day
	}

	expected := Macros{Protein: 140, Fat: 70, Carbs: 280}
	got := plan.AverageDailyMacros()

	if got != expected {
		t.Errorf("WeeklyMealPlan.AverageDailyMacros() = %v, want %v", got, expected)
	}
}

func TestWeeklyMealPlanGenerateShoppingList(t *testing.T) {
	recipe1 := Recipe{
		Ingredients: []Ingredient{
			{Name: "beef", Quantity: "1 lb"},
			{Name: "rice", Quantity: "2 cups"},
		},
	}
	recipe2 := Recipe{
		Ingredients: []Ingredient{
			{Name: "beef", Quantity: "2 lb"},
			{Name: "spinach", Quantity: "1 bunch"},
		},
	}

	plan := WeeklyMealPlan{
		Days: [7]DailyPlan{
			{Meals: []Meal{{Recipe: recipe1, PortionSize: 1.0}}},
			{Meals: []Meal{{Recipe: recipe2, PortionSize: 1.0}}},
		},
	}

	plan.GenerateShoppingList()

	if len(plan.ShoppingList) != 3 {
		t.Errorf("Expected 3 unique ingredients, got %d", len(plan.ShoppingList))
	}

	// Check that beef was consolidated
	found := false
	for _, ing := range plan.ShoppingList {
		if ing.Name == "beef" {
			found = true
			if ing.Quantity != "1 lb, 2 lb" {
				t.Errorf("Expected beef quantity '1 lb, 2 lb', got '%s'", ing.Quantity)
			}
		}
	}
	if !found {
		t.Error("Expected to find beef in shopping list")
	}
}

func TestWeeklyMealPlanIsWithinMacroTargets(t *testing.T) {
	profile := UserProfile{
		Bodyweight:    180,
		ActivityLevel: "moderate",
		Goal:          "maintain",
		MealsPerDay:   3,
	}
	targets := profile.DailyMacroTargets()

	// Create a plan that matches targets exactly
	meal := Meal{
		Recipe:      Recipe{Macros: targets},
		PortionSize: 1.0,
	}
	day := DailyPlan{Meals: []Meal{meal}}

	plan := WeeklyMealPlan{UserProfile: profile}
	for i := 0; i < 7; i++ {
		plan.Days[i] = day
	}

	if !plan.IsWithinMacroTargets(0.05) {
		t.Error("Expected plan matching targets to be within 5% tolerance")
	}

	// Create a plan that's way off
	badMeal := Meal{
		Recipe:      Recipe{Macros: Macros{Protein: 10, Fat: 5, Carbs: 20}},
		PortionSize: 1.0,
	}
	badDay := DailyPlan{Meals: []Meal{badMeal}}
	badPlan := WeeklyMealPlan{UserProfile: profile}
	for i := 0; i < 7; i++ {
		badPlan.Days[i] = badDay
	}

	if badPlan.IsWithinMacroTargets(0.05) {
		t.Error("Expected plan far from targets to NOT be within 5% tolerance")
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

// HighFODMAPIngredients contains ingredients that are high in FODMAPs
// and should be avoided or limited on the Vertical Diet
var HighFODMAPIngredients = []string{
	"garlic",
	"onion",
	"beans",
	"chickpea",
	"lentil",
	"cauliflower",
	"broccoli",
	"asparagus",
	"mushroom",
	"apple",
	"pear",
	"mango",
	"watermelon",
	"wheat",
	"rye",
	"barley",
	"honey",
}

// FODMAPAnalysis represents the result of analyzing a recipe for FODMAP content
type FODMAPAnalysis struct {
	Recipe               string   // Recipe name
	HighFODMAPFound      []string // List of high-FODMAP ingredients found
	IsLowFODMAP          bool     // True if no high-FODMAP ingredients found
	CompliancePercentage float64  // 0-100, higher means more compliant
}

// AnalyzeRecipeFODMAP checks a recipe's ingredients against high-FODMAP list
func AnalyzeRecipeFODMAP(recipe Recipe) FODMAPAnalysis {
	analysis := FODMAPAnalysis{
		Recipe:      recipe.Name,
		IsLowFODMAP: true,
	}

	for _, ingredient := range recipe.Ingredients {
		ingredientLower := strings.ToLower(ingredient.Name)
		for _, fodmap := range HighFODMAPIngredients {
			if strings.Contains(ingredientLower, fodmap) {
				analysis.HighFODMAPFound = append(analysis.HighFODMAPFound, ingredient.Name)
				analysis.IsLowFODMAP = false
				break
			}
		}
	}

	// Calculate compliance percentage
	if len(recipe.Ingredients) == 0 {
		analysis.CompliancePercentage = 100.0
	} else {
		compliantCount := len(recipe.Ingredients) - len(analysis.HighFODMAPFound)
		analysis.CompliancePercentage = float64(compliantCount) / float64(len(recipe.Ingredients)) * 100
	}

	return analysis
}

func TestAnalyzeRecipeFODMAP(t *testing.T) {
	tests := []struct {
		name                 string
		recipe               Recipe
		expectedLowFODMAP    bool
		expectedHighFODMAPs  []string
		expectedCompliance   float64
	}{
		{
			name: "clean recipe - no high-FODMAP",
			recipe: Recipe{
				Name: "Simple Steak",
				Ingredients: []Ingredient{
					{Name: "beef ribeye", Quantity: "2 lbs"},
					{Name: "salt", Quantity: "1 tbsp"},
					{Name: "pepper", Quantity: "1 tsp"},
				},
			},
			expectedLowFODMAP:   true,
			expectedHighFODMAPs: nil,
			expectedCompliance:  100.0,
		},
		{
			name: "recipe with garlic",
			recipe: Recipe{
				Name: "Garlic Steak",
				Ingredients: []Ingredient{
					{Name: "beef ribeye", Quantity: "2 lbs"},
					{Name: "garlic cloves, minced", Quantity: "4"},
					{Name: "salt", Quantity: "1 tbsp"},
				},
			},
			expectedLowFODMAP:   false,
			expectedHighFODMAPs: []string{"garlic cloves, minced"},
			expectedCompliance:  66.66666666666667, // 2 out of 3 compliant
		},
		{
			name: "recipe with onion and beans",
			recipe: Recipe{
				Name: "Bean Stew",
				Ingredients: []Ingredient{
					{Name: "ground beef", Quantity: "2 lbs"},
					{Name: "onions, diced", Quantity: "2"},
					{Name: "canned beans", Quantity: "2 cans"},
					{Name: "salt", Quantity: "1 tbsp"},
				},
			},
			expectedLowFODMAP:   false,
			expectedHighFODMAPs: []string{"onions, diced", "canned beans"},
			expectedCompliance:  50.0, // 2 out of 4 compliant
		},
		{
			name: "recipe with broccoli",
			recipe: Recipe{
				Name: "Beef Stir-Fry",
				Ingredients: []Ingredient{
					{Name: "beef sirloin", Quantity: "2 lbs"},
					{Name: "broccoli florets", Quantity: "2 cups"},
					{Name: "soy sauce", Quantity: "1/4 cup"},
				},
			},
			expectedLowFODMAP:   false,
			expectedHighFODMAPs: []string{"broccoli florets"},
			expectedCompliance:  66.66666666666667,
		},
		{
			name: "recipe with honey",
			recipe: Recipe{
				Name: "Honey Glazed Ham",
				Ingredients: []Ingredient{
					{Name: "ham", Quantity: "6 lbs"},
					{Name: "honey", Quantity: "1/2 cup"},
					{Name: "brown sugar", Quantity: "1/4 cup"},
				},
			},
			expectedLowFODMAP:   false,
			expectedHighFODMAPs: []string{"honey"},
			expectedCompliance:  66.66666666666667,
		},
		{
			name: "recipe with apple",
			recipe: Recipe{
				Name: "Pork with Apples",
				Ingredients: []Ingredient{
					{Name: "pork chops", Quantity: "4"},
					{Name: "apples, sliced", Quantity: "2"},
					{Name: "cinnamon", Quantity: "1 tsp"},
					{Name: "salt", Quantity: "1 tbsp"},
				},
			},
			expectedLowFODMAP:   false,
			expectedHighFODMAPs: []string{"apples, sliced"},
			expectedCompliance:  75.0,
		},
		{
			name:                "empty recipe",
			recipe:              Recipe{Name: "Empty Recipe"},
			expectedLowFODMAP:   true,
			expectedHighFODMAPs: nil,
			expectedCompliance:  100.0,
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			analysis := AnalyzeRecipeFODMAP(tt.recipe)

			if analysis.IsLowFODMAP != tt.expectedLowFODMAP {
				t.Errorf("IsLowFODMAP = %v, want %v", analysis.IsLowFODMAP, tt.expectedLowFODMAP)
			}

			if len(analysis.HighFODMAPFound) != len(tt.expectedHighFODMAPs) {
				t.Errorf("HighFODMAPFound count = %d, want %d", len(analysis.HighFODMAPFound), len(tt.expectedHighFODMAPs))
			}

			for i, expected := range tt.expectedHighFODMAPs {
				if i < len(analysis.HighFODMAPFound) && analysis.HighFODMAPFound[i] != expected {
					t.Errorf("HighFODMAPFound[%d] = %s, want %s", i, analysis.HighFODMAPFound[i], expected)
				}
			}

			// Use tolerance for float comparison
			diff := analysis.CompliancePercentage - tt.expectedCompliance
			if diff < 0 {
				diff = -diff
			}
			if diff > 0.01 {
				t.Errorf("CompliancePercentage = %v, want %v", analysis.CompliancePercentage, tt.expectedCompliance)
			}
		})
	}
}
