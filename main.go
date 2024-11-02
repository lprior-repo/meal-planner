package main

import (
	"fmt"
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
	var parseStruct RecipeStruct
	if err := yaml.Unmarshal(recipeFile, &parseStruct); err != nil {
		return RecipeStruct{}, fmt.Errorf("couldn't parse the YAML file: %w", err)
	}
	return parseStruct, nil
}

func main() {
	recipeFile, err := readFile("recipes.yaml")
	if err != nil {
		fmt.Println(err)
		return
	}

	recipes, err := parseFile(recipeFile)
	if err != nil {
		fmt.Println(err)
		return
	}

	fmt.Println(recipes)
}
