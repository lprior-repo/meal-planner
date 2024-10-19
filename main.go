package main

import (
	"fmt"
	"os"

	"gopkg.in/yaml.v3"
)

type RecipeStruct struct {
	Recipes []struct {
		Name        string `yaml:"name"`
		Description string `yaml:"description"`
		Ingredients []struct {
			Name     string `yaml:"name"`
			Quantity string `yaml:"quantity"`
		} `yaml:"ingredients"`
	} `yaml:"recipes"`
}

func readFile(filename string) ([]byte, error) {
	recipeFile, err := os.ReadFile(filename)
	if err != nil {
		return nil, err
	}
	return recipeFile, nil
}

func main() {
	recipeFile, err := readFile("recipes.yaml")
	if err != nil {
		fmt.Println("Couldn't read in recipe file")
	}
	var recipesWrapper RecipeStruct
	yaml.Unmarshal(recipeFile, &recipesWrapper)
	fmt.Println(recipesWrapper.Recipes)
}
