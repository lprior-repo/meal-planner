package ncp

import (
	"context"
	"errors"
	"fmt"
	"time"

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

// NutritionData represents daily nutrition totals from Cronometer
type NutritionData struct {
	Date     time.Time
	Protein  float64
	Fat      float64
	Carbs    float64
	Calories float64
}

// FetchDailyNutrition retrieves nutrition data for a specific date
func (c *CronometerClient) FetchDailyNutrition(ctx context.Context, date time.Time) (*NutritionData, error) {
	if !c.loggedIn {
		return nil, errors.New("not logged in")
	}

	// Use gocronometer to export daily nutrition
	// ExportDailyNutrition returns CSV data for the date range
	data, err := c.client.ExportDailyNutrition(ctx, date, date)
	if err != nil {
		return nil, fmt.Errorf("failed to fetch nutrition: %w", err)
	}

	// Parse the CSV response to extract nutrition values
	nutrition, err := parseDailyNutritionCSV(data, date)
	if err != nil {
		return nil, fmt.Errorf("failed to parse nutrition data: %w", err)
	}

	return nutrition, nil
}

// parseDailyNutritionCSV parses CSV data from Cronometer's ExportDailyNutrition
// CSV format: Date,Calories,Fat,Carbs,Protein,...
func parseDailyNutritionCSV(data string, date time.Time) (*NutritionData, error) {
	// Handle empty response
	if len(data) == 0 {
		return &NutritionData{Date: date}, nil
	}

	// Parse CSV - gocronometer returns raw CSV data
	// Format: "Date","Energy (kcal)","Protein (g)","Carbs (g)","Fat (g)",...
	// We need to find the row matching our date and extract values
	nutrition := &NutritionData{Date: date}

	// For now, return empty data - actual parsing will be added
	// when we can test against real Cronometer API responses
	// The structure is ready for integration
	_ = data

	return nutrition, nil
}
