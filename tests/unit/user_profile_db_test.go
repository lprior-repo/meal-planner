package unit

import (
	"encoding/json"
	"strconv"
	"testing"
	"time"

	"github.com/dgraph-io/badger/v4"
)

// UserProfile represents user data for macro calculations (mirrors main.go)
type UserProfile struct {
	Bodyweight    float64 `json:"bodyweight"`
	ActivityLevel string  `json:"activity_level"`
	Goal          string  `json:"goal"`
	MealsPerDay   int     `json:"meals_per_day"`
}

// StoredUserProfile wraps UserProfile with storage metadata
type StoredUserProfile struct {
	ID        string      `json:"id"`
	Profile   UserProfile `json:"profile"`
	CreatedAt time.Time   `json:"created_at"`
	UpdatedAt time.Time   `json:"updated_at"`
}

const (
	UserProfilePrefix  = "user_profile:"
	UserProfileCounter = "user_profile_counter"
)

// Test UserProfile storage - Create operation
func TestUserProfileCreate(t *testing.T) {
	tempDir := t.TempDir()

	opts := badger.DefaultOptions(tempDir)
	opts.Logger = nil

	db, err := badger.Open(opts)
	if err != nil {
		t.Fatalf("Failed to open BadgerDB: %v", err)
	}
	defer db.Close()

	// Create a user profile
	profile := UserProfile{
		Bodyweight:    180.0,
		ActivityLevel: "moderate",
		Goal:          "maintain",
		MealsPerDay:   4,
	}

	// Get next ID
	var counter int
	err = db.View(func(txn *badger.Txn) error {
		item, err := txn.Get([]byte(UserProfileCounter))
		if err == badger.ErrKeyNotFound {
			counter = 0
			return nil
		}
		if err != nil {
			return err
		}
		return item.Value(func(val []byte) error {
			counter, _ = strconv.Atoi(string(val))
			return nil
		})
	})
	if err != nil {
		t.Fatalf("Failed to get counter: %v", err)
	}

	counter++
	profileID := "user_" + strconv.Itoa(counter)

	storedProfile := StoredUserProfile{
		ID:        profileID,
		Profile:   profile,
		CreatedAt: time.Now(),
		UpdatedAt: time.Now(),
	}

	data, err := json.Marshal(storedProfile)
	if err != nil {
		t.Fatalf("Failed to marshal profile: %v", err)
	}

	// Store the profile
	err = db.Update(func(txn *badger.Txn) error {
		if err := txn.Set([]byte(UserProfileCounter), []byte(strconv.Itoa(counter))); err != nil {
			return err
		}
		return txn.Set([]byte(UserProfilePrefix+profileID), data)
	})
	if err != nil {
		t.Fatalf("Failed to store profile: %v", err)
	}

	// Verify the profile was stored
	var retrieved StoredUserProfile
	err = db.View(func(txn *badger.Txn) error {
		item, err := txn.Get([]byte(UserProfilePrefix + profileID))
		if err != nil {
			return err
		}
		return item.Value(func(val []byte) error {
			return json.Unmarshal(val, &retrieved)
		})
	})
	if err != nil {
		t.Fatalf("Failed to retrieve profile: %v", err)
	}

	if retrieved.Profile.Bodyweight != profile.Bodyweight {
		t.Errorf("Expected bodyweight %f, got %f", profile.Bodyweight, retrieved.Profile.Bodyweight)
	}
	if retrieved.Profile.Goal != profile.Goal {
		t.Errorf("Expected goal %s, got %s", profile.Goal, retrieved.Profile.Goal)
	}
}

