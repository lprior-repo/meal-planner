package ncp

import (
	"testing"

	"github.com/jrmycanady/gocronometer"
)

// TestGoCronometerImport verifies the gocronometer dependency is available
func TestGoCronometerImport(t *testing.T) {
	// Verify we can reference the gocronometer package
	// This is a compile-time check that the dependency is properly installed
	var _ *gocronometer.Client
	t.Log("gocronometer package imported successfully")
}
