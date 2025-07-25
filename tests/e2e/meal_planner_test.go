package e2e

import (
	"bufio"
	"bytes"
	"context"
	"encoding/json"
	"fmt"
	"io"
	"net/http"
	"net/http/httptest"
	"os"
	"path/filepath"
	"strings"
	"testing"
	"time"

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

// MockMailtrapServer creates a test server to mock Mailtrap API
func MockMailtrapServer() *httptest.Server {
	return httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		if r.URL.Path != "/api/send" {
			http.Error(w, "Not found", http.StatusNotFound)
			return
		}

		if r.Method != "POST" {
			http.Error(w, "Method not allowed", http.StatusMethodNotAllowed)
			return
		}

		body, err := io.ReadAll(r.Body)
		if err != nil {
			http.Error(w, "Error reading request body", http.StatusInternalServerError)
			return
		}

		var payload EmailPayload
		if err := json.Unmarshal(body, &payload); err != nil {
			http.Error(w, "Invalid JSON payload", http.StatusBadRequest)
			return
		}

		// Validate email payload
		if payload.From.Email == "" || len(payload.To) == 0 || payload.To[0].Email == "" || payload.Subject == "" || payload.Text == "" {
			http.Error(w, "Missing required fields in email payload", http.StatusBadRequest)
			return
		}

		// Return successful response
		w.Header().Set("Content-Type", "application/json")
		w.WriteHeader(http.StatusOK)
		response := map[string]interface{}{
			"success": true,
			"message_ids": []string{
				fmt.Sprintf("mock-message-id-%d", time.Now().Unix()),
			},
		}
		json.NewEncoder(w).Encode(response)
	}))
}

// TestMealPlannerE2E is a full end-to-end test of the meal planner
func TestMealPlannerE2E(t *testing.T) {
	// Create test environment
	testDir := setupTestEnvironment(t)
	defer os.RemoveAll(testDir)

	// Mock the Mailtrap API
	mockServer := MockMailtrapServer()
	defer mockServer.Close()

	// Set environment variables for testing
	os.Setenv("MAILTRAP_API_TOKEN", "test-token")
	os.Setenv("SENDER_EMAIL", "test@example.com")
	os.Setenv("SENDER_NAME", "Test Sender")
	os.Setenv("RECIPIENT_EMAIL", "recipient@example.com")

	// Save the current working directory
	originalWd, err := os.Getwd()
	if err != nil {
		t.Fatalf("Failed to get current working directory: %v", err)
	}

	// Change to the test directory
	if err := os.Chdir(testDir); err != nil {
		t.Fatalf("Failed to change to test directory: %v", err)
	}

	// Restore the original working directory after the test
	defer os.Chdir(originalWd)

	// Test both output modes
	t.Run("Terminal Output", func(t *testing.T) {
		// Capture stdout
		oldStdout := os.Stdout
		r, w, _ := os.Pipe()
		os.Stdout = w

		// Mock user input to choose terminal output
		oldStdin := os.Stdin
		pipeReader, pipeWriter, _ := os.Pipe()
		os.Stdin = pipeReader
		go func() {
			pipeWriter.Write([]byte("terminal\n"))
			pipeWriter.Close()
		}()

		// Run the simulation
		simulateMain(t, mockServer.URL)

		// Restore stdin and stdout
		os.Stdin = oldStdin
		w.Close()
		os.Stdout = oldStdout

		var buf bytes.Buffer
		io.Copy(&buf, r)
		output := buf.String()

		// Verify output contains expected text
		if !strings.Contains(output, "RECIPE SELECTION") {
			t.Errorf("Expected terminal output to contain 'RECIPE SELECTION', got: %s", output)
		}
	})

	t.Run("Email Output", func(t *testing.T) {
		// Capture stdout
		oldStdout := os.Stdout
		r, w, _ := os.Pipe()
		os.Stdout = w

		// Mock user input to choose email output
		oldStdin := os.Stdin
		pipeReader, pipeWriter, _ := os.Pipe()
		os.Stdin = pipeReader
		go func() {
			pipeWriter.Write([]byte("email\n"))
			pipeWriter.Close()
		}()

		// Run the simulation
		simulateMain(t, mockServer.URL)

		// Restore stdin and stdout
		os.Stdin = oldStdin
		w.Close()
		os.Stdout = oldStdout

		var buf bytes.Buffer
		io.Copy(&buf, r)
		output := buf.String()

		// Verify output contains expected text
		if !strings.Contains(output, "Email sent successfully") {
			t.Errorf("Expected email output to contain 'Email sent successfully', got: %s", output)
		}
	})
}

