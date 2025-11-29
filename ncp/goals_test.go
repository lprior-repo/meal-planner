package ncp

import (
	"testing"
)

func TestNutritionGoals_Struct(t *testing.T) {
	goals := NutritionGoals{
		DailyProtein:  180.0,
		DailyFat:      54.0,
		DailyCarbs:    250.0,
		DailyCalories: 2700.0,
	}

	if goals.DailyProtein != 180.0 {
		t.Errorf("Expected protein 180.0, got %f", goals.DailyProtein)
	}
	if goals.DailyFat != 54.0 {
		t.Errorf("Expected fat 54.0, got %f", goals.DailyFat)
	}
	if goals.DailyCarbs != 250.0 {
		t.Errorf("Expected carbs 250.0, got %f", goals.DailyCarbs)
	}
	if goals.DailyCalories != 2700.0 {
		t.Errorf("Expected calories 2700.0, got %f", goals.DailyCalories)
	}
}

func TestNutritionGoals_Validate(t *testing.T) {
	tests := []struct {
		name    string
		goals   NutritionGoals
		wantErr bool
	}{
		{
			name: "valid goals",
			goals: NutritionGoals{
				DailyProtein:  180.0,
				DailyFat:      54.0,
				DailyCarbs:    250.0,
				DailyCalories: 2700.0,
			},
			wantErr: false,
		},
		{
			name: "zero protein",
			goals: NutritionGoals{
				DailyProtein:  0,
				DailyFat:      54.0,
				DailyCarbs:    250.0,
				DailyCalories: 2700.0,
			},
			wantErr: true,
		},
		{
			name: "negative protein",
			goals: NutritionGoals{
				DailyProtein:  -10.0,
				DailyFat:      54.0,
				DailyCarbs:    250.0,
				DailyCalories: 2700.0,
			},
			wantErr: true,
		},
		{
			name: "negative fat",
			goals: NutritionGoals{
				DailyProtein:  180.0,
				DailyFat:      -10.0,
				DailyCarbs:    250.0,
				DailyCalories: 2700.0,
			},
			wantErr: true,
		},
		{
			name: "negative carbs",
			goals: NutritionGoals{
				DailyProtein:  180.0,
				DailyFat:      54.0,
				DailyCarbs:    -10.0,
				DailyCalories: 2700.0,
			},
			wantErr: true,
		},
		{
			name: "negative calories",
			goals: NutritionGoals{
				DailyProtein:  180.0,
				DailyFat:      54.0,
				DailyCarbs:    250.0,
				DailyCalories: -100.0,
			},
			wantErr: true,
		},
		{
			name: "zero calories",
			goals: NutritionGoals{
				DailyProtein:  180.0,
				DailyFat:      54.0,
				DailyCarbs:    250.0,
				DailyCalories: 0,
			},
			wantErr: true,
		},
		{
			name: "zero fat is valid",
			goals: NutritionGoals{
				DailyProtein:  180.0,
				DailyFat:      0,
				DailyCarbs:    250.0,
				DailyCalories: 2700.0,
			},
			wantErr: false,
		},
		{
			name: "zero carbs is valid",
			goals: NutritionGoals{
				DailyProtein:  180.0,
				DailyFat:      54.0,
				DailyCarbs:    0,
				DailyCalories: 2700.0,
			},
			wantErr: false,
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			err := tt.goals.Validate()
			if (err != nil) != tt.wantErr {
				t.Errorf("NutritionGoals.Validate() error = %v, wantErr %v", err, tt.wantErr)
			}
		})
	}
}

func TestNewNutritionGoals(t *testing.T) {
	// Test creating goals from manual values
	goals := NewNutritionGoals(180.0, 54.0, 250.0, 2700.0)

	if goals.DailyProtein != 180.0 {
		t.Errorf("Expected protein 180.0, got %f", goals.DailyProtein)
	}
	if goals.DailyCalories != 2700.0 {
		t.Errorf("Expected calories 2700.0, got %f", goals.DailyCalories)
	}
}
