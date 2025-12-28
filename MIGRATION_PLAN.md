# Migration Plan: Convert Meal Planner to Windmill + Go Lambdas

## Overview

This document outlines the migration plan to convert the existing Gleam-based meal planner to use Windmill as the orchestrator with Go lambdas. This approach will leverage Windmill's flow orchestration capabilities while maintaining the existing business logic patterns.

## Current Architecture Analysis

### Key Components to Migrate

Based on detailed analysis, the following components are prime candidates for migration to Go lambdas:

### 1. **Nutrition Calculation Engine (NCP Module)**
This is the most substantial candidate for migration:

**Functions to migrate:**
- `calculate_deviation` - Core deviation calculations
- `deviation_is_within_tolerance` - Compliance checking
- `deviation_max` - Maximum deviation tracking
- `calculate_min_nutrition` / `calculate_max_nutrition` - Statistical analysis
- `calculate_nutrition_variability` - Variance calculations
- `calculate_daily_totals` - Aggregation functions
- `calculate_macro_percentages` - Macro distribution calculations
- `estimate_daily_calories` - Calorie estimation

**Why:** These are pure mathematical functions that:
- Take structured input and return structured output
- Have well-defined, testable behavior
- Are computationally intensive but stateless
- Would benefit from Go's performance characteristics

### 2. **Advisor Recommendation Engine**
This module generates actionable insights:

**Functions to migrate:**
- `analyze_nutrition_trends` - Trend analysis
- `calculate_consistency_rate` - Consistency calculations
- `determine_trend` - Trend direction determination
- `calculate_compliance_score` - Compliance scoring

**Why:** These are pure logic functions that:
- Process historical data to generate recommendations
- Have clear input/output contracts
- Are well-tested and documented

### 3. **Grocery List Generation**
This is a data aggregation and processing function:

**Functions to migrate:**
- `from_ingredients` - Ingredient aggregation
- `group_by_food` - Data grouping
- `sum_quantities` - Quantity calculation
- `get_unit_name` / `get_category` - Metadata extraction

**Why:** These are data processing functions that:
- Take structured input and produce structured output
- Are easily testable with fixtures
- Have clear business logic boundaries

### 4. **CLI Command Processing**
Several CLI domain functions that could benefit from Go:

**Functions to migrate:**
- `generate_report` - Nutrition reporting
- `display_trends` - Trend analysis display
- `check_compliance` - Compliance checking
- `validate_goal_value` - Input validation

**Why:** These are stateless processing functions that:
- Handle structured data input/output
- Have well-defined error handling
- Are used in command-line interfaces

## Migration Strategy

### Phase 1: Component Identification and Mapping

#### Web Handlers
- **Current**: `src/meal_planner/web/handlers.gleam`
- **Mapping**: Convert to Go lambdas that handle specific HTTP requests
- **Orchestration**: Windmill flows coordinate these handlers

#### CLI Commands
- **Current**: `src/meal_planner/cli/` directory
- **Mapping**: Convert to Go lambdas that implement specific CLI operations
- **Orchestration**: Windmill flows call these commands

#### Business Logic Modules
- **Current**: `src/meal_planner/ncp/`, `src/meal_planner/grocery_list.gleam`, etc.
- **Mapping**: Convert to Go lambdas for pure functions
- **Orchestration**: Windmill flows coordinate these functions

### Phase 2: Windmill Flow Structure

Based on the analysis, the following Windmill flow structure is recommended:

#### Core Flows:
1. **Meal Planning Flow** - Complete meal planning workflow
2. **Nutrition Analysis Flow** - Nutrition trend analysis and recommendations
3. **FatSecret Sync Flow** - Integration with FatSecret
4. **Automated Planning Flow** - Scheduled planning tasks

#### Module Organization:
- **Core Modules** - Fundamental business logic components
- **Nutrition Modules** - Nutrition calculation and analysis
- **Integration Modules** - External API integrations
- **CLI Modules** - Command-line interface components
- **Error Handling** - Centralized error management

Each module will be implemented as a Go lambda following the patterns defined in the Go Lambda Implementation Guide.

### Phase 2: Go Lambda Implementation Patterns

#### Data Structures
- Use JSON for data interchange between Go lambdas
- Define clear input/output contracts for each lambda
- Leverage existing Gleam type definitions as reference

#### Error Handling
- Use Go error types for failures
- Implement error propagation through Windmill
- Maintain consistency with existing error handling patterns