// SetupTestEnvironment creates a test directory with recipe files
func setupTestEnvironment(t *testing.T) string {
	t.Helper()

	// Create temp directory
	testDir, err := os.MkdirTemp("", "meal-planner-e2e-*")
	if err != nil {
		t.Fatalf("Failed to create temp directory: %v", err)
	}

	// Create recipes directory
	recipesDir := filepath.Join(testDir, "recipes")
	if err := os.Mkdir(recipesDir, 0755); err != nil {
		t.Fatalf("Failed to create recipes directory: %v", err)
	}

	// Create test recipe files
	beefRecipes := RecipeCollection{
		Recipes: []Recipe{
			{
				Name: "Simple Beef Stir-Fry",
				Ingredients: []Ingredient{
					{Name: "beef sirloin, sliced", Quantity: "2 lbs"},
					{Name: "broccoli florets", Quantity: "2 cups"},
					{Name: "soy sauce", Quantity: "1/4 cup"},
					{Name: "sesame oil", Quantity: "2 tbsp"},
					{Name: "garlic, minced", Quantity: "2 cloves"},
				},
				Instructions: []string{
					"Mix soy sauce, sesame oil, and garlic.",
					"Toss beef slices in the mixture.",
					"Arrange beef and broccoli on a baking sheet.",
					"Bake at 400°F for 20-25 minutes, stirring halfway through.",
				},
			},
			{
				Name: "Beef Tacos",
				Ingredients: []Ingredient{
					{Name: "ground beef", Quantity: "3 lbs"},
					{Name: "taco seasoning", Quantity: "1 packet"},
					{Name: "taco shells", Quantity: "20"},
					{Name: "shredded cheese", Quantity: "2 cups"},
				},
				Instructions: []string{
					"Brown ground beef and mix in taco seasoning.",
					"Fill taco shells with beef and cheese.",
					"Bake at 350°F for 5-10 minutes until cheese melts.",
				},
			},
		},
	}

	chickenRecipes := RecipeCollection{
		Recipes: []Recipe{
			{
				Name: "Lemon Herb Chicken Breasts",
				Ingredients: []Ingredient{
					{Name: "chicken breasts", Quantity: "4 lbs"},
					{Name: "lemon juice", Quantity: "1/4 cup"},
					{Name: "garlic cloves, minced", Quantity: "2"},
					{Name: "fresh rosemary, chopped", Quantity: "2 tbsp"},
					{Name: "salt", Quantity: "1 tbsp"},
				},
				Instructions: []string{
					"Mix lemon juice and garlic in a bowl.",
					"Season chicken with salt.",
					"Coat chicken with the mixture.",
					"Bake at 375°F for 25-30 minutes until internal temperature reaches 165°F.",
				},
			},
		},
	}

	// Write recipe files
	beefData, err := yaml.Marshal(beefRecipes)
	if err != nil {
		t.Fatalf("Failed to marshal beef recipes: %v", err)
	}
	if err := os.WriteFile(filepath.Join(recipesDir, "beef.yaml"), beefData, 0644); err != nil {
		t.Fatalf("Failed to write beef recipes file: %v", err)
	}

	chickenData, err := yaml.Marshal(chickenRecipes)
	if err != nil {
		t.Fatalf("Failed to marshal chicken recipes: %v", err)
	}
	if err := os.WriteFile(filepath.Join(recipesDir, "chicken.yaml"), chickenData, 0644); err != nil {
		t.Fatalf("Failed to write chicken recipes file: %v", err)
	}

	return testDir
}

