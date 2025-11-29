package ncp

import (
	"context"
	"fmt"

	"github.com/jrmycanady/gocronometer"
)

// CronometerClient wraps gocronometer.Client with our config
type CronometerClient struct {
	config   CronometerConfig
	client   *gocronometer.Client
	loggedIn bool
}

// NewCronometerClient creates a new Cronometer client
func NewCronometerClient(config CronometerConfig) *CronometerClient {
	return &CronometerClient{
		config: config,
		client: gocronometer.NewClient(nil),
	}
}

// Login authenticates with Cronometer using the configured credentials
func (c *CronometerClient) Login(ctx context.Context) error {
	if err := c.config.Validate(); err != nil {
		return fmt.Errorf("invalid config: %w", err)
	}

	err := c.client.Login(ctx, c.config.Username, c.config.Password)
	if err != nil {
		return fmt.Errorf("cronometer login failed: %w", err)
	}

	c.loggedIn = true
	return nil
}

// IsLoggedIn returns whether the client is authenticated
func (c *CronometerClient) IsLoggedIn() bool {
	return c.loggedIn
}

// Logout ends the Cronometer session
func (c *CronometerClient) Logout(ctx context.Context) error {
	if !c.loggedIn {
		return nil
	}
	err := c.client.Logout(ctx)
	if err != nil {
		return fmt.Errorf("cronometer logout failed: %w", err)
	}
	c.loggedIn = false
	return nil
}
