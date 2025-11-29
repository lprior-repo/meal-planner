package ncp

import (
	"testing"
	"time"
)

func TestAverageNutritionHistory_SingleDay(t *testing.T) {
	history := []NutritionState{
		{
			Date: time.Date(2024, 11, 29, 0, 0, 0, 0, time.UTC),
			Consumed: NutritionData{
				Protein:  150.0,
				Fat:      60.0,
				Carbs:    200.0,
				Calories: 2000.0,
			},
		},
	}

	avg := AverageNutritionHistory(history)

	if avg.Protein != 150.0 {
		t.Errorf("Expected protein 150.0, got %f", avg.Protein)
	}
	if avg.Fat != 60.0 {
		t.Errorf("Expected fat 60.0, got %f", avg.Fat)
	}
	if avg.Carbs != 200.0 {
		t.Errorf("Expected carbs 200.0, got %f", avg.Carbs)
	}
	if avg.Calories != 2000.0 {
		t.Errorf("Expected calories 2000.0, got %f", avg.Calories)
	}
}

func TestAverageNutritionHistory_MultipleDays(t *testing.T) {
	history := []NutritionState{
		{
			Date: time.Date(2024, 11, 27, 0, 0, 0, 0, time.UTC),
			Consumed: NutritionData{
				Protein:  100.0,
				Fat:      50.0,
				Carbs:    150.0,
				Calories: 1500.0,
			},
		},
		{
			Date: time.Date(2024, 11, 28, 0, 0, 0, 0, time.UTC),
			Consumed: NutritionData{
				Protein:  200.0,
				Fat:      70.0,
				Carbs:    250.0,
				Calories: 2500.0,
			},
		},
	}

	avg := AverageNutritionHistory(history)

	// (100+200)/2 = 150
	if avg.Protein != 150.0 {
		t.Errorf("Expected protein 150.0, got %f", avg.Protein)
	}
	// (50+70)/2 = 60
	if avg.Fat != 60.0 {
		t.Errorf("Expected fat 60.0, got %f", avg.Fat)
	}
	// (150+250)/2 = 200
	if avg.Carbs != 200.0 {
		t.Errorf("Expected carbs 200.0, got %f", avg.Carbs)
	}
	// (1500+2500)/2 = 2000
	if avg.Calories != 2000.0 {
		t.Errorf("Expected calories 2000.0, got %f", avg.Calories)
	}
}

func TestAverageNutritionHistory_EmptyHistory(t *testing.T) {
	history := []NutritionState{}

	avg := AverageNutritionHistory(history)

	if avg.Protein != 0.0 || avg.Fat != 0.0 || avg.Carbs != 0.0 || avg.Calories != 0.0 {
		t.Errorf("Expected all zeros for empty history, got P:%f F:%f C:%f Cal:%f",
			avg.Protein, avg.Fat, avg.Carbs, avg.Calories)
	}
}