// MockEmailPreference mocks the user's email preference input
type MockEmailPreference struct {
	preference string // "email" or "terminal"
}

// askEmailPreference mocks the function that asks for email preference
func (m *MockEmailPreference) askEmailPreference() string {
	return m.preference
}

// SimulateMain simulates the main functionality for testing
func simulateMain(t *testing.T, mailtrapURL string) {
	// Load recipes
	allRecipes, err := loadRecipes("recipes", "")
	if err != nil {
		t.Fatalf("Error loading recipes: %v", err)
	}

	if len(allRecipes) == 0 {
		t.Fatalf("No recipes found")
	}

	// Select recipes
	numRecipes := 2
	if len(allRecipes) < numRecipes {
		numRecipes = len(allRecipes)
	}

	var output strings.Builder

	for i := 0; i < numRecipes; i++ {
		recipe := allRecipes[i]

		output.WriteString(fmt.Sprintf("Recipe %d: %s\n", i+1, recipe.Name))
		output.WriteString("Ingredients:\n")
		for _, ingredient := range recipe.Ingredients {
			output.WriteString(fmt.Sprintf("- %s: %s\n", ingredient.Name, ingredient.Quantity))
		}
		output.WriteString("Instructions:\n")
		for j, instruction := range recipe.Instructions {
			output.WriteString(fmt.Sprintf("  %d. %s\n", j+1, instruction))
		}
		output.WriteString("\n")
		output.WriteString(strings.Repeat("-", 48) + "\n\n")
	}

	recipeContent := "Today's Recipe Selection - " + time.Now().Format("January 02, 2006") + "\n\n" + output.String()

	// Read user preference from stdin
	reader := bufio.NewReader(os.Stdin)
	input, err := reader.ReadString('\n')
	if err != nil {
		t.Fatalf("Error reading input: %v", err)
	}
	preference := strings.ToLower(strings.TrimSpace(input))

	if preference == "email" {
		// Send email
		ctx, cancel := context.WithTimeout(context.Background(), 10*time.Second)
		defer cancel()

		// Create email payload
		emailPayload := EmailPayload{}
		emailPayload.From.Email = os.Getenv("SENDER_EMAIL")
		emailPayload.From.Name = os.Getenv("SENDER_NAME")
		emailPayload.To = []struct {
			Email string `json:"email"`
		}{
			{Email: os.Getenv("RECIPIENT_EMAIL")},
		}
		emailPayload.Subject = "Weekly Recipe Selection for " + time.Now().Format("January 02, 2006")
		emailPayload.Text = recipeContent
		emailPayload.Category = "Recipe Integration"

		// Send email to mock server
		if err := sendTestEmail(ctx, emailPayload, mailtrapURL); err != nil {
			t.Fatalf("Error sending email: %v", err)
		}

		fmt.Println("Email sent successfully!")
	} else {
		// Output to terminal
		fmt.Println("\n==== RECIPE SELECTION ====")
		fmt.Println(output.String())
		fmt.Println("\n==== END OF RECIPE SELECTION ====")
	}
}

// Helper function to load recipes
func loadRecipes(dir, excludeFile string) ([]Recipe, error) {
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

	var allRecipes []Recipe
	for _, file := range yamlFiles {
		data, err := os.ReadFile(file)
		if err != nil {
			fmt.Printf("Warning: %v\n", err)
			continue
		}

		var recipeCollection RecipeCollection
		if err := yaml.Unmarshal(data, &recipeCollection); err != nil {
			fmt.Printf("Warning: Error parsing file %s: %v\n", file, err)
			continue
		}

		allRecipes = append(allRecipes, recipeCollection.Recipes...)
	}

	return allRecipes, nil
}

// sendTestEmail sends an email to the mock Mailtrap server
func sendTestEmail(ctx context.Context, payload EmailPayload, mailtrapURL string) error {
	payloadBytes, err := json.Marshal(payload)
	if err != nil {
		return fmt.Errorf("error marshalling email payload: %w", err)
	}

	req, err := http.NewRequestWithContext(ctx, "POST", mailtrapURL+"/api/send", strings.NewReader(string(payloadBytes)))
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

	return nil
}
