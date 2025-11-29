package ncp

import (
	"context"
	"errors"
	"os"
	"testing"
	"time"

	"github.com/dgraph-io/badger/v4"
)

func TestSyncCommand_StoresData(t *testing.T) {
	// Skip if no credentials (integration test)
	if os.Getenv("CRONOMETER_USERNAME") == "" {
		t.Skip("Skipping integration test: CRONOMETER_EMAIL not set")
	}

	db, cleanup := setupCLITestDB(t)
	defer cleanup()

	config := CronometerConfig{
		Username:    os.Getenv("CRONOMETER_USERNAME"),
		Password: os.Getenv("CRONOMETER_PASSWORD"),
	}

	// Run sync for today
	today := time.Now()
	err := SyncNutritionData(db, config, today, today)
	if err != nil {
		t.Fatalf("Sync failed: %v", err)
	}

	// Verify data was stored
	state, err := GetNutritionState(db, today)
	if err != nil {
		t.Fatalf("Failed to retrieve synced data: %v", err)
	}

	if state.Consumed.Calories == 0 && state.Consumed.Protein == 0 {
		t.Log("Warning: synced data has zero values (may be expected if no food logged today)")
	}
}

func TestSyncNutritionData_InvalidCredentials(t *testing.T) {
	db, cleanup := setupCLITestDB(t)
	defer cleanup()

	config := CronometerConfig{
		Username:    "invalid@example.com",
		Password: "wrongpassword",
	}

	today := time.Now()
	err := SyncNutritionData(db, config, today, today)

	// Should fail with invalid credentials
	if err == nil {
		t.Error("Expected error for invalid credentials, got nil")
	}
}


// MockNutritionClient implements NutritionClient for testing
type MockNutritionClient struct {
	loginError     error
	logoutError    error
	fetchError     error
	nutritionData  *NutritionData
	isLoggedIn     bool
	loginCalled    bool
	logoutCalled   bool
	fetchCallCount int
}

func (m *MockNutritionClient) Login(ctx context.Context) error {
	m.loginCalled = true
	if m.loginError != nil {
		return m.loginError
	}
	m.isLoggedIn = true
	return nil
}

func (m *MockNutritionClient) Logout(ctx context.Context) error {
	m.logoutCalled = true
	if m.logoutError != nil {
		return m.logoutError
	}
	m.isLoggedIn = false
	return nil
}

func (m *MockNutritionClient) IsLoggedIn() bool {
	return m.isLoggedIn
}

func (m *MockNutritionClient) FetchDailyNutrition(ctx context.Context, date time.Time) (*NutritionData, error) {
	m.fetchCallCount++
	if m.fetchError != nil {
		return nil, m.fetchError
	}
	if m.nutritionData != nil {
		return m.nutritionData, nil
	}
	return &NutritionData{
		Date:     date,
		Protein:  150.0,
		Fat:      50.0,
		Carbs:    200.0,
		Calories: 2000.0,
	}, nil
}

func TestSyncNutritionDataWithClient_Success(t *testing.T) {
	db, cleanup := setupCLITestDB(t)
	defer cleanup()

	mockClient := &MockNutritionClient{
		nutritionData: &NutritionData{
			Protein:  160.0,
			Fat:      55.0,
			Carbs:    220.0,
			Calories: 2100.0,
		},
	}

	startDate := time.Date(2024, 11, 28, 0, 0, 0, 0, time.UTC)
	endDate := time.Date(2024, 11, 29, 0, 0, 0, 0, time.UTC)

	err := SyncNutritionDataWithClient(db, mockClient, startDate, endDate)
	if err != nil {
		t.Fatalf("Expected no error, got %v", err)
	}

	// Verify login was called
	if !mockClient.loginCalled {
		t.Error("Expected login to be called")
	}

	// Verify logout was called (via defer)
	if !mockClient.logoutCalled {
		t.Error("Expected logout to be called")
	}

	// Verify fetch was called for each day
	if mockClient.fetchCallCount != 2 {
		t.Errorf("Expected 2 fetch calls, got %d", mockClient.fetchCallCount)
	}

	// Verify data was stored
	state, err := GetNutritionState(db, startDate)
	if err != nil {
		t.Fatalf("Failed to get stored state: %v", err)
	}
	if state.Consumed.Protein != 160.0 {
		t.Errorf("Expected protein 160.0, got %f", state.Consumed.Protein)
	}
}