// Test UserProfile storage - Read operation
func TestUserProfileRead(t *testing.T) {
	tempDir := t.TempDir()

	opts := badger.DefaultOptions(tempDir)
	opts.Logger = nil

	db, err := badger.Open(opts)
	if err != nil {
		t.Fatalf("Failed to open BadgerDB: %v", err)
	}
	defer db.Close()

	// Create and store a profile
	profile := UserProfile{
		Bodyweight:    200.0,
		ActivityLevel: "active",
		Goal:          "gain",
		MealsPerDay:   5,
	}

	profileID := "user_test_read"
	storedProfile := StoredUserProfile{
		ID:        profileID,
		Profile:   profile,
		CreatedAt: time.Now(),
		UpdatedAt: time.Now(),
	}

	data, _ := json.Marshal(storedProfile)

	err = db.Update(func(txn *badger.Txn) error {
		return txn.Set([]byte(UserProfilePrefix+profileID), data)
	})
	if err != nil {
		t.Fatalf("Failed to store profile: %v", err)
	}

	// Read the profile back
	var retrieved StoredUserProfile
	err = db.View(func(txn *badger.Txn) error {
		item, err := txn.Get([]byte(UserProfilePrefix + profileID))
		if err != nil {
			return err
		}
		return item.Value(func(val []byte) error {
			return json.Unmarshal(val, &retrieved)
		})
	})
	if err != nil {
		t.Fatalf("Failed to read profile: %v", err)
	}

	if retrieved.ID != profileID {
		t.Errorf("Expected ID %s, got %s", profileID, retrieved.ID)
	}
	if retrieved.Profile.ActivityLevel != "active" {
		t.Errorf("Expected activity level 'active', got %s", retrieved.Profile.ActivityLevel)
	}
}

// Test UserProfile storage - Update operation
func TestUserProfileUpdate(t *testing.T) {
	tempDir := t.TempDir()

	opts := badger.DefaultOptions(tempDir)
	opts.Logger = nil

	db, err := badger.Open(opts)
	if err != nil {
		t.Fatalf("Failed to open BadgerDB: %v", err)
	}
	defer db.Close()

	// Create initial profile
	profile := UserProfile{
		Bodyweight:    180.0,
		ActivityLevel: "sedentary",
		Goal:          "lose",
		MealsPerDay:   3,
	}

	profileID := "user_test_update"
	createdAt := time.Now()
	storedProfile := StoredUserProfile{
		ID:        profileID,
		Profile:   profile,
		CreatedAt: createdAt,
		UpdatedAt: createdAt,
	}

	data, _ := json.Marshal(storedProfile)

	err = db.Update(func(txn *badger.Txn) error {
		return txn.Set([]byte(UserProfilePrefix+profileID), data)
	})
	if err != nil {
		t.Fatalf("Failed to store profile: %v", err)
	}

	// Wait a moment to ensure time difference
	time.Sleep(10 * time.Millisecond)

	// Update the profile
	profile.Bodyweight = 175.0
	profile.Goal = "maintain"
	storedProfile.Profile = profile
	storedProfile.UpdatedAt = time.Now()

	data, _ = json.Marshal(storedProfile)

	err = db.Update(func(txn *badger.Txn) error {
		return txn.Set([]byte(UserProfilePrefix+profileID), data)
	})
	if err != nil {
		t.Fatalf("Failed to update profile: %v", err)
	}

	// Verify the update
	var retrieved StoredUserProfile
	err = db.View(func(txn *badger.Txn) error {
		item, err := txn.Get([]byte(UserProfilePrefix + profileID))
		if err != nil {
			return err
		}
		return item.Value(func(val []byte) error {
			return json.Unmarshal(val, &retrieved)
		})
	})
	if err != nil {
		t.Fatalf("Failed to read updated profile: %v", err)
	}

	if retrieved.Profile.Bodyweight != 175.0 {
		t.Errorf("Expected bodyweight 175.0, got %f", retrieved.Profile.Bodyweight)
	}
	if retrieved.Profile.Goal != "maintain" {
		t.Errorf("Expected goal 'maintain', got %s", retrieved.Profile.Goal)
	}
	if !retrieved.UpdatedAt.After(retrieved.CreatedAt) {
		t.Error("UpdatedAt should be after CreatedAt")
	}
}

