package ncp

import (
	"context"
	"fmt"
	"strings"
	"time"

	"github.com/dgraph-io/badger/v4"
)

// SyncNutritionData fetches nutrition data from Cronometer and stores it in BadgerDB
func SyncNutritionData(db *badger.DB, config CronometerConfig, startDate, endDate time.Time) error {
	// Validate config
	if err := config.Validate(); err != nil {
		return fmt.Errorf("invalid config: %w", err)
	}

	// Create client and use the generic sync function
	client := NewCronometerClient(config)
	return SyncNutritionDataWithClient(db, client, startDate, endDate)
}

// SyncNutritionDataWithClient syncs nutrition data using the provided client
// This is separated to allow for mocking in tests
func SyncNutritionDataWithClient(db *badger.DB, client NutritionClient, startDate, endDate time.Time) error {
	ctx := context.Background()

	// Login
	if err := client.Login(ctx); err != nil {
		return fmt.Errorf("login failed: %w", err)
	}
	defer client.Logout(ctx)

	// Fetch data for each day in range
	current := startDate
	for !current.After(endDate) {
		data, err := client.FetchDailyNutrition(ctx, current)
		if err != nil {
			return fmt.Errorf("failed to fetch data for %s: %w", current.Format("2006-01-02"), err)
		}

		state := NutritionState{
			Date:     current,
			Consumed: *data,
			SyncedAt: time.Now(),
		}

		if err := StoreNutritionState(db, state); err != nil {
			return fmt.Errorf("failed to store data for %s: %w", current.Format("2006-01-02"), err)
		}

		current = current.AddDate(0, 0, 1)
	}

	return nil
}

// FormatStatusOutput generates a human-readable status report
func FormatStatusOutput(result ReconciliationResult) string {
	var sb strings.Builder

	sb.WriteString("═══════════════════════════════════════════════\n")
	sb.WriteString("           NCP NUTRITION STATUS REPORT          \n")
	sb.WriteString("═══════════════════════════════════════════════\n\n")

	// Date
	sb.WriteString(fmt.Sprintf("Date: %s\n\n", result.Date.Format("January 02, 2006")))

	// Goals vs Actual
	sb.WriteString("📊 MACRO COMPARISON\n")
	sb.WriteString("───────────────────────────────────────────────\n")
	sb.WriteString(fmt.Sprintf("           Goal      Actual    Deviation\n"))
	sb.WriteString(fmt.Sprintf("Protein:   %6.1fg   %6.1fg   %+6.1f%%\n",
		result.Goals.DailyProtein, result.AverageConsumed.Protein, result.Deviation.ProteinPct))
	sb.WriteString(fmt.Sprintf("Fat:       %6.1fg   %6.1fg   %+6.1f%%\n",
		result.Goals.DailyFat, result.AverageConsumed.Fat, result.Deviation.FatPct))
	sb.WriteString(fmt.Sprintf("Carbs:     %6.1fg   %6.1fg   %+6.1f%%\n",
		result.Goals.DailyCarbs, result.AverageConsumed.Carbs, result.Deviation.CarbsPct))
	sb.WriteString(fmt.Sprintf("Calories:  %6.0f    %6.0f    %+6.1f%%\n\n",
		result.Goals.DailyCalories, result.AverageConsumed.Calories, result.Deviation.CaloriesPct))

	// Tolerance status
	if result.WithinTolerance {
		sb.WriteString("✓ STATUS: Within tolerance - On track!\n\n")
	} else {
		sb.WriteString("⚠ STATUS: Outside tolerance - Adjustments recommended\n\n")

		// Suggestions
		if len(result.Plan.Suggestions) > 0 {
			sb.WriteString("📋 RECOMMENDED RECIPES\n")
			sb.WriteString("───────────────────────────────────────────────\n")
			for i, suggestion := range result.Plan.Suggestions {
				sb.WriteString(fmt.Sprintf("%d. %s (score: %.2f)\n", i+1, suggestion.RecipeName, suggestion.Score))
				sb.WriteString(fmt.Sprintf("   %s\n", suggestion.Reason))
			}
		}
	}

	sb.WriteString("\n═══════════════════════════════════════════════\n")

	return sb.String()
}

// FormatReconcileOutput generates output for the reconcile command
func FormatReconcileOutput(result ReconciliationResult) string {
	output := FormatStatusOutput(result)

	var sb strings.Builder
	sb.WriteString(output)

	if !result.WithinTolerance && len(result.Plan.Suggestions) > 0 {
		sb.WriteString("\n🍽️  ADJUSTMENT PLAN\n")
		sb.WriteString("───────────────────────────────────────────────\n")
		sb.WriteString("Add the following meals to get back on track:\n\n")

		for _, suggestion := range result.Plan.Suggestions {
			sb.WriteString(fmt.Sprintf("  • %s\n", suggestion.RecipeName))
		}
		sb.WriteString("\n")
	}

	return sb.String()
}