func TestSyncNutritionDataWithClient_LoginError(t *testing.T) {
	db, cleanup := setupCLITestDB(t)
	defer cleanup()

	mockClient := &MockNutritionClient{
		loginError: errors.New("authentication failed"),
	}

	startDate := time.Date(2024, 11, 29, 0, 0, 0, 0, time.UTC)

	err := SyncNutritionDataWithClient(db, mockClient, startDate, startDate)
	if err == nil {
		t.Error("Expected login error, got nil")
	}
	if !containsString(err.Error(), "login failed") {
		t.Errorf("Expected 'login failed' in error, got %s", err.Error())
	}
}

func TestSyncNutritionDataWithClient_FetchError(t *testing.T) {
	db, cleanup := setupCLITestDB(t)
	defer cleanup()

	mockClient := &MockNutritionClient{
		fetchError: errors.New("API rate limit exceeded"),
	}

	startDate := time.Date(2024, 11, 29, 0, 0, 0, 0, time.UTC)

	err := SyncNutritionDataWithClient(db, mockClient, startDate, startDate)
	if err == nil {
		t.Error("Expected fetch error, got nil")
	}
	if !containsString(err.Error(), "failed to fetch data") {
		t.Errorf("Expected 'failed to fetch data' in error, got %s", err.Error())
	}
}

func TestSyncNutritionData_InvalidConfig(t *testing.T) {
	db, cleanup := setupCLITestDB(t)
	defer cleanup()

	// Empty config should fail validation
	config := CronometerConfig{}

	startDate := time.Date(2024, 11, 29, 0, 0, 0, 0, time.UTC)

	err := SyncNutritionData(db, config, startDate, startDate)
	if err == nil {
		t.Error("Expected validation error, got nil")
	}
	if !containsString(err.Error(), "invalid config") {
		t.Errorf("Expected 'invalid config' in error, got %s", err.Error())
	}
}


func TestSyncNutritionDataWithClient_StoreError(t *testing.T) {
	db, cleanup := setupCLITestDB(t)
	// Close the database early to cause a store error
	cleanup()

	mockClient := &MockNutritionClient{
		nutritionData: &NutritionData{
			Protein: 160.0,
		},
	}

	startDate := time.Date(2024, 11, 29, 0, 0, 0, 0, time.UTC)

	err := SyncNutritionDataWithClient(db, mockClient, startDate, startDate)
	if err == nil {
		t.Error("Expected store error, got nil")
	}
	if !containsString(err.Error(), "failed to store data") {
		t.Errorf("Expected 'failed to store data' in error, got %s", err.Error())
	}
}

func TestFormatStatusOutput_WithinTolerance(t *testing.T) {
	result := ReconciliationResult{
		Date: time.Date(2024, 11, 29, 0, 0, 0, 0, time.UTC),
		AverageConsumed: NutritionData{
			Protein:  175.0,
			Fat:      58.0,
			Carbs:    245.0,
			Calories: 2450.0,
		},
		Goals: NutritionGoals{
			DailyProtein:  180.0,
			DailyFat:      60.0,
			DailyCarbs:    250.0,
			DailyCalories: 2500.0,
		},
		Deviation: DeviationResult{
			ProteinPct:  -2.8,
			FatPct:      -3.3,
			CarbsPct:    -2.0,
			CaloriesPct: -2.0,
		},
		WithinTolerance: true,
	}

	output := FormatStatusOutput(result)

	if output == "" {
		t.Error("Expected non-empty output")
	}

	// Should contain key information
	if !containsString(output, "Within tolerance") && !containsString(output, "✓") {
		t.Error("Expected output to indicate within tolerance")
	}
}

