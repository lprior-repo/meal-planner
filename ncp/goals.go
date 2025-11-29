package ncp

import "errors"

// NutritionGoals represents daily macro targets
type NutritionGoals struct {
	DailyProtein  float64 `json:"daily_protein"`
	DailyFat      float64 `json:"daily_fat"`
	DailyCarbs    float64 `json:"daily_carbs"`
	DailyCalories float64 `json:"daily_calories"`
}

// NewNutritionGoals creates goals from explicit values
func NewNutritionGoals(protein, fat, carbs, calories float64) NutritionGoals {
	return NutritionGoals{
		DailyProtein:  protein,
		DailyFat:      fat,
		DailyCarbs:    carbs,
		DailyCalories: calories,
	}
}

// Validate ensures goals are within reasonable ranges
func (g NutritionGoals) Validate() error {
	if g.DailyProtein <= 0 {
		return errors.New("daily protein must be positive")
	}
	if g.DailyFat < 0 {
		return errors.New("daily fat cannot be negative")
	}
	if g.DailyCarbs < 0 {
		return errors.New("daily carbs cannot be negative")
	}
	if g.DailyCalories <= 0 {
		return errors.New("daily calories must be positive")
	}
	return nil
}
