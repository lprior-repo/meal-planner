package ncp

import "time"

// ReconciliationResult contains the full output of a nutrition reconciliation
type ReconciliationResult struct {
	Date            time.Time       `json:"date"`
	AverageConsumed NutritionData   `json:"average_consumed"`
	Goals           NutritionGoals  `json:"goals"`
	Deviation       DeviationResult `json:"deviation"`
	Plan            AdjustmentPlan  `json:"plan"`
	WithinTolerance bool            `json:"within_tolerance"`
}
