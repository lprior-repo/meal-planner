package ncp

import (
	"encoding/json"
	"testing"
	"time"
)

func TestNutritionState_Struct(t *testing.T) {
	now := time.Now()
	state := NutritionState{
		Date:     now,
		Consumed: NutritionData{
			Date:     now,
			Protein:  150.5,
			Fat:      60.0,
			Carbs:    200.0,
			Calories: 1950.5,
		},
		SyncedAt: now,
	}

	if !state.Date.Equal(now) {
		t.Errorf("Expected date %v, got %v", now, state.Date)
	}
	if state.Consumed.Protein != 150.5 {
		t.Errorf("Expected protein 150.5, got %f", state.Consumed.Protein)
	}
}

func TestNutritionState_JSONMarshaling(t *testing.T) {
	now := time.Now().Truncate(time.Second) // Truncate for JSON comparison
	state := NutritionState{
		Date:     now,
		Consumed: NutritionData{
			Date:     now,
			Protein:  150.5,
			Fat:      60.0,
			Carbs:    200.0,
			Calories: 1950.5,
		},
		SyncedAt: now,
	}

	// Marshal to JSON
	data, err := json.Marshal(state)
	if err != nil {
		t.Fatalf("Failed to marshal state: %v", err)
	}

	// Unmarshal back
	var unmarshaled NutritionState
	err = json.Unmarshal(data, &unmarshaled)
	if err != nil {
		t.Fatalf("Failed to unmarshal state: %v", err)
	}

	if unmarshaled.Consumed.Protein != state.Consumed.Protein {
		t.Errorf("Expected protein %f, got %f", state.Consumed.Protein, unmarshaled.Consumed.Protein)
	}
}

func TestNutritionState_Key(t *testing.T) {
	date := time.Date(2024, 11, 29, 0, 0, 0, 0, time.UTC)
	state := NutritionState{Date: date}

	key := state.Key()
	expectedKey := "ncp:state:2024-11-29"
	if key != expectedKey {
		t.Errorf("Expected key %s, got %s", expectedKey, key)
	}
}
