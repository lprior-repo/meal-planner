package ncp

import (
	"testing"
)

func TestCalculateDeviation(t *testing.T) {
	goals := NutritionGoals{
		DailyProtein:  180.0,
		DailyFat:      60.0,
		DailyCarbs:    250.0,
		DailyCalories: 2700.0,
	}

	tests := []struct {
		name           string
		actual         NutritionData
		wantProteinPct float64
		wantFatPct     float64
		wantCarbsPct   float64
	}{
		{
			name: "exact match - no deviation",
			actual: NutritionData{
				Protein:  180.0,
				Fat:      60.0,
				Carbs:    250.0,
				Calories: 2700.0,
			},
			wantProteinPct: 0.0,
			wantFatPct:     0.0,
			wantCarbsPct:   0.0,
		},
		{
			name: "10% over protein",
			actual: NutritionData{
				Protein:  198.0, // 180 + 10%
				Fat:      60.0,
				Carbs:    250.0,
				Calories: 2772.0,
			},
			wantProteinPct: 10.0,
			wantFatPct:     0.0,
			wantCarbsPct:   0.0,
		},
		{
			name: "20% under all macros",
			actual: NutritionData{
				Protein:  144.0, // 180 - 20%
				Fat:      48.0,  // 60 - 20%
				Carbs:    200.0, // 250 - 20%
				Calories: 2160.0,
			},
			wantProteinPct: -20.0,
			wantFatPct:     -20.0,
			wantCarbsPct:   -20.0,
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			result := CalculateDeviation(goals, tt.actual)

			if !floatEquals(result.ProteinPct, tt.wantProteinPct, 0.1) {
				t.Errorf("ProteinPct = %f, want %f", result.ProteinPct, tt.wantProteinPct)
			}
			if !floatEquals(result.FatPct, tt.wantFatPct, 0.1) {
				t.Errorf("FatPct = %f, want %f", result.FatPct, tt.wantFatPct)
			}
			if !floatEquals(result.CarbsPct, tt.wantCarbsPct, 0.1) {
				t.Errorf("CarbsPct = %f, want %f", result.CarbsPct, tt.wantCarbsPct)
			}
		})
	}
}

func TestIsWithinTolerance(t *testing.T) {
	tests := []struct {
		name      string
		deviation DeviationResult
		tolerance float64
		want      bool
	}{
		{
			name: "all within 25%",
			deviation: DeviationResult{
				ProteinPct: 10.0,
				FatPct:     -15.0,
				CarbsPct:   20.0,
			},
			tolerance: 25.0,
			want:      true,
		},
		{
			name: "protein exceeds tolerance",
			deviation: DeviationResult{
				ProteinPct: 30.0,
				FatPct:     10.0,
				CarbsPct:   10.0,
			},
			tolerance: 25.0,
			want:      false,
		},
		{
			name: "exactly at tolerance boundary",
			deviation: DeviationResult{
				ProteinPct: 25.0,
				FatPct:     -25.0,
				CarbsPct:   25.0,
			},
			tolerance: 25.0,
			want:      true,
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			got := tt.deviation.IsWithinTolerance(tt.tolerance)
			if got != tt.want {
				t.Errorf("IsWithinTolerance(%f) = %v, want %v", tt.tolerance, got, tt.want)
			}
		})
	}
}

// floatEquals compares two floats with a tolerance
func floatEquals(a, b, tolerance float64) bool {
	diff := a - b
	if diff < 0 {
		diff = -diff
	}
	return diff <= tolerance
}
