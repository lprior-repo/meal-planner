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
	if err := godotenv.Load(); err != nil {
		return fmt.Errorf("error loading .env file: %w", err)
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

func printRecipe(title string, recipe Recipe) {
	fmt.Printf("%s: %s\n", title, recipe.Name)
	fmt.Println("Ingredients:")
	for _, ingredient := range recipe.Ingredients {
		fmt.Printf("- %s: %s\n", ingredient.Name, ingredient.Quantity)
	}
	fmt.Println("Instructions:")
	for _, instruction := range recipe.Instructions {
		fmt.Printf("- %s\n", instruction)
	}
	fmt.Println()
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
		fmt.Println("Error: SENDER_EMAIL, SENDER_NAME, and RECIPIENT_EMAIL must be set in the .env file")
		return
	}
	recipesDir := "recipes"
	sidesFilename := "sides.yaml"
	ctx, cancel := context.WithTimeout(context.Background(), 10*time.Second)
	defer cancel()
	allMainDishes, err := loadRecipes(recipesDir, sidesFilename)
	if err != nil {
		fmt.Println("Error loading main dishes:", err)
		return
	}
	if len(allMainDishes) == 0 {
		fmt.Println("No main dish recipes found.")
		return
	}
	sidesFilePath, err := getSidesFilePath(recipesDir, sidesFilename)
	if err != nil {
		fmt.Println(err)
		return
	}
	sidesData, err := readYAMLFile(sidesFilePath)
	if err != nil {
		fmt.Println("Error reading sides file:", err)
		return
	}
	sidesCollection, err := parseYAML(sidesData)
	if err != nil {
		fmt.Printf("Error parsing %s: %v\n", sidesFilename, err)
		return
	}
	if len(sidesCollection.Recipes) == 0 {
		fmt.Println("No side dish recipes found.")
		return
	}
	shuffleRecipes(allMainDishes)
	shuffleRecipes(sidesCollection.Recipes)
	numRecipes := 4
	minRecipes := min(len(allMainDishes), len(sidesCollection.Recipes))
	if minRecipes < numRecipes {
		numRecipes = minRecipes
	}
	var selectedMainDishes, selectedSideDishes []Recipe
	for i := 0; i < numRecipes; i++ {
		select {
		case <-ctx.Done():
			fmt.Println("Operation timed out.")
			return
		default:
			mainDish := allMainDishes[i]
			sideDish := sidesCollection.Recipes[i]
			printRecipe(fmt.Sprintf("Main Dish %d", i+1), mainDish)
			printRecipe(fmt.Sprintf("Side Dish %d", i+1), sideDish)
			fmt.Println(strings.Repeat("-", 48))
			selectedMainDishes = append(selectedMainDishes, mainDish)
			selectedSideDishes = append(selectedSideDishes, sideDish)
		}
	}
	emailContent := "Today's Recipe Selection:\n\n"
	for i := 0; i < numRecipes; i++ {
		emailContent += fmt.Sprintf("Main Dish %d: %s\n", i+1, selectedMainDishes[i].Name)
		for _, ingredient := range selectedMainDishes[i].Ingredients {
			emailContent += fmt.Sprintf("  - %s: %s\n", ingredient.Name, ingredient.Quantity)
		}
		for _, instruction := range selectedMainDishes[i].Instructions {
			emailContent += fmt.Sprintf("  * %s\n", instruction)
		}
		emailContent += "\n"
		emailContent += fmt.Sprintf("Side Dish %d: %s\n", i+1, selectedSideDishes[i].Name)
		for _, ingredient := range selectedSideDishes[i].Ingredients {
			emailContent += fmt.Sprintf("  - %s: %s\n", ingredient.Name, ingredient.Quantity)
		}
		for _, instruction := range selectedSideDishes[i].Instructions {
			emailContent += fmt.Sprintf("  * %s\n", instruction)
		}
		emailContent += "\n" + strings.Repeat("-", 48) + "\n\n"
	}
	var emailPayload EmailPayload
	emailPayload.From.Email = senderEmail
	emailPayload.From.Name = senderName
	emailPayload.To = []struct {
		Email string `json:"email"`
	}{
		{Email: recipientEmail},
	}
	emailPayload.Subject = "Today's Recipe Selection!"
	emailPayload.Text = emailContent
	emailPayload.Category = "Recipe Integration"
	if err := sendEmail(ctx, emailPayload); err != nil {
		fmt.Println("Error sending email:", err)
	}
}
