package ncp

import "math"

// DeviationResult represents the percentage deviation from goals
type DeviationResult struct {
	ProteinPct   float64 `json:"protein_pct"`
	FatPct       float64 `json:"fat_pct"`
	CarbsPct     float64 `json:"carbs_pct"`
	CaloriesPct  float64 `json:"calories_pct"`
}

// CalculateDeviation computes the percentage deviation between actual and goals
// Returns positive values for over, negative for under
func CalculateDeviation(goals NutritionGoals, actual NutritionData) DeviationResult {
	return DeviationResult{
		ProteinPct:  calcPctDeviation(goals.DailyProtein, actual.Protein),
		FatPct:      calcPctDeviation(goals.DailyFat, actual.Fat),
		CarbsPct:    calcPctDeviation(goals.DailyCarbs, actual.Carbs),
		CaloriesPct: calcPctDeviation(goals.DailyCalories, actual.Calories),
	}
}

// calcPctDeviation calculates (actual - goal) / goal * 100
func calcPctDeviation(goal, actual float64) float64 {
	if goal == 0 {
		return 0
	}
	return ((actual - goal) / goal) * 100
}

// IsWithinTolerance checks if all macro deviations are within the given tolerance
func (d DeviationResult) IsWithinTolerance(tolerancePct float64) bool {
	return math.Abs(d.ProteinPct) <= tolerancePct &&
		math.Abs(d.FatPct) <= tolerancePct &&
		math.Abs(d.CarbsPct) <= tolerancePct
}

// MaxDeviation returns the maximum absolute deviation across all macros
func (d DeviationResult) MaxDeviation() float64 {
	max := math.Abs(d.ProteinPct)
	if math.Abs(d.FatPct) > max {
		max = math.Abs(d.FatPct)
	}
	if math.Abs(d.CarbsPct) > max {
		max = math.Abs(d.CarbsPct)
	}
	return max
}
