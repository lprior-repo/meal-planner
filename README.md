# Meal Planner

A Rust-based application for meal planning, nutrition tracking, and recipe management.

## Features

- Web API endpoints for meal planning and nutrition tracking
- CLI interface for command-line operations
- Database integration for persistent data storage
- Integration with external services (FatSecret, Tandoor)
- Configuration management and error handling

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

## Getting Started

1. Install Rust (latest stable version)
2. Clone the repository
3. Run `cargo run` to start the application

## Development

- Run tests with `cargo test`
- Run linter with `cargo clippy`
- Format code with `cargo fmt`

## License

MIT