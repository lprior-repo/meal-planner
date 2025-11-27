package main

import (
	"bufio"
	"context"
	"encoding/json"
	"fmt"
	"io"
	"math/rand"
	"net/http"
	"os"
	"path/filepath"
	"strings"
	"time"

	"github.com/joho/godotenv"
	"gopkg.in/yaml.v3"
)

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

// ValidateBodyweight checks if bodyweight is within reasonable range
func ValidateBodyweight(weight float64) error {
	if weight < 80 {
		return fmt.Errorf("bodyweight too low: minimum 80 lbs")
	}
	if weight > 500 {
		return fmt.Errorf("bodyweight too high: maximum 500 lbs")
	}
	return nil
}

// ValidateActivityLevel checks if activity level is valid
func ValidateActivityLevel(level string) error {
	validLevels := []string{"sedentary", "moderate", "active"}
	for _, valid := range validLevels {
		if level == valid {
			return nil
		}
	}
	return fmt.Errorf("invalid activity level: must be sedentary, moderate, or active")
}

// ValidateGoal checks if goal is valid
func ValidateGoal(goal string) error {
	validGoals := []string{"gain", "maintain", "lose"}
	for _, valid := range validGoals {
		if goal == valid {
			return nil
		}
	}
	return fmt.Errorf("invalid goal: must be gain, maintain, or lose")
}

// ValidateMealsPerDay checks if meals per day is within range
func ValidateMealsPerDay(meals int) error {
	if meals < 2 {
		return fmt.Errorf("meals per day too low: minimum 2")
	}
	if meals > 6 {
		return fmt.Errorf("meals per day too high: maximum 6")
	}
	return nil
}

// CollectUserProfile interactively collects user profile data from stdin
func CollectUserProfile() (UserProfile, error) {
	reader := bufio.NewReader(os.Stdin)
	profile := UserProfile{}

	// Collect bodyweight
	for {
		fmt.Print("Enter your bodyweight (lbs): ")
		input, err := reader.ReadString('\n')
		if err != nil {
			return profile, fmt.Errorf("error reading bodyweight: %w", err)
		}
		input = strings.TrimSpace(input)
		var weight float64
		_, err = fmt.Sscanf(input, "%f", &weight)
		if err != nil {
			fmt.Println("Invalid number. Please enter a valid weight.")
			continue
		}
		if err := ValidateBodyweight(weight); err != nil {
			fmt.Println(err)
			continue
		}
		profile.Bodyweight = weight
		break
	}

	// Collect activity level
	for {
		fmt.Print("Activity level (sedentary/moderate/active): ")
		input, err := reader.ReadString('\n')
		if err != nil {
			return profile, fmt.Errorf("error reading activity level: %w", err)
		}
		input = strings.ToLower(strings.TrimSpace(input))
		if err := ValidateActivityLevel(input); err != nil {
			fmt.Println(err)
			continue
		}
		profile.ActivityLevel = input
		break
	}

	// Collect goal
	for {
		fmt.Print("Goal (gain/maintain/lose): ")
		input, err := reader.ReadString('\n')
		if err != nil {
			return profile, fmt.Errorf("error reading goal: %w", err)
		}
		input = strings.ToLower(strings.TrimSpace(input))
		if err := ValidateGoal(input); err != nil {
			fmt.Println(err)
			continue
		}
		profile.Goal = input
		break
	}

	// Collect meals per day
	for {
		fmt.Print("Meals per day (2-6): ")
		input, err := reader.ReadString('\n')
		if err != nil {
			return profile, fmt.Errorf("error reading meals per day: %w", err)
		}
		input = strings.TrimSpace(input)
		var meals int
		_, err = fmt.Sscanf(input, "%d", &meals)
		if err != nil {
			fmt.Println("Invalid number. Please enter a number between 2-6.")
			continue
		}
		if err := ValidateMealsPerDay(meals); err != nil {
			fmt.Println(err)
			continue
		}
		profile.MealsPerDay = meals
		break
	}

	return profile, nil
}

// PrintUserProfile displays user profile and calculated macro targets
func PrintUserProfile(profile UserProfile) {
	targets := profile.DailyMacroTargets()
	perMeal := profile.MacrosPerMeal()

	fmt.Println("\n==== YOUR VERTICAL DIET PROFILE ====")
	fmt.Printf("Bodyweight: %.0f lbs\n", profile.Bodyweight)
	fmt.Printf("Activity Level: %s\n", profile.ActivityLevel)
	fmt.Printf("Goal: %s\n", profile.Goal)
	fmt.Printf("Meals per Day: %d\n", profile.MealsPerDay)

	fmt.Println("\n--- Daily Macro Targets ---")
	fmt.Printf("Calories: %.0f\n", targets.Calories())
	fmt.Printf("Protein: %.0fg\n", targets.Protein)
	fmt.Printf("Fat: %.0fg\n", targets.Fat)
	fmt.Printf("Carbs: %.0fg\n", targets.Carbs)

	fmt.Println("\n--- Per Meal Targets ---")
	fmt.Printf("Protein: %.0fg\n", perMeal.Protein)
	fmt.Printf("Fat: %.0fg\n", perMeal.Fat)
	fmt.Printf("Carbs: %.0fg\n", perMeal.Carbs)
	fmt.Println("====================================")
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
	"apples",  // whole apples, not vinegar
	"pear",
	"mango",
	"watermelon",
	"wheat",
	"rye",
	"barley",
	"honey",
}

