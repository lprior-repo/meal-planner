package main

import (
	"context"
	"fmt"
	"math/rand"
	"os"
	"path/filepath"
	"strings"
	"time"

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

func getRecipeFiles(dir string, excludeFile string) ([]string, error) {
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

func getSidesFilePath(dir string, sidesFilename string) (string, error) {
	sidesFilePath := filepath.Join(dir, sidesFilename)
	if _, err := os.Stat(sidesFilePath); os.IsNotExist(err) {
		return "", fmt.Errorf("%s file not found in directory %s", sidesFilename, dir)
	}
	return sidesFilePath, nil
}

func shuffleRecipes(recipes []Recipe) {
	rand.Shuffle(len(recipes), func(i, j int) {
		recipes[i], recipes[j] = recipes[j], recipes[i]
	})
}

func loadRecipes(dir string, excludeFile string) ([]Recipe, error) {
	recipeFiles, err := getRecipeFiles(dir, excludeFile)
	if err != nil {
		return nil, err
	}

	var allRecipes []Recipe
	for _, file := range recipeFiles {
		data, err := readYAMLFile(file)
		if err != nil {
			fmt.Println(err)
			continue
		}

		recipeCollection, err := parseYAML(data)
		if err != nil {
			fmt.Printf("Error parsing file %s: %v\n", file, err)
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

func main() {
	recipesDir := "recipes"
	sidesFilename := "sides.yaml"

	ctx, cancel := context.WithTimeout(context.Background(), 10*time.Second)
	defer cancel()

	allMainDishes, err := loadRecipes(recipesDir, sidesFilename)
	if err != nil {
		fmt.Println(err)
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
		fmt.Println(err)
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
		}
	}
}

func min(a, b int) int {
	if a < b {
		return a
	}
	return b
}
