package main

import (
	"fmt"
	"math/rand"
	"os"

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

type RecipeStruct struct {
	Recipes []Recipe `yaml:"recipes"`
}

func readFile(filename string) ([]byte, error) {
	recipeFile, err := os.ReadFile(filename)
	if err != nil {
		return nil, fmt.Errorf("couldn't read file %s: %w", filename, err)
	}
	return recipeFile, nil
}

func parseFile(recipeFile []byte) (RecipeStruct, error) {
	var recipeData RecipeStruct
	if err := yaml.Unmarshal(recipeFile, &recipeData); err != nil {
		return RecipeStruct{}, fmt.Errorf("couldn't parse the YAML file: %w", err)
	}
	return recipeData, nil
}

func shuffleRecipes(recipes []Recipe) {
	rand.Shuffle(len(recipes), func(i, j int) {
		recipes[i], recipes[j] = recipes[j], recipes[i]
	})
}

func main() {
	recipeFile, err := readFile("recipes.yaml")
	if err != nil {
		fmt.Println(err)
		return
	}

	recipeData, err := parseFile(recipeFile)
	if err != nil {
		fmt.Println(err)
		return
	}

	shuffleRecipes(recipeData.Recipes)

	numRecipes := 4
	if len(recipeData.Recipes) < 4 {
		numRecipes = len(recipeData.Recipes)
	}

	for i := 0; i < numRecipes; i++ {
		randomRecipe := recipeData.Recipes[i]
		fmt.Printf("Recipe %d: %s\n", i+1, randomRecipe.Name)
		fmt.Println("Ingredients:")
		for _, ingredient := range randomRecipe.Ingredients {
			fmt.Printf("- %s: %s\n", ingredient.Name, ingredient.Quantity)
		}
		fmt.Println("Instructions:")
		for _, instruction := range randomRecipe.Instructions {
			fmt.Printf("- %s\n", instruction)
		}
		fmt.Println()
	}
}
