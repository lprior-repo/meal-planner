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

// askEmailPreference prompts the user to choose whether to send an email or display in terminal
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
	
	// Ask user preference
	preference, err := askEmailPreference()
	if err != nil {
		fmt.Println("Error getting preference:", err)
		preference = EmailPreferenceTerminal
	}
	
	if preference == EmailPreferenceTerminal {
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
