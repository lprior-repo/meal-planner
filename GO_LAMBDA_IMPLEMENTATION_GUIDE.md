# Go Lambda Implementation Guide

This document provides detailed patterns and guidelines for implementing Go lambdas that will be orchestrated by Windmill.

## General Go Lambda Patterns

### 1. Input/Output Structure
All Go lambdas should follow a consistent input/output pattern:

```go
// Input struct
type Input struct {
    // Define all required parameters
    Param1 string `json:"param1"`
    Param2 int    `json:"param2"`
    // ... other parameters
}

// Output struct  
type Output struct {
    // Define all return values
    Success bool `json:"success"`
    Result  interface{} `json:"result,omitempty"`
    Error   string `json:"error,omitempty"`
}
```

### 2. Error Handling
Use standard Go error handling with custom error types:

```go
type LambdaError struct {
    Code    string `json:"code"`
    Message string `json:"message"`
    Details string `json:"details,omitempty"`
}

func (e *LambdaError) Error() string {
    return fmt.Sprintf("%s: %s", e.Code, e.Message)
}

// Return errors as:
return &LambdaError{
    Code:    "VALIDATION_ERROR",
    Message: "Invalid input parameter",
    Details: "Param1 must be non-empty",
}
```

### 3. Data Format Consistency
Maintain consistency with existing Gleam data structures:

```go
// Example nutrition data structure
type NutritionData struct {
    Protein float64 `json:"protein"`
    Fat     float64 `json:"fat"`
    Carbs   float64 `json:"carbs"`
    Calories float64 `json:"calories"`
}
```

## Component-Specific Implementation Patterns

### 1. Nutrition Calculation Engine (NCP)
**Pattern**: Pure mathematical functions with clear input/output contracts

```go
// Example: calculate_deviation
type DeviationInput struct {
    Target   NutritionData `json:"target"`
    Actual   NutritionData `json:"actual"`
    Tolerance float64 `json:"tolerance"`
}

type DeviationOutput struct {
    Deviation float64 `json:"deviation"`
    WithinTolerance bool `json:"within_tolerance"`
    MaxDeviation float64 `json:"max_deviation"`
}

func CalculateDeviation(input *DeviationInput) (*DeviationOutput, error) {
    // Implementation here
    return &DeviationOutput{
        Deviation: deviation,
        WithinTolerance: withinTolerance,
        MaxDeviation: maxDeviation,
    }, nil
}
```

### 2. Advisor Recommendation Engine
**Pattern**: Logic processing with trend analysis

```go
type TrendAnalysisInput struct {
    HistoricalData []NutritionData `json:"historical_data"`
    TargetNutrition  NutritionData `json:"target_nutrition"`
    TimeRange        string `json:"time_range"`
}

type TrendAnalysisOutput struct {
    TrendDirection string `json:"trend_direction"`
    ConsistencyRate float64 `json:"consistency_rate"`
    ComplianceScore float64 `json:"compliance_score"`
    Recommendations []string `json:"recommendations"`
}

func AnalyzeNutritionTrends(input *TrendAnalysisInput) (*TrendAnalysisOutput, error) {
    // Implementation here
    return &TrendAnalysisOutput{
        TrendDirection: direction,
        ConsistencyRate: rate,
        ComplianceScore: score,
        Recommendations: recommendations,
    }, nil
}
```

### 3. Grocery List Generation
**Pattern**: Data aggregation and transformation

```go
type GroceryListInput struct {
    Ingredients []Ingredient `json:"ingredients"`
    MealPlan  MealPlan     `json:"meal_plan"`
    Preferences Preferences `json:"preferences"`
}

type GroceryListOutput struct {
    Items []GroceryItem `json:"items"`
    Totals NutritionData `json:"totals"`
    Categories map[string][]GroceryItem `json:"categories"`
}

func GenerateGroceryList(input *GroceryListInput) (*GroceryListOutput, error) {
    // Implementation here
    return &GroceryListOutput{
        Items: items,
        Totals: totals,
        Categories: categories,
    }, nil
}
```

### 4. CLI Command Processing
**Pattern**: Input/output handling with validation

```go
type ReportGenerationInput struct {
    ReportType string `json:"report_type"`
    DateRange  DateRange `json:"date_range"`
    Format   string `json:"format"`
}

type ReportGenerationOutput struct {
    ReportData string `json:"report_data"`
    FileName   string `json:"file_name"`
    GeneratedAt  time.Time `json:"generated_at"`
}

func GenerateReport(input *ReportGenerationInput) (*ReportGenerationOutput, error) {
    // Implementation here
    return &ReportGenerationOutput{
        ReportData: data,
        FileName: fileName,
        GeneratedAt: time.Now(),
    }, nil
}
```

## Best Practices

### 1. Statelessness
Go lambdas must be stateless:
- No global variables
- No file system state
- No database connections (use Windmill resources)

### 2. Error Propagation
- Use consistent error codes
- Include detailed error messages
- Return errors as early as possible

### 3. Performance Considerations
- Optimize for fast execution
- Avoid unnecessary computations
- Use efficient data structures

### 4. Testing
- Write unit tests for all lambdas
- Test edge cases and error conditions
- Use fixtures for input/output validation

## Deployment Considerations

### 1. Environment Variables
Use Windmill's variable management:
```go
// Access configuration
config := &Config{
    DatabaseURL: os.Getenv("DATABASE_URL"),
    LogLevel:  os.Getenv("LOG_LEVEL"),
}
```

### 2. Logging
Use structured logging:
```go
import "go.uber.org/zap"

logger, _ := zap.NewDevelopment()
logger.Info("Processing nutrition data",
    zap.String("trace_id", traceID),
    zap.Int("item_count", len(items)),
)
```

### 3. Monitoring
Implement basic metrics:
```go
// Example metrics
metrics := map[string]interface{}{
    "execution_time": time.Since(start).Seconds(),
    "input_size": len(inputBytes),
    "output_size": len(outputBytes),
}
```

## Migration Checklist

- [ ] Define input/output structures
- [ ] Implement core business logic
- [ ] Add comprehensive error handling
- [ ] Write unit tests
- [ ] Validate data format consistency
- [ ] Test with existing test fixtures
- [ ] Set up Windmill deployment configuration
- [ ] Document API contracts