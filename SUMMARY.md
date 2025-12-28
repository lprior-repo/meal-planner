# Meal Planner Rust Project Structure

This project provides a comprehensive Rust project structure for the Meal Planner application that's compatible with Windmill orchestration patterns.

## Project Structure

```
src/
├── main.rs              # Application entry point
├── lib.rs               # Library exports
├── cli/                 # Command-line interface
├── config/                # Configuration management
├── db/                  # Database integration
├── models/              # Data models
├── errors/              # Error handling
├── web/                 # Web server and handlers
├── logging/             # Logging configuration
└── utils/               # Utility functions
```

## Key Features Implemented

1. **Proper Rust Project Structure**:
   - Modular organization with clear separation of concerns
   - Standard Rust project layout
   - Cargo.toml with appropriate dependencies

2. **Core Dependencies**:
   - HTTP handling (warp)
   - Database connectivity (PostgreSQL with deadpool)
   - JSON handling (serde)
   - Error handling (thiserror, anyhow)
   - Async runtime (tokio)
   - Configuration management (config, dotenvy)
   - CLI interface (clap)

3. **Modular Components**:
   - Configuration management with environment variables
   - Database abstraction layer
   - Web server with handler traits
   - Error handling with custom error types
   - Logging with tracing
   - Data models for nutrition, recipes, meals, etc.

4. **Windmill Orchestration Compatibility**:
   - Modular design that can be easily integrated with Windmill workflows
   - Clear separation of concerns
   - Async-first approach
   - Standardized interfaces for components

## How to Use

1. **Run the application**:
   ```bash
   cargo run
   ```

2. **Build the project**:
   ```bash
   cargo build
   ```

3. **Run tests**:
   ```bash
   cargo test
   ```

4. **Lint the code**:
   ```bash
   cargo clippy
   ```

## Integration Points

The structure is designed to be compatible with Windmill orchestration patterns through:

- Clear module boundaries
- Standardized interfaces
- Async-first design
- Configuration-driven approach
- Error handling that integrates well with monitoring systems

This structure provides a solid foundation that can be extended with the specific functionality from the original Gleam codebase while maintaining Rust idioms and Windmill compatibility.