#### External Integration
- Convert API clients to Go lambdas
- Implement retry logic in Go code
- Handle authentication through Windmill secrets

### Phase 3: Windmill Flow Design

#### Flow Patterns
1. **Sequential Flows** - Simple step-by-step execution
2. **Parallel Flows** - Multiple operations running concurrently
3. **Retry Logic** - Automatic retries with exponential backoff
4. **Error Handling** - Centralized error management
5. **Caching** - Built-in caching for expensive operations

#### Orchestration Examples
1. **Meal Planning Flow** - Generate plan → Validate → Save
2. **Nutrition Analysis Flow** - Calculate macros → Validate → Store
3. **Recipe Processing Flow** - Fetch → Transform → Validate → Store

## Implementation Roadmap

### Phase 1: Foundation Setup (Week 1-2)
1. **Environment Setup** - Configure Windmill workspace and deployment
2. **Go Lambda Templates** - Create standard Go lambda templates with error handling
3. **Infrastructure** - Set up database connections and external API integrations
4. **Testing Framework** - Establish testing patterns for Go lambdas

### Phase 2: Core Components (Week 3-4)
1. **Nutrition Calculation Engine** - Migrate NCP modules to Go lambdas
2. **Advisor Logic** - Migrate advisor recommendation engine
3. **Grocery List Generation** - Migrate grocery list generation
4. **CLI Commands** - Migrate CLI command processing

### Phase 3: Integration Flows (Week 5-6)
1. **Web Handlers** - Migrate web handlers to Go lambdas
2. **External Integrations** - Implement FatSecret and Tandoor API integrations
3. **Core Flows** - Design and implement main Windmill flows
4. **Error Handling** - Set up centralized error handling

### Phase 4: Advanced Features (Week 7-8)
1. **Caching Strategies** - Implement caching for expensive operations
2. **Monitoring** - Add observability and logging
3. **Performance Optimization** - Optimize Go lambda execution
4. **Testing** - Comprehensive test coverage for all components

### Phase 5: Validation and Migration (Week 9-10)
1. **Integration Testing** - Test complete workflows
2. **Data Migration** - Ensure data consistency
3. **Performance Testing** - Validate performance improvements
4. **Documentation** - Update all documentation for new architecture

## Technical Considerations

### Data Flow Design
- Define clear input/output contracts for each Go lambda
- Use JSON for data interchange between components
- Maintain backward compatibility where possible
- Ensure all data structures are consistent with existing Gleam types

### Error Handling Strategy
- Implement consistent error types in Go using custom error structs
- Leverage Windmill's built-in error handling and retry mechanisms
- Maintain existing error message patterns for compatibility
- Use structured logging for debugging

### Performance Optimization
- Implement caching for expensive operations (nutrition calculations, trend analysis)
- Use parallel execution where appropriate (multiple recipe processing)
- Optimize data processing pipelines with efficient algorithms
- Leverage Go's performance characteristics for mathematical operations

## Migration Benefits

1. **Scalability** - Go lambdas are lightweight and scalable with efficient memory usage
2. **Maintainability** - Clear separation of concerns with well-defined contracts and consistent patterns
3. **Observability** - Built-in monitoring, tracing, and logging in Windmill
4. **Reliability** - Built-in retry, error handling, and circuit breaker patterns in Windmill
5. **Flexibility** - Easy to modify individual components without affecting others
6. **Performance** - Go's compiled nature and efficient execution for mathematical operations
7. **Consistency** - Standardized Go lambda patterns across all components
8. **Integration** - Seamless integration with external services through Windmill's resource management

## Risk Mitigation

1. **Data Consistency** - Implement data validation and migration testing
2. **Performance** - Monitor Go lambda execution and optimize as needed
3. **Error Handling** - Maintain consistent error patterns and implement comprehensive error handling
4. **Testing** - Comprehensive test coverage for all migrated components with regression testing
5. **Rollback Strategy** - Maintain ability to revert to original Gleam implementation if needed
6. **Monitoring** - Implement comprehensive monitoring during migration phase

## Next Steps

1. **Phase 1**: Begin with simple components to establish patterns and testing frameworks
2. **Documentation**: Create detailed implementation guides for each Go lambda type
3. **Infrastructure**: Set up Windmill deployment pipeline and resource management
4. **Testing**: Implement comprehensive testing for all migrated components
5. **Validation**: Validate performance improvements and correctness of migrated components