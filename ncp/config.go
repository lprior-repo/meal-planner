package ncp

import (
	"errors"
	"os"
)

// CronometerConfig holds credentials for Cronometer API access
type CronometerConfig struct {
	Username string
	Password string
}

// Validate checks that the config has required fields
func (c CronometerConfig) Validate() error {
	if c.Username == "" {
		return errors.New("cronometer username is required")
	}
	if c.Password == "" {
		return errors.New("cronometer password is required")
	}
	return nil
}

// CronometerConfigFromEnv creates a config from environment variables
func CronometerConfigFromEnv() CronometerConfig {
	return CronometerConfig{
		Username: os.Getenv("CRONOMETER_USERNAME"),
		Password: os.Getenv("CRONOMETER_PASSWORD"),
	}
}
