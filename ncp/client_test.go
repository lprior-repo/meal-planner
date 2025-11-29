package ncp

import (
	"context"
	"os"
	"testing"
	"time"
)

func TestNewCronometerClient(t *testing.T) {
	config := CronometerConfig{
		Username: "user@example.com",
		Password: "password123",
	}

	client := NewCronometerClient(config)

	if client == nil {
		t.Fatal("Expected non-nil client")
	}
	if client.config.Username != config.Username {
		t.Errorf("Expected username %s, got %s", config.Username, client.config.Username)
	}
}

func TestCronometerClient_Login_InvalidCredentials(t *testing.T) {
	// This test uses intentionally invalid credentials
	// In a real test suite, we'd mock the gocronometer client
	config := CronometerConfig{
		Username: "invalid@example.com",
		Password: "invalid",
	}

	client := NewCronometerClient(config)
	err := client.Login(context.Background())

	// We expect an error with invalid credentials
	if err == nil {
		t.Error("Expected error with invalid credentials, got nil")
	}
}

func TestCronometerClient_IsLoggedIn(t *testing.T) {
	config := CronometerConfig{
		Username: "user@example.com",
		Password: "password123",
	}

	client := NewCronometerClient(config)

	// Should not be logged in initially
	if client.IsLoggedIn() {
		t.Error("Expected IsLoggedIn() to be false before login")
	}
}

func TestCronometerClient_FetchDailyNutrition_NotLoggedIn(t *testing.T) {
	config := CronometerConfig{
		Username: "user@example.com",
		Password: "password123",
	}

	client := NewCronometerClient(config)

	// Should error when not logged in
	_, err := client.FetchDailyNutrition(context.Background(), time.Now())
	if err == nil {
		t.Error("Expected error when not logged in, got nil")
	}
}

func TestNutritionData_Struct(t *testing.T) {
	// Test that NutritionData struct has expected fields
	data := NutritionData{
		Date:     time.Now(),
		Protein:  150.5,
		Fat:      65.2,
		Carbs:    200.0,
		Calories: 2000.0,
	}

	if data.Protein != 150.5 {
		t.Errorf("Expected protein 150.5, got %f", data.Protein)
	}
	if data.Fat != 65.2 {
		t.Errorf("Expected fat 65.2, got %f", data.Fat)
	}
	if data.Carbs != 200.0 {
		t.Errorf("Expected carbs 200.0, got %f", data.Carbs)
	}
	if data.Calories != 2000.0 {
		t.Errorf("Expected calories 2000.0, got %f", data.Calories)
	}
}


func TestCronometerClient_Logout_NotLoggedIn(t *testing.T) {
	config := CronometerConfig{
		Username: "test@example.com",
		Password: "password123",
	}
	client := NewCronometerClient(config)

	// Logout when not logged in should succeed without error
	ctx := context.Background()
	err := client.Logout(ctx)
	if err != nil {
		t.Errorf("Expected no error for logout when not logged in, got %v", err)
	}
}


func TestCronometerClient_Login_Success(t *testing.T) {
	// Skip if no credentials (integration test)
	username := os.Getenv("CRONOMETER_USERNAME")
	password := os.Getenv("CRONOMETER_PASSWORD")
	if username == "" || password == "" {
		t.Skip("Skipping integration test: CRONOMETER credentials not set")
	}

	config := CronometerConfig{
		Username: username,
		Password: password,
	}

	client := NewCronometerClient(config)
	ctx := context.Background()

	err := client.Login(ctx)
	if err != nil {
		t.Fatalf("Login failed: %v", err)
	}

	if !client.IsLoggedIn() {
		t.Error("Expected IsLoggedIn() to return true after login")
	}

	// Clean up
	err = client.Logout(ctx)
	if err != nil {
		t.Errorf("Logout failed: %v", err)
	}
}

func TestCronometerClient_FetchDailyNutrition_Success(t *testing.T) {
	// Skip if no credentials (integration test)
	username := os.Getenv("CRONOMETER_USERNAME")
	password := os.Getenv("CRONOMETER_PASSWORD")
	if username == "" || password == "" {
		t.Skip("Skipping integration test: CRONOMETER credentials not set")
	}

	config := CronometerConfig{
		Username: username,
		Password: password,
	}

	client := NewCronometerClient(config)
	ctx := context.Background()

	err := client.Login(ctx)
	if err != nil {
		t.Fatalf("Login failed: %v", err)
	}
	defer client.Logout(ctx)

	// Fetch today's data
	today := time.Now()
	data, err := client.FetchDailyNutrition(ctx, today)
	if err != nil {
		t.Fatalf("FetchDailyNutrition failed: %v", err)
	}

	// Just verify we got data back
	if data == nil {
		t.Error("Expected non-nil nutrition data")
	}
}
