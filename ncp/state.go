package ncp

import (
	"fmt"
	"time"
)

// NutritionData represents nutrition values for a day
type NutritionData struct {
	Date     time.Time `json:"date"`
	Protein  float64   `json:"protein"`
	Fat      float64   `json:"fat"`
	Carbs    float64   `json:"carbs"`
	Calories float64   `json:"calories"`
}

// NutritionState represents the nutrition state for a specific day
type NutritionState struct {
	Date     time.Time     `json:"date"`
	Consumed NutritionData `json:"consumed"`
	SyncedAt time.Time     `json:"synced_at"`
}

// Key returns the BadgerDB key for this state
func (s NutritionState) Key() string {
	return fmt.Sprintf("ncp:state:%s", s.Date.Format("2006-01-02"))
}

// ParseStateKey extracts the date from a state key
func ParseStateKey(key string) (time.Time, error) {
	// Key format: "ncp:state:2006-01-02"
	if len(key) < 15 {
		return time.Time{}, fmt.Errorf("invalid state key: %s", key)
	}
	dateStr := key[10:] // Skip "ncp:state:"
	return time.Parse("2006-01-02", dateStr)
}
