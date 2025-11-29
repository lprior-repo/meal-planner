package ncp

import (
	"encoding/json"
	"errors"
	"fmt"
	"time"

	"github.com/dgraph-io/badger/v4"
)

// ErrStateNotFound is returned when no nutrition state exists for the given date
var ErrStateNotFound = errors.New("nutrition state not found")

// StoreNutritionState saves a NutritionState to BadgerDB
func StoreNutritionState(db *badger.DB, state NutritionState) error {
	data, err := json.Marshal(state)
	if err != nil {
		return fmt.Errorf("failed to marshal state: %w", err)
	}

	return db.Update(func(txn *badger.Txn) error {
		return txn.Set([]byte(state.Key()), data)
	})
}

// GetNutritionState retrieves a NutritionState for a specific date
func GetNutritionState(db *badger.DB, date time.Time) (*NutritionState, error) {
	key := fmt.Sprintf("ncp:state:%s", date.Format("2006-01-02"))

	var state NutritionState
	err := db.View(func(txn *badger.Txn) error {
		item, err := txn.Get([]byte(key))
		if err != nil {
			if err == badger.ErrKeyNotFound {
				return ErrStateNotFound
			}
			return err
		}

		return item.Value(func(val []byte) error {
			return json.Unmarshal(val, &state)
		})
	})

	if err != nil {
		return nil, err
	}

	return &state, nil
}