func TestFormatStatusOutput_OutsideTolerance(t *testing.T) {
	result := ReconciliationResult{
		Deviation: DeviationResult{
			ProteinPct: -25.0,
			FatPct:     10.0,
			CarbsPct:   -15.0,
		},
		WithinTolerance: false,
		Plan: AdjustmentPlan{
			Suggestions: []RecipeSuggestion{
				{RecipeName: "Grilled Chicken", Score: 0.85},
			},
		},
	}

	output := FormatStatusOutput(result)

	if !containsString(output, "Grilled Chicken") {
		t.Error("Expected output to contain recipe suggestions")
	}
}


func TestFormatReconcileOutput_WithSuggestions(t *testing.T) {
	result := ReconciliationResult{
		Deviation: DeviationResult{
			ProteinPct: -25.0,
			FatPct:     10.0,
			CarbsPct:   -15.0,
		},
		WithinTolerance: false,
		Plan: AdjustmentPlan{
			Suggestions: []RecipeSuggestion{
				{RecipeName: "Grilled Chicken", Score: 0.85},
				{RecipeName: "Salmon Bowl", Score: 0.75},
			},
		},
	}

	output := FormatReconcileOutput(result)

	// Should contain adjustment plan section
	if !containsString(output, "ADJUSTMENT PLAN") {
		t.Error("Expected output to contain ADJUSTMENT PLAN")
	}

	// Should contain all recipe suggestions
	if !containsString(output, "Grilled Chicken") {
		t.Error("Expected output to contain Grilled Chicken")
	}
	if !containsString(output, "Salmon Bowl") {
		t.Error("Expected output to contain Salmon Bowl")
	}

	// Should contain the bullet point format
	if !containsString(output, "•") {
		t.Error("Expected output to contain bullet points")
	}
}

func TestFormatReconcileOutput_WithinTolerance(t *testing.T) {
	result := ReconciliationResult{
		WithinTolerance: true,
		Plan:            AdjustmentPlan{},
	}

	output := FormatReconcileOutput(result)

	// Should NOT contain adjustment plan when within tolerance
	if containsString(output, "ADJUSTMENT PLAN") {
		t.Error("Expected no ADJUSTMENT PLAN when within tolerance")
	}
}

func TestFormatReconcileOutput_NoSuggestions(t *testing.T) {
	result := ReconciliationResult{
		WithinTolerance: false,
		Plan:            AdjustmentPlan{Suggestions: []RecipeSuggestion{}},
	}

	output := FormatReconcileOutput(result)

	// Should NOT contain adjustment plan when no suggestions
	if containsString(output, "ADJUSTMENT PLAN") {
		t.Error("Expected no ADJUSTMENT PLAN with empty suggestions")
	}
}

// Helper to set up test BadgerDB
func setupCLITestDB(t *testing.T) (*badger.DB, func()) {
	t.Helper()

	tmpDir, err := os.MkdirTemp("", "ncp_cli_test_*")
	if err != nil {
		t.Fatalf("Failed to create temp dir: %v", err)
	}

	opts := badger.DefaultOptions(tmpDir)
	opts.Logger = nil

	db, err := badger.Open(opts)
	if err != nil {
		os.RemoveAll(tmpDir)
		t.Fatalf("Failed to open test DB: %v", err)
	}

	cleanup := func() {
		db.Close()
		os.RemoveAll(tmpDir)
	}

	return db, cleanup
}

func containsString(s, substr string) bool {
	return len(s) >= len(substr) && (s == substr || len(s) > 0 && containsStringHelper(s, substr))
}

func containsStringHelper(s, substr string) bool {
	for i := 0; i <= len(s)-len(substr); i++ {
		if s[i:i+len(substr)] == substr {
			return true
		}
	}
	return false
}
