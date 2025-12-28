# Complete Porting Guide: Meal Planner to Windmill + Go Lambdas

This document provides a comprehensive guide for migrating the meal-planner codebase to use Windmill as the orchestrator with Go lambdas.

## Executive Summary

The meal planner will be migrated from its current Gleam-based architecture to a new architecture that leverages Windmill for orchestration and Go lambdas for business logic execution. This approach will provide better scalability, maintainability, and observability while maintaining the existing business logic patterns.

## Migration Overview

### Current Architecture
- Gleam-based web server with HTTP handlers
- CLI commands for command-line operations
- Business logic modules for meal planning, nutrition calculations, etc.
- Integration with Tandoor and FatSecret APIs
- Manual orchestration of components

### Target Architecture
- Windmill orchestration engine for workflow management
- Go lambdas for all business logic components
- Standardized input/output contracts for all functions
- Centralized error handling and monitoring
- Improved scalability and maintainability

## Key Components for Migration

### 1. Nutrition Calculation Engine (NCP)
- `calculate_deviation` - Core deviation calculations
- `deviation_is_within_tolerance` - Compliance checking
- `calculate_min_nutrition` / `calculate_max_nutrition` - Statistical analysis
- `calculate_nutrition_variability` - Variance calculations
- `calculate_daily_totals` - Aggregation functions
- `calculate_macro_percentages` - Macro distribution calculations
- `estimate_daily_calories` - Calorie estimation

### 2. Advisor Recommendation Engine
- `analyze_nutrition_trends` - Trend analysis
- `calculate_consistency_rate` - Consistency calculations
- `determine_trend` - Trend direction determination
- `calculate_compliance_score` - Compliance scoring

### 3. Grocery List Generation
- `from_ingredients` - Ingredient aggregation
- `group_by_food` - Data grouping
- `sum_quantities` - Quantity calculation

### 4. CLI Command Processing
- `generate_report` - Nutrition reporting
- `display_trends` - Trend analysis display
- `check_compliance` - Compliance checking

## Go Lambda Implementation Patterns

All Go lambdas follow consistent patterns:
- Standard input/output structures with JSON serialization
- Consistent error handling with custom error types
- Stateless implementation with no side effects
- Comprehensive testing with existing fixtures
- Structured logging for observability

## Windmill Flow Structure

### Core Flows
1. **Meal Planning Flow** - Complete meal planning workflow
2. **Nutrition Analysis Flow** - Nutrition trend analysis and recommendations
3. **FatSecret Sync Flow** - Integration with FatSecret
4. **Automated Planning Flow** - Scheduled planning tasks

### Module Organization
- **Core Modules** - Fundamental business logic components
- **Nutrition Modules** - Nutrition calculation and analysis
- **Integration Modules** - External API integrations
- **CLI Modules** - Command-line interface components
- **Error Handling** - Centralized error management

## Implementation Roadmap

### Phase 1: Foundation (Weeks 1-2)
- Set up Windmill workspace and deployment pipeline
- Create Go lambda templates with standard error handling
- Establish testing frameworks
- Configure external API integrations

### Phase 2: Core Components (Weeks 3-4)
- Migrate Nutrition Calculation Engine to Go lambdas
- Migrate Advisor Recommendation Engine
- Migrate Grocery List Generation
- Migrate CLI Command Processing

### Phase 3: Integration Flows (Weeks 5-6)
- Migrate Web Handlers to Go lambdas
- Implement FatSecret and Tandoor API integrations
- Design and implement main Windmill flows
- Set up centralized error handling

### Phase 4: Advanced Features (Weeks 7-8)
- Implement caching strategies
- Add monitoring and observability
- Optimize performance and resource usage
- Comprehensive testing and validation

## Benefits of Migration

1. **Scalability** - Go lambdas are lightweight and scalable
2. **Maintainability** - Clear separation of concerns with well-defined contracts
3. **Observability** - Built-in monitoring, tracing, and logging in Windmill
4. **Reliability** - Built-in retry, error handling, and circuit breaker patterns
5. **Performance** - Go's compiled nature and efficient execution for mathematical operations
6. **Flexibility** - Easy to modify individual components without affecting others
7. **Consistency** - Standardized Go lambda patterns across all components

## Technical Considerations

### Data Flow Design
- Clear input/output contracts for each Go lambda
- JSON-based data interchange between components
- Consistent data structures with existing Gleam types

### Error Handling Strategy
- Consistent error types in Go using custom error structs
- Windmill's built-in error handling and retry mechanisms
- Maintained error message patterns for compatibility

### Performance Optimization
- Caching for expensive operations (nutrition calculations, trend analysis)
- Parallel execution where appropriate
- Efficient data processing pipelines

## Risk Mitigation

1. **Data Consistency** - Implement data validation and migration testing
2. **Performance** - Monitor Go lambda execution and optimize as needed
3. **Error Handling** - Maintain consistent error patterns and implement comprehensive error handling
4. **Testing** - Comprehensive test coverage for all migrated components
5. **Rollback Strategy** - Maintain ability to revert to original Gleam implementation if needed
6. **Monitoring** - Implement comprehensive monitoring during migration phase

## Next Steps

1. Begin with simple components to establish patterns and testing frameworks
2. Create detailed implementation guides for each Go lambda type
3. Set up Windmill deployment pipeline and resource management
4. Implement comprehensive testing for all migrated components
5. Validate performance improvements and correctness of migrated components