package ncp

import (
	"testing"
)

func TestCronometerConfig_Validate(t *testing.T) {
	tests := []struct {
		name    string
		config  CronometerConfig
		wantErr bool
	}{
		{
			name: "valid config",
			config: CronometerConfig{
				Username: "user@example.com",
				Password: "password123",
			},
			wantErr: false,
		},
		{
			name: "missing username",
			config: CronometerConfig{
				Username: "",
				Password: "password123",
			},
			wantErr: true,
		},
		{
			name: "missing password",
			config: CronometerConfig{
				Username: "user@example.com",
				Password: "",
			},
			wantErr: true,
		},
		{
			name:    "empty config",
			config:  CronometerConfig{},
			wantErr: true,
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			err := tt.config.Validate()
			if (err != nil) != tt.wantErr {
				t.Errorf("CronometerConfig.Validate() error = %v, wantErr %v", err, tt.wantErr)
			}
		})
	}
}

func TestCronometerConfig_FromEnv(t *testing.T) {
	// Save and restore env vars
	t.Setenv("CRONOMETER_USERNAME", "test@example.com")
	t.Setenv("CRONOMETER_PASSWORD", "testpass")

	config := CronometerConfigFromEnv()

	if config.Username != "test@example.com" {
		t.Errorf("Expected username test@example.com, got %s", config.Username)
	}
	if config.Password != "testpass" {
		t.Errorf("Expected password testpass, got %s", config.Password)
	}
}
