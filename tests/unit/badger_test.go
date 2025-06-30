package unit

import (
	"strings"
	"testing"

	"github.com/dgraph-io/badger/v4"
)

// Test BadgerDB basic operations
func TestBadgerDB(t *testing.T) {
	// Create a temporary directory for testing
	tempDir := t.TempDir()
	
	// Test database initialization
	opts := badger.DefaultOptions(tempDir)
	opts.Logger = nil
	
	db, err := badger.Open(opts)
	if err != nil {
		t.Fatalf("Failed to open BadgerDB: %v", err)
	}
	defer db.Close()
	
	// Test basic read/write operations
	key := []byte("test_key")
	value := []byte("test_value")
	
	// Write data
	err = db.Update(func(txn *badger.Txn) error {
		return txn.Set(key, value)
	})
	if err != nil {
		t.Fatalf("Failed to write to BadgerDB: %v", err)
	}
	
	// Read data
	var retrievedValue []byte
	err = db.View(func(txn *badger.Txn) error {
		item, err := txn.Get(key)
		if err != nil {
			return err
		}
		
		return item.Value(func(val []byte) error {
			retrievedValue = append([]byte{}, val...)
			return nil
		})
	})
	if err != nil {
		t.Fatalf("Failed to read from BadgerDB: %v", err)
	}
	
	// Verify data
	if string(retrievedValue) != string(value) {
		t.Errorf("Expected %s, got %s", string(value), string(retrievedValue))
	}
}

// Test BadgerDB with prefix iteration
func TestBadgerDBPrefixIteration(t *testing.T) {
	// Create a temporary directory for testing
	tempDir := t.TempDir()
	
	// Test database initialization
	opts := badger.DefaultOptions(tempDir)
	opts.Logger = nil
	
	db, err := badger.Open(opts)
	if err != nil {
		t.Fatalf("Failed to open BadgerDB: %v", err)
	}
	defer db.Close()
	
	// Insert test data with prefix
	prefix := "recipe:"
	testData := map[string]string{
		"recipe:1": "Recipe 1 Data",
		"recipe:2": "Recipe 2 Data",
		"recipe:3": "Recipe 3 Data",
		"other:1":  "Other Data",
	}
	
	// Write test data
	err = db.Update(func(txn *badger.Txn) error {
		for key, value := range testData {
			if err := txn.Set([]byte(key), []byte(value)); err != nil {
				return err
			}
		}
		return nil
	})
	if err != nil {
		t.Fatalf("Failed to write test data: %v", err)
	}
	
	// Test prefix iteration
	var foundKeys []string
	err = db.View(func(txn *badger.Txn) error {
		opts := badger.DefaultIteratorOptions
		it := txn.NewIterator(opts)
		defer it.Close()
		
		prefixBytes := []byte(prefix)
		for it.Seek(prefixBytes); it.ValidForPrefix(prefixBytes); it.Next() {
			item := it.Item()
			foundKeys = append(foundKeys, string(item.Key()))
		}
		return nil
	})
	if err != nil {
		t.Fatalf("Failed to iterate with prefix: %v", err)
	}
	
	// Verify we found the correct number of keys with the prefix
	expectedCount := 3
	if len(foundKeys) != expectedCount {
		t.Errorf("Expected %d keys with prefix, got %d", expectedCount, len(foundKeys))
	}
	
	// Verify all found keys have the correct prefix
	for _, key := range foundKeys {
		if !strings.HasPrefix(key, prefix) {
			t.Errorf("Key %s does not have expected prefix %s", key, prefix)
		}
	}
}