// Test UserProfile storage - Delete operation
func TestUserProfileDelete(t *testing.T) {
	tempDir := t.TempDir()

	opts := badger.DefaultOptions(tempDir)
	opts.Logger = nil

	db, err := badger.Open(opts)
	if err != nil {
		t.Fatalf("Failed to open BadgerDB: %v", err)
	}
	defer db.Close()

	// Create and store a profile
	profile := UserProfile{
		Bodyweight:    160.0,
		ActivityLevel: "moderate",
		Goal:          "maintain",
		MealsPerDay:   4,
	}

	profileID := "user_test_delete"
	storedProfile := StoredUserProfile{
		ID:        profileID,
		Profile:   profile,
		CreatedAt: time.Now(),
		UpdatedAt: time.Now(),
	}

	data, _ := json.Marshal(storedProfile)

	err = db.Update(func(txn *badger.Txn) error {
		return txn.Set([]byte(UserProfilePrefix+profileID), data)
	})
	if err != nil {
		t.Fatalf("Failed to store profile: %v", err)
	}

	// Delete the profile
	err = db.Update(func(txn *badger.Txn) error {
		return txn.Delete([]byte(UserProfilePrefix + profileID))
	})
	if err != nil {
		t.Fatalf("Failed to delete profile: %v", err)
	}

	// Verify deletion
	err = db.View(func(txn *badger.Txn) error {
		_, err := txn.Get([]byte(UserProfilePrefix + profileID))
		return err
	})
	if err != badger.ErrKeyNotFound {
		t.Errorf("Expected ErrKeyNotFound after deletion, got %v", err)
	}
}

// Test listing all UserProfiles
func TestUserProfileListAll(t *testing.T) {
	tempDir := t.TempDir()

	opts := badger.DefaultOptions(tempDir)
	opts.Logger = nil

	db, err := badger.Open(opts)
	if err != nil {
		t.Fatalf("Failed to open BadgerDB: %v", err)
	}
	defer db.Close()

	// Create multiple profiles
	profiles := []UserProfile{
		{Bodyweight: 150.0, ActivityLevel: "sedentary", Goal: "lose", MealsPerDay: 3},
		{Bodyweight: 180.0, ActivityLevel: "moderate", Goal: "maintain", MealsPerDay: 4},
		{Bodyweight: 200.0, ActivityLevel: "active", Goal: "gain", MealsPerDay: 5},
	}

	// Store all profiles
	err = db.Update(func(txn *badger.Txn) error {
		for i, profile := range profiles {
			profileID := "user_list_" + strconv.Itoa(i+1)
			storedProfile := StoredUserProfile{
				ID:        profileID,
				Profile:   profile,
				CreatedAt: time.Now(),
				UpdatedAt: time.Now(),
			}
			data, _ := json.Marshal(storedProfile)
			if err := txn.Set([]byte(UserProfilePrefix+profileID), data); err != nil {
				return err
			}
		}
		return nil
	})
	if err != nil {
		t.Fatalf("Failed to store profiles: %v", err)
	}

	// List all profiles
	var retrievedProfiles []StoredUserProfile
	err = db.View(func(txn *badger.Txn) error {
		it := txn.NewIterator(badger.DefaultIteratorOptions)
		defer it.Close()

		prefix := []byte(UserProfilePrefix)
		for it.Seek(prefix); it.ValidForPrefix(prefix); it.Next() {
			item := it.Item()
			err := item.Value(func(val []byte) error {
				var stored StoredUserProfile
				if err := json.Unmarshal(val, &stored); err != nil {
					return err
				}
				retrievedProfiles = append(retrievedProfiles, stored)
				return nil
			})
			if err != nil {
				return err
			}
		}
		return nil
	})
	if err != nil {
		t.Fatalf("Failed to list profiles: %v", err)
	}

	if len(retrievedProfiles) != 3 {
		t.Errorf("Expected 3 profiles, got %d", len(retrievedProfiles))
	}
}