// LowFODMAPExceptions contains ingredients that contain high-FODMAP keywords
// but are actually low-FODMAP and should not be flagged
var LowFODMAPExceptions = []string{
	"apple cider vinegar",
	"garlic-infused oil",
	"green onion tops", // green part only is low-FODMAP
}

// FODMAPAnalysis represents the result of analyzing a recipe for FODMAP content
type FODMAPAnalysis struct {
	Recipe               string   `json:"recipe"`
	HighFODMAPFound      []string `json:"high_fodmap_found"`
	IsLowFODMAP          bool     `json:"is_low_fodmap"`
	CompliancePercentage float64  `json:"compliance_percentage"`
}

// isLowFODMAPException checks if an ingredient is a known low-FODMAP exception
func isLowFODMAPException(ingredientLower string) bool {
	for _, exception := range LowFODMAPExceptions {
		if strings.Contains(ingredientLower, exception) {
			return true
		}
	}
	return false
}

// AnalyzeRecipeFODMAP checks a recipe's ingredients against high-FODMAP list
func AnalyzeRecipeFODMAP(recipe Recipe) FODMAPAnalysis {
	analysis := FODMAPAnalysis{
		Recipe:      recipe.Name,
		IsLowFODMAP: true,
	}

	for _, ingredient := range recipe.Ingredients {
		ingredientLower := strings.ToLower(ingredient.Name)

		// Skip known low-FODMAP exceptions
		if isLowFODMAPException(ingredientLower) {
			continue
		}

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

// AnalyzeAllRecipesFODMAP analyzes all recipes and returns compliance summary
func AnalyzeAllRecipesFODMAP(recipes []Recipe) []FODMAPAnalysis {
	analyses := make([]FODMAPAnalysis, len(recipes))
	for i, recipe := range recipes {
		analyses[i] = AnalyzeRecipeFODMAP(recipe)
	}
	return analyses
}

// RecipeAuditSummary provides an overview of recipe compliance
type RecipeAuditSummary struct {
	TotalRecipes          int     `json:"total_recipes"`
	CompliantRecipes      int     `json:"compliant_recipes"`
	NonCompliantRecipes   int     `json:"non_compliant_recipes"`
	OverallComplianceRate float64 `json:"overall_compliance_rate"`
}

// GenerateAuditSummary creates a summary from FODMAP analyses
func GenerateAuditSummary(analyses []FODMAPAnalysis) RecipeAuditSummary {
	summary := RecipeAuditSummary{
		TotalRecipes: len(analyses),
	}
	for _, analysis := range analyses {
		if analysis.IsLowFODMAP {
			summary.CompliantRecipes++
		} else {
			summary.NonCompliantRecipes++
		}
	}
	if summary.TotalRecipes > 0 {
		summary.OverallComplianceRate = float64(summary.CompliantRecipes) / float64(summary.TotalRecipes) * 100
	}
	return summary
}

// PrintAuditReport outputs a formatted recipe compliance audit
func PrintAuditReport(recipes []Recipe) {
	analyses := AnalyzeAllRecipesFODMAP(recipes)
	summary := GenerateAuditSummary(analyses)

	fmt.Println("\n==== VERTICAL DIET RECIPE AUDIT ====")
	fmt.Printf("Total Recipes: %d\n", summary.TotalRecipes)
	fmt.Printf("Compliant (Low-FODMAP): %d (%.1f%%)\n", summary.CompliantRecipes, summary.OverallComplianceRate)
	fmt.Printf("Non-Compliant: %d\n", summary.NonCompliantRecipes)
	fmt.Println("\n--- Non-Compliant Recipes ---")

	for _, analysis := range analyses {
		if !analysis.IsLowFODMAP {
			fmt.Printf("\n%s (%.0f%% compliant)\n", analysis.Recipe, analysis.CompliancePercentage)
			fmt.Printf("  High-FODMAP ingredients: %v\n", analysis.HighFODMAPFound)
		}
	}
	fmt.Println("\n==== END AUDIT ====")
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

// =============================================================================
// Meal Selection Algorithm
// =============================================================================

// MealCategory represents the food category for selection distribution
type MealCategory string

const (
	MealCategoryRedMeat MealCategory = "red_meat"
	MealCategorySalmon  MealCategory = "salmon"
	MealCategoryEggs    MealCategory = "eggs"
	MealCategoryVariety MealCategory = "variety"
)

// GetMealCategory determines the category of a recipe based on its ingredients and category
func GetMealCategory(recipe Recipe) MealCategory {
	category := strings.ToLower(recipe.Category)
	name := strings.ToLower(recipe.Name)

	// Check for red meat categories
	if category == "beef" || category == "vertical-beef" || category == "pork" {
		return MealCategoryRedMeat
	}

	// Check for salmon
	if strings.Contains(name, "salmon") || strings.Contains(category, "salmon") {
		return MealCategorySalmon
	}

	// Check for eggs
	if strings.Contains(name, "egg") || category == "breakfast" || category == "vertical-breakfast" {
		return MealCategoryEggs
	}

	// Everything else is variety
	return MealCategoryVariety
}

// MealSelectionConfig defines the distribution targets
type MealSelectionConfig struct {
	RedMeatMinPercent float64 // 60%
	RedMeatMaxPercent float64 // 70%
	ProteinMinPercent float64 // 20% (salmon + eggs)
	ProteinMaxPercent float64 // 30%
	VarietyMaxPercent float64 // 10%
}

// DefaultMealSelectionConfig returns the Vertical Diet recommended distribution
func DefaultMealSelectionConfig() MealSelectionConfig {
	return MealSelectionConfig{
		RedMeatMinPercent: 0.60,
		RedMeatMaxPercent: 0.70,
		ProteinMinPercent: 0.20,
		ProteinMaxPercent: 0.30,
		VarietyMaxPercent: 0.10,
	}
}

// MealSelectionResult tracks the distribution of selected meals
type MealSelectionResult struct {
	SelectedRecipes []Recipe
	RedMeatCount    int
	SalmonCount     int
	EggsCount       int
	VarietyCount    int
	TotalCount      int
}

// GetDistribution returns the percentage distribution of meal categories
func (r MealSelectionResult) GetDistribution() map[MealCategory]float64 {
	if r.TotalCount == 0 {
		return map[MealCategory]float64{}
	}
	return map[MealCategory]float64{
		MealCategoryRedMeat: float64(r.RedMeatCount) / float64(r.TotalCount),
		MealCategorySalmon:  float64(r.SalmonCount) / float64(r.TotalCount),
		MealCategoryEggs:    float64(r.EggsCount) / float64(r.TotalCount),
		MealCategoryVariety: float64(r.VarietyCount) / float64(r.TotalCount),
	}
}

// IsWithinTargets checks if the selection meets Vertical Diet distribution
func (r MealSelectionResult) IsWithinTargets(config MealSelectionConfig) bool {
	if r.TotalCount == 0 {
		return false
	}
	dist := r.GetDistribution()

	// Red meat should be 60-70%
	redMeat := dist[MealCategoryRedMeat]
	if redMeat < config.RedMeatMinPercent || redMeat > config.RedMeatMaxPercent {
		return false
	}

	// Salmon + Eggs should be 20-30%
	proteinAlt := dist[MealCategorySalmon] + dist[MealCategoryEggs]
	if proteinAlt < config.ProteinMinPercent || proteinAlt > config.ProteinMaxPercent {
		return false
	}

	// Variety should be at most 10%
	if dist[MealCategoryVariety] > config.VarietyMaxPercent {
		return false
	}

	return true
}

// SelectMealsForWeek selects meals following Vertical Diet distribution
// targetMeals is the number of main meals to select (e.g., 21 for 7 days x 3 meals)
func SelectMealsForWeek(recipes []Recipe, targetMeals int) MealSelectionResult {
	config := DefaultMealSelectionConfig()
	result := MealSelectionResult{}

	// Categorize all available recipes
	var redMeatRecipes, salmonRecipes, eggsRecipes, varietyRecipes []Recipe
	for _, r := range recipes {
		if !r.IsVerticalDietCompliant() {
			continue
		}
		switch GetMealCategory(r) {
		case MealCategoryRedMeat:
			redMeatRecipes = append(redMeatRecipes, r)
		case MealCategorySalmon:
			salmonRecipes = append(salmonRecipes, r)
		case MealCategoryEggs:
			eggsRecipes = append(eggsRecipes, r)
		case MealCategoryVariety:
			varietyRecipes = append(varietyRecipes, r)
		}
	}

	// Calculate target counts (using middle of ranges)
	redMeatTarget := int(float64(targetMeals) * 0.65) // 65% = middle of 60-70%
	proteinTarget := int(float64(targetMeals) * 0.25) // 25% = middle of 20-30%
	varietyTarget := targetMeals - redMeatTarget - proteinTarget

	// Cap variety at 10%
	maxVariety := int(float64(targetMeals) * config.VarietyMaxPercent)
	if varietyTarget > maxVariety {
		varietyTarget = maxVariety
	}

	// Select red meat meals (cycle through if needed)
	for i := 0; i < redMeatTarget && len(redMeatRecipes) > 0; i++ {
		result.SelectedRecipes = append(result.SelectedRecipes, redMeatRecipes[i%len(redMeatRecipes)])
		result.RedMeatCount++
	}

	// Select salmon/eggs meals (alternate between them)
	salmonTarget := proteinTarget / 2
	eggsTarget := proteinTarget - salmonTarget

	for i := 0; i < salmonTarget && len(salmonRecipes) > 0; i++ {
		result.SelectedRecipes = append(result.SelectedRecipes, salmonRecipes[i%len(salmonRecipes)])
		result.SalmonCount++
	}

	for i := 0; i < eggsTarget && len(eggsRecipes) > 0; i++ {
		result.SelectedRecipes = append(result.SelectedRecipes, eggsRecipes[i%len(eggsRecipes)])
		result.EggsCount++
	}

	// If we couldn't fill salmon/eggs targets, add more from the other
	remaining := proteinTarget - result.SalmonCount - result.EggsCount
	if remaining > 0 && len(eggsRecipes) > 0 {
		for i := 0; i < remaining; i++ {
			result.SelectedRecipes = append(result.SelectedRecipes, eggsRecipes[i%len(eggsRecipes)])
			result.EggsCount++
		}
	}

	// Select variety meals
	for i := 0; i < varietyTarget && len(varietyRecipes) > 0; i++ {
		result.SelectedRecipes = append(result.SelectedRecipes, varietyRecipes[i%len(varietyRecipes)])
		result.VarietyCount++
	}

	result.TotalCount = result.RedMeatCount + result.SalmonCount + result.EggsCount + result.VarietyCount

	return result
}

// PrintMealSelectionSummary displays the meal selection distribution
func PrintMealSelectionSummary(result MealSelectionResult) {
	fmt.Println("\n=== Meal Selection Summary ===")
	fmt.Printf("Total Meals Selected: %d\n\n", result.TotalCount)

	dist := result.GetDistribution()
	fmt.Println("Distribution:")
	fmt.Printf("  Red Meat:    %d (%.1f%%)\n", result.RedMeatCount, dist[MealCategoryRedMeat]*100)
	fmt.Printf("  Salmon:      %d (%.1f%%)\n", result.SalmonCount, dist[MealCategorySalmon]*100)
	fmt.Printf("  Eggs:        %d (%.1f%%)\n", result.EggsCount, dist[MealCategoryEggs]*100)
	fmt.Printf("  Variety:     %d (%.1f%%)\n", result.VarietyCount, dist[MealCategoryVariety]*100)

	config := DefaultMealSelectionConfig()
	if result.IsWithinTargets(config) {
		fmt.Println("\n✓ Selection meets Vertical Diet distribution targets")
	} else {
		fmt.Println("\n✗ Selection does NOT meet Vertical Diet distribution targets")
	}
}

// =============================================================================
// Portion Calculator
// =============================================================================

// PortionCalculation represents a scaled recipe portion
type PortionCalculation struct {
	Recipe       Recipe
	ScaleFactor  float64 // 1.0 = original serving, 1.5 = 150% of serving
	ScaledMacros Macros
	MeetsTarget  bool    // within 5% of target macros
	Variance     float64 // percentage variance from target
}

// CalculatePortionForTarget scales a recipe to hit target macros
// Prioritizes hitting protein target since it's the key constraint in Vertical Diet
func CalculatePortionForTarget(recipe Recipe, targetMacros Macros) PortionCalculation {
	result := PortionCalculation{
		Recipe: recipe,
	}

	// If recipe has no macros defined, return 1.0 scale factor
	if recipe.Macros.Protein == 0 && recipe.Macros.Fat == 0 && recipe.Macros.Carbs == 0 {
		result.ScaleFactor = 1.0
		result.ScaledMacros = recipe.Macros
		result.MeetsTarget = false
		result.Variance = 100.0 // No macro data
		return result
	}

	// Calculate scale factor based on protein (primary macro)
	if recipe.Macros.Protein > 0 && targetMacros.Protein > 0 {
		result.ScaleFactor = targetMacros.Protein / recipe.Macros.Protein
	} else if recipe.Macros.Calories() > 0 && targetMacros.Calories() > 0 {
		// Fallback to calories if no protein
		result.ScaleFactor = targetMacros.Calories() / recipe.Macros.Calories()
	} else {
		result.ScaleFactor = 1.0
	}

	// Cap scale factor to reasonable range (0.25x to 4x)
	if result.ScaleFactor < 0.25 {
		result.ScaleFactor = 0.25
	}
	if result.ScaleFactor > 4.0 {
		result.ScaleFactor = 4.0
	}

	// Calculate scaled macros
	result.ScaledMacros = Macros{
		Protein: recipe.Macros.Protein * result.ScaleFactor,
		Fat:     recipe.Macros.Fat * result.ScaleFactor,
		Carbs:   recipe.Macros.Carbs * result.ScaleFactor,
	}

	// Calculate variance from target
	proteinVar := 0.0
	if targetMacros.Protein > 0 {
		proteinVar = (result.ScaledMacros.Protein - targetMacros.Protein) / targetMacros.Protein
		if proteinVar < 0 {
			proteinVar = -proteinVar
		}
	}

	fatVar := 0.0
	if targetMacros.Fat > 0 {
		fatVar = (result.ScaledMacros.Fat - targetMacros.Fat) / targetMacros.Fat
		if fatVar < 0 {
			fatVar = -fatVar
		}
	}

	carbsVar := 0.0
	if targetMacros.Carbs > 0 {
		carbsVar = (result.ScaledMacros.Carbs - targetMacros.Carbs) / targetMacros.Carbs
		if carbsVar < 0 {
			carbsVar = -carbsVar
		}
	}

	// Average variance across macros
	result.Variance = (proteinVar + fatVar + carbsVar) / 3.0 * 100.0

	// Check if within 5% tolerance (on protein primarily)
	result.MeetsTarget = proteinVar <= 0.05

	return result
}

// CalculateDailyPortions distributes daily macro targets across meals
func CalculateDailyPortions(dailyMacros Macros, mealsPerDay int, recipes []Recipe) []PortionCalculation {
	if mealsPerDay <= 0 {
		return nil
	}

	// Divide daily macros evenly across meals
	perMealMacros := Macros{
		Protein: dailyMacros.Protein / float64(mealsPerDay),
		Fat:     dailyMacros.Fat / float64(mealsPerDay),
		Carbs:   dailyMacros.Carbs / float64(mealsPerDay),
	}

	var portions []PortionCalculation
	for _, recipe := range recipes {
		portions = append(portions, CalculatePortionForTarget(recipe, perMealMacros))
	}

	return portions
}

// PrintPortionCalculation displays the portion calculation result
func PrintPortionCalculation(calc PortionCalculation) {
	fmt.Printf("\n%s:\n", calc.Recipe.Name)
	fmt.Printf("  Scale Factor: %.2fx\n", calc.ScaleFactor)
	fmt.Printf("  Scaled Macros: P:%.0fg F:%.0fg C:%.0fg (%.0f cal)\n",
		calc.ScaledMacros.Protein, calc.ScaledMacros.Fat, calc.ScaledMacros.Carbs,
		calc.ScaledMacros.Calories())
	if calc.MeetsTarget {
		fmt.Printf("  ✓ Meets protein target (%.1f%% variance)\n", calc.Variance)
	} else {
		fmt.Printf("  ✗ Does not meet target (%.1f%% variance)\n", calc.Variance)
	}
}

// =============================================================================
// Weekly Plan Generator
// =============================================================================

// DayNames for weekly plan generation
var DayNames = []string{"Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday", "Sunday"}

// GenerateWeeklyPlan creates a 7-day meal plan using Vertical Diet distribution
func GenerateWeeklyPlan(profile UserProfile, recipes []Recipe) WeeklyMealPlan {
	plan := WeeklyMealPlan{
		UserProfile: profile,
	}

	// Calculate daily macro targets from profile
	dailyMacros := Macros{
		Protein: profile.DailyProteinTarget(),
		Fat:     profile.DailyFatTarget(),
		Carbs:   profile.DailyCarbTarget(),
	}

	// Select meals for the week using Vertical Diet distribution
	totalMeals := 7 * profile.MealsPerDay
	selection := SelectMealsForWeek(recipes, totalMeals)

	// Distribute selected recipes across days
	recipeIdx := 0
	for day := 0; day < 7; day++ {
		dailyPlan := DailyPlan{
			DayName: DayNames[day],
			Meals:   make([]Meal, 0, profile.MealsPerDay),
		}

		// Per-meal macro target
		perMealMacros := Macros{
			Protein: dailyMacros.Protein / float64(profile.MealsPerDay),
			Fat:     dailyMacros.Fat / float64(profile.MealsPerDay),
			Carbs:   dailyMacros.Carbs / float64(profile.MealsPerDay),
		}

		for meal := 0; meal < profile.MealsPerDay && recipeIdx < len(selection.SelectedRecipes); meal++ {
			recipe := selection.SelectedRecipes[recipeIdx]
			recipeIdx++

			// Calculate portion to hit macro target
			portion := CalculatePortionForTarget(recipe, perMealMacros)

			dailyPlan.Meals = append(dailyPlan.Meals, Meal{
				Recipe:      recipe,
				PortionSize: portion.ScaleFactor,
			})
		}

		plan.Days[day] = dailyPlan
	}

	// Generate shopping list from all meals
	plan.ShoppingList = GenerateShoppingList(plan)

	return plan
}

// GenerateShoppingList aggregates ingredients from all meals in the plan
func GenerateShoppingList(plan WeeklyMealPlan) []Ingredient {
	ingredientMap := make(map[string]Ingredient)

	for _, day := range plan.Days {
		for _, meal := range day.Meals {
			for _, ing := range meal.Recipe.Ingredients {
				key := strings.ToLower(ing.Name)
				if existing, ok := ingredientMap[key]; ok {
					// Combine quantities (simplified - just append)
					existing.Quantity = existing.Quantity + " + " + ing.Quantity
					ingredientMap[key] = existing
				} else {
					ingredientMap[key] = ing
				}
			}
		}
	}

	// Convert map to slice
	var list []Ingredient
	for _, ing := range ingredientMap {
		list = append(list, ing)
	}

	return list
}

// =============================================================================
// Strict Validation Rules
// =============================================================================

// ForbiddenSeedOils list of seed/vegetable oils not allowed on Vertical Diet
var ForbiddenSeedOils = []string{
	"canola oil", "soybean oil", "corn oil", "vegetable oil",
	"sunflower oil", "safflower oil", "cottonseed oil", "grapeseed oil",
	"rice bran oil", "peanut oil",
}

// ForbiddenGrains list of grains not allowed (white rice is the exception)
var ForbiddenGrains = []string{
	"wheat", "whole wheat", "bread", "pasta", "flour tortilla",
	"rye", "barley", "oats", "oatmeal",
	"quinoa", "couscous", "bulgur",
	"brown rice", // only white rice allowed
}

// AllowedGrains exceptions that are permitted
var AllowedGrains = []string{
	"white rice", "rice cereal", "cream of rice", "rice flour",
}

// ValidationResult represents the outcome of validating a recipe or plan
type ValidationResult struct {
	IsValid    bool     `json:"is_valid"`
	Violations []string `json:"violations"`
	Warnings   []string `json:"warnings"`
	RecipeName string   `json:"recipe_name,omitempty"`
}

// ValidateRecipeStrict performs strict Vertical Diet validation on a recipe
func ValidateRecipeStrict(recipe Recipe) ValidationResult {
	result := ValidationResult{
		IsValid:    true,
		RecipeName: recipe.Name,
	}

	for _, ing := range recipe.Ingredients {
		ingLower := strings.ToLower(ing.Name)

		// Check for seed oils
		for _, oil := range ForbiddenSeedOils {
			if strings.Contains(ingLower, oil) {
				result.IsValid = false
				result.Violations = append(result.Violations,
					fmt.Sprintf("Contains forbidden seed oil: %s", ing.Name))
			}
		}

		// Check for forbidden grains (but allow white rice variants)
		isAllowedGrain := false
		for _, allowed := range AllowedGrains {
			if strings.Contains(ingLower, allowed) {
				isAllowedGrain = true
				break
			}
		}

		if !isAllowedGrain {
			for _, grain := range ForbiddenGrains {
				if strings.Contains(ingLower, grain) {
					result.IsValid = false
					result.Violations = append(result.Violations,
						fmt.Sprintf("Contains forbidden grain: %s", ing.Name))
					break
				}
			}
		}

		// Check for high-FODMAP (reuse existing list)
		if !isLowFODMAPException(ingLower) {
			for _, fodmap := range HighFODMAPIngredients {
				if strings.Contains(ingLower, fodmap) {
					result.IsValid = false
					result.Violations = append(result.Violations,
						fmt.Sprintf("Contains high-FODMAP ingredient: %s", ing.Name))
					break
				}
			}
		}
	}

	return result
}

// ValidateWeeklyPlanStrict validates an entire weekly plan
func ValidateWeeklyPlanStrict(plan WeeklyMealPlan) ValidationResult {
	result := ValidationResult{
		IsValid: true,
	}

	// Track meal categories for distribution validation
	redMeatCount := 0
	totalMeals := 0

	for _, day := range plan.Days {
		for _, meal := range day.Meals {
			totalMeals++

			// Validate each recipe
			recipeResult := ValidateRecipeStrict(meal.Recipe)
			if !recipeResult.IsValid {
				result.IsValid = false
				for _, v := range recipeResult.Violations {
					result.Violations = append(result.Violations,
						fmt.Sprintf("%s: %s", meal.Recipe.Name, v))
				}
			}

			// Count red meat meals
			cat := GetMealCategory(meal.Recipe)
			if cat == MealCategoryRedMeat {
				redMeatCount++
			}
		}
	}

	// Validate red meat frequency (should be 60-70%)
	if totalMeals > 0 {
		redMeatPercent := float64(redMeatCount) / float64(totalMeals)
		if redMeatPercent < 0.55 {
			result.Warnings = append(result.Warnings,
				fmt.Sprintf("Red meat frequency (%.0f%%) is below recommended 60%%", redMeatPercent*100))
		}
		if redMeatPercent > 0.75 {
			result.Warnings = append(result.Warnings,
				fmt.Sprintf("Red meat frequency (%.0f%%) is above recommended 70%%", redMeatPercent*100))
		}
	}

	return result
}

// PrintValidationResult displays validation results
func PrintValidationResult(result ValidationResult) {
	if result.RecipeName != "" {
		fmt.Printf("\n=== Validation: %s ===\n", result.RecipeName)
	} else {
		fmt.Println("\n=== Plan Validation ===")
	}

	if result.IsValid {
		fmt.Println("Status: VALID")
	} else {
		fmt.Println("Status: INVALID")
		fmt.Println("\nViolations:")
		for _, v := range result.Violations {
			fmt.Printf("  - %s\n", v)
		}
	}

	if len(result.Warnings) > 0 {
		fmt.Println("\nWarnings:")
		for _, w := range result.Warnings {
			fmt.Printf("  - %s\n", w)
		}
	}
}

// PrintWeeklyPlan displays the weekly meal plan
func PrintWeeklyPlan(plan WeeklyMealPlan) {
	fmt.Println("\n=== Weekly Meal Plan ===")
	fmt.Printf("Profile: %.0f lbs, %s, %s\n",
		plan.UserProfile.Bodyweight, plan.UserProfile.ActivityLevel, plan.UserProfile.Goal)
	fmt.Printf("Daily Targets: P:%.0fg F:%.0fg C:%.0fg\n\n",
		plan.UserProfile.DailyProteinTarget(),
		plan.UserProfile.DailyFatTarget(),
		plan.UserProfile.DailyCarbTarget())

	for _, day := range plan.Days {
		fmt.Printf("--- %s ---\n", day.DayName)
		dayMacros := day.TotalMacros()
		fmt.Printf("Day Total: P:%.0fg F:%.0fg C:%.0fg\n", dayMacros.Protein, dayMacros.Fat, dayMacros.Carbs)

		for i, meal := range day.Meals {
			mealMacros := meal.Macros()
			fmt.Printf("  Meal %d: %s (%.1fx portion)\n", i+1, meal.Recipe.Name, meal.PortionSize)
			fmt.Printf("          P:%.0fg F:%.0fg C:%.0fg\n", mealMacros.Protein, mealMacros.Fat, mealMacros.Carbs)
		}
		fmt.Println()
	}

	// Print weekly totals
	totalMacros := plan.TotalMacros()
	avgMacros := plan.AverageDailyMacros()
	fmt.Println("=== Weekly Summary ===")
	fmt.Printf("Total:   P:%.0fg F:%.0fg C:%.0fg (%.0f cal)\n",
		totalMacros.Protein, totalMacros.Fat, totalMacros.Carbs, totalMacros.Calories())
	fmt.Printf("Daily Avg: P:%.0fg F:%.0fg C:%.0fg (%.0f cal)\n",
		avgMacros.Protein, avgMacros.Fat, avgMacros.Carbs, avgMacros.Calories())

	// Print shopping list
	if len(plan.ShoppingList) > 0 {
		fmt.Println("\n=== Shopping List ===")
		for _, ing := range plan.ShoppingList {
			fmt.Printf("  - %s: %s\n", ing.Name, ing.Quantity)
		}
	}
}

type EmailPayload struct {
	From struct {
		Email string `json:"email"`
		Name  string `json:"name"`
	} `json:"from"`
	To []struct {
		Email string `json:"email"`
	} `json:"to"`
	Subject  string `json:"subject"`
	Text     string `json:"text"`
	Category string `json:"category"`
}

// EmailPreference represents user's choice for email delivery
type EmailPreference int

const (
	EmailPreferenceTerminal EmailPreference = iota
	EmailPreferenceSend
)

func loadEnv() error {
	err := godotenv.Load()
	if err != nil {
		if !os.IsNotExist(err) {
			return fmt.Errorf("error loading .env file: %w", err)
		}
	}
	requiredVars := []string{"MAILTRAP_API_TOKEN", "SENDER_EMAIL", "SENDER_NAME", "RECIPIENT_EMAIL"}
	var missingVars []string
	for _, v := range requiredVars {
		if os.Getenv(v) == "" {
			missingVars = append(missingVars, v)
		}
	}
	if len(missingVars) > 0 {
		return fmt.Errorf("missing required environment variables: %s", strings.Join(missingVars, ", "))
	}
	return nil
}

func readYAMLFile(filename string) ([]byte, error) {
	data, err := os.ReadFile(filename)
	if err != nil {
		return nil, fmt.Errorf("couldn't read file %s: %w", filename, err)
	}
	return data, nil
}

func parseYAML(data []byte) (RecipeCollection, error) {
	var recipes RecipeCollection
	if err := yaml.Unmarshal(data, &recipes); err != nil {
		return RecipeCollection{}, fmt.Errorf("couldn't parse the YAML file: %w", err)
	}
	return recipes, nil
}

func getRecipeFiles(dir, excludeFile string) ([]string, error) {
	var yamlFiles []string
	entries, err := os.ReadDir(dir)
	if err != nil {
		return nil, fmt.Errorf("couldn't read directory %s: %w", dir, err)
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



func shuffleRecipes(recipes []Recipe) {
	rand.Shuffle(len(recipes), func(i, j int) {
		recipes[i], recipes[j] = recipes[j], recipes[i]
	})
}

func loadRecipes(dir, excludeFile string) ([]Recipe, error) {
	recipeFiles, err := getRecipeFiles(dir, excludeFile)
	if err != nil {
		return nil, err
	}
	var allRecipes []Recipe
	for _, file := range recipeFiles {
		data, err := readYAMLFile(file)
		if err != nil {
			fmt.Printf("Warning: %v\n", err)
			continue
		}
		recipeCollection, err := parseYAML(data)
		if err != nil {
			fmt.Printf("Warning: Error parsing file %s: %v\n", file, err)
			continue
		}
		allRecipes = append(allRecipes, recipeCollection.Recipes...)
	}
	return allRecipes, nil
}

// AppMode represents the application mode selection
type AppMode int

const (
	AppModeTerminal AppMode = iota
	AppModeEmail
	AppModeAudit
	AppModeProfile
)

// askAppMode prompts the user to choose the application mode
func askAppMode() (AppMode, error) {
	fmt.Print("Select mode - (t)erminal, (e)mail, (a)udit, or (p)rofile: ")
	reader := bufio.NewReader(os.Stdin)
	input, err := reader.ReadString('\n')
	if err != nil {
		return AppModeTerminal, fmt.Errorf("error reading input: %w", err)
	}

	input = strings.ToLower(strings.TrimSpace(input))
	switch input {
	case "email", "e":
		return AppModeEmail, nil
	case "audit", "a":
		return AppModeAudit, nil
	case "profile", "p":
		return AppModeProfile, nil
	default:
		return AppModeTerminal, nil
	}
}

// askEmailPreference prompts the user to choose whether to send an email or display in terminal
// Deprecated: Use askAppMode instead
func askEmailPreference() (EmailPreference, error) {
	fmt.Print("Would you like to send an email or just display recipes in terminal? (terminal/email): ")
	reader := bufio.NewReader(os.Stdin)
	input, err := reader.ReadString('\n')
	if err != nil {
		return EmailPreferenceTerminal, fmt.Errorf("error reading input: %w", err)
	}

	input = strings.ToLower(strings.TrimSpace(input))
	if input == "email" {
		return EmailPreferenceSend, nil
	}
	return EmailPreferenceTerminal, nil
}

func printRecipe(title string, recipe Recipe) string {
	var sb strings.Builder
	sb.WriteString(fmt.Sprintf("%s: %s\n", title, recipe.Name))
	sb.WriteString("Ingredients:\n")
	for _, ingredient := range recipe.Ingredients {
		sb.WriteString(fmt.Sprintf("- %s: %s\n", ingredient.Name, ingredient.Quantity))
	}
	sb.WriteString("Instructions:\n")
	for i, instruction := range recipe.Instructions {
		sb.WriteString(fmt.Sprintf("  %d. %s\n", i+1, instruction))
	}
	sb.WriteString("\n")
	return sb.String()
}

func min(a, b int) int {
	if a < b {
		return a
	}
	return b
}

func sendEmail(ctx context.Context, payload EmailPayload) error {
	url := "https://send.api.mailtrap.io/api/send"
	payloadBytes, err := json.Marshal(payload)
	if err != nil {
		return fmt.Errorf("error marshalling email payload: %w", err)
	}
	req, err := http.NewRequestWithContext(ctx, "POST", url, strings.NewReader(string(payloadBytes)))
	if err != nil {
		return fmt.Errorf("creating request failed: %w", err)
	}
	apiToken := os.Getenv("MAILTRAP_API_TOKEN")
	if apiToken == "" {
		return fmt.Errorf("MAILTRAP_API_TOKEN environment variable not set")
	}
	req.Header.Add("Authorization", "Bearer "+apiToken)
	req.Header.Add("Content-Type", "application/json")
	client := &http.Client{}
	res, err := client.Do(req)
	if err != nil {
		return fmt.Errorf("sending request failed: %w", err)
	}
	defer res.Body.Close()
	body, err := io.ReadAll(res.Body)
	if err != nil {
		return fmt.Errorf("reading response body failed: %w", err)
	}
	if res.StatusCode < 200 || res.StatusCode >= 300 {
		return fmt.Errorf("received non-success status code %d: %s", res.StatusCode, string(body))
	}
	fmt.Println("Email sent successfully!")
	fmt.Println("Response Body:", string(body))
	return nil
}

func main() {
	// Initialize application
	if err := InitializeApp(); err != nil {
		fmt.Printf("Initialization failed: %v\n", err)
		return
	}

	// Load recipes from BadgerDB
	bdb, err := InitBadgerDatabase()
	if err != nil {
		fmt.Printf("Failed to connect to BadgerDB: %v\n", err)
		return
	}
	defer bdb.Close()

	allRecipes, err := bdb.GetAllRecipes()
	if err != nil {
		fmt.Printf("Error loading recipes from BadgerDB: %v\n", err)
		return
	}
	if len(allRecipes) == 0 {
		fmt.Println("No recipes found in BadgerDB.")
		return
	}
	
	// Ask user for mode
	mode, err := askAppMode()
	if err != nil {
		fmt.Println("Error getting mode:", err)
		mode = AppModeTerminal
	}

	// Handle audit mode
	if mode == AppModeAudit {
		PrintAuditReport(allRecipes)
		return
	}

	// Handle profile mode
	if mode == AppModeProfile {
		profile, err := CollectUserProfile()
		if err != nil {
			fmt.Println("Error collecting profile:", err)
			return
		}
		PrintUserProfile(profile)
		return
	}

	// Shuffle and select recipes
	shuffleRecipes(allRecipes)
	numRecipes := 4
	if len(allRecipes) < numRecipes {
		numRecipes = len(allRecipes)
	}

	// Generate output
	var output strings.Builder
	for i := 0; i < numRecipes; i++ {
		recipe := allRecipes[i]
		output.WriteString(printRecipe(fmt.Sprintf("Recipe %d", i+1), recipe))
		output.WriteString(strings.Repeat("-", 48) + "\n\n")
	}
	recipeContent := "Today's Recipe Selection - " + time.Now().Format("January 02, 2006") + "\n\n" + output.String()

	if mode == AppModeTerminal {
		// Output to terminal
		fmt.Println("\n==== RECIPE SELECTION ====")
		fmt.Println(output.String())
		fmt.Println("\n==== END OF RECIPE SELECTION ====")
	} else {
		// Send email
		if err := loadEnv(); err != nil {
			fmt.Println(err)
			return
		}
		senderEmail := os.Getenv("SENDER_EMAIL")
		senderName := os.Getenv("SENDER_NAME")
		recipientEmail := os.Getenv("RECIPIENT_EMAIL")
		if senderEmail == "" || senderName == "" || recipientEmail == "" {
			fmt.Println("Error: SENDER_EMAIL, SENDER_NAME, and RECIPIENT_EMAIL must be set in the environment")
			return
		}

		ctx, cancel := context.WithTimeout(context.Background(), 10*time.Second)
		defer cancel()

		emailPayload := EmailPayload{}
		emailPayload.From.Email = senderEmail
		emailPayload.From.Name = senderName
		emailPayload.To = []struct {
			Email string `json:"email"`
		}{
			{Email: recipientEmail},
		}
		emailPayload.Subject = "Weekly Recipe Selection for " + time.Now().Format("January 02, 2006")
		emailPayload.Text = recipeContent
		emailPayload.Category = "Recipe Integration"

		if err := sendEmail(ctx, emailPayload); err != nil {
			fmt.Println("Error sending email:", err)
			// Fallback to terminal output
			fmt.Println("\n==== RECIPE SELECTION ====")
			fmt.Println(output.String())
			fmt.Println("\n==== END OF RECIPE SELECTION ====")
		} else {
			fmt.Println("Email sent successfully!")
		}
	}
}
