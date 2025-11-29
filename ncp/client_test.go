package ncp

import (
	"context"
	"testing"
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
