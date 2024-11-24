package main

import (
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

type Recipe struct {
	Name         string       `yaml:"name"`
	Ingredients  []Ingredient `yaml:"ingredients"`
	Instructions []string     `yaml:"instructions"`
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

func getSidesFilePath(dir, sidesFilename string) (string, error) {
	sidesFilePath := filepath.Join(dir, sidesFilename)
	if _, err := os.Stat(sidesFilePath); os.IsNotExist(err) {
		return "", fmt.Errorf("%s file not found in directory %s", sidesFilename, dir)
	}
	return sidesFilePath, nil
}

func shuffleRecipes(recipes []Recipe) {
	rand.Seed(time.Now().UnixNano())
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

func loadSides() ([]Recipe, error) {
	recipesDir := "recipes"
	sidesFilename := "sides.yaml"
	sidesFilePath, err := getSidesFilePath(recipesDir, sidesFilename)
	if err != nil {
		return nil, err
	}
	sidesData, err := readYAMLFile(sidesFilePath)
	if err != nil {
		return nil, fmt.Errorf("error reading sides file: %w", err)
	}
	sidesCollection, err := parseYAML(sidesData)
	if err != nil {
		return nil, fmt.Errorf("error parsing %s: %w", sidesFilename, err)
	}
	return sidesCollection.Recipes, nil
}

func printRecipe(title string, recipe Recipe) string {
	var sb strings.Builder
	sb.WriteString(fmt.Sprintf("%s: %s\n", title, recipe.Name))
	sb.WriteString("Ingredients:\n")
	for _, ingredient := range recipe.Ingredients {
		sb.WriteString(fmt.Sprintf("- %s: %s\n", ingredient.Name, ingredient.Quantity))
	}
	sb.WriteString("Instructions:\n")
	for _, instruction := range recipe.Instructions {
		sb.WriteString(fmt.Sprintf("- %s\n", instruction))
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
	allMainDishes, err := loadRecipes("recipes", "sides.yaml")
	if err != nil {
		fmt.Println("Error loading main dishes:", err)
		return
	}
	if len(allMainDishes) == 0 {
		fmt.Println("No main dish recipes found.")
		return
	}
	sides, err := loadSides()
	if err != nil {
		fmt.Println("Error loading side dishes:", err)
		return
	}
	if len(sides) == 0 {
		fmt.Println("No side dish recipes found.")
		return
	}
	shuffleRecipes(allMainDishes)
	shuffleRecipes(sides)
	numRecipes := 4
	minRecipes := min(len(allMainDishes), len(sides))
	if minRecipes < numRecipes {
		numRecipes = minRecipes
	}
	var selectedMainDishes, selectedSideDishes []Recipe
	var output strings.Builder
	for i := 0; i < numRecipes; i++ {
		mainDish := allMainDishes[i]
		sideDish := sides[i]
		output.WriteString(printRecipe(fmt.Sprintf("Main Dish %d", i+1), mainDish))
		output.WriteString(printRecipe(fmt.Sprintf("Side Dish %d", i+1), sideDish))
		output.WriteString(strings.Repeat("-", 48) + "\n\n")
		selectedMainDishes = append(selectedMainDishes, mainDish)
		selectedSideDishes = append(selectedSideDishes, sideDish)
	}
	emailContent := "Today's Recipe Selection - " + time.Now().Format("January 02, 2006") + "\n\n" + output.String()
	emailPayload := EmailPayload{}
	emailPayload.From.Email = senderEmail
	emailPayload.From.Name = senderName
	emailPayload.To = []struct {
		Email string `json:"email"`
	}{
		{Email: recipientEmail},
	}
	emailPayload.Subject = "Weekly Recipe Selection for " + time.Now().Format("January 02, 2006")
	emailPayload.Text = emailContent
	emailPayload.Category = "Recipe Integration"
	if err := sendEmail(ctx, emailPayload); err != nil {
		fmt.Println("Error sending email:", err)
	}
}
