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
