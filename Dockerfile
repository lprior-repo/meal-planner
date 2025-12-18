# Gleam Backend Dockerfile
# Multi-stage build for production-ready Gleam application

# Stage 1: Build the Gleam application
FROM ghcr.io/gleam-lang/gleam:v1.7.1-erlang-alpine AS builder

# Install build dependencies
RUN apk add --no-cache \
    gcc \
    musl-dev \
    postgresql-dev

WORKDIR /build

# Copy dependency files first (for better caching)
COPY gleam.toml manifest.toml ./

# Download dependencies
RUN gleam deps download

# Copy source code
COPY src ./src
COPY test ./test
COPY priv ./priv 2>/dev/null || true

# Build the application
RUN gleam build --target erlang

# Stage 2: Create minimal runtime image
FROM erlang:27-alpine

# Install runtime dependencies
RUN apk add --no-cache \
    libstdc++ \
    libpq \
    ca-certificates \
    curl

# Create app user
RUN addgroup -g 1000 gleam && \
    adduser -D -u 1000 -G gleam gleam

WORKDIR /app

# Copy built application from builder
COPY --from=builder --chown=gleam:gleam /build/build /app/build
COPY --from=builder --chown=gleam:gleam /build/manifest.toml /app/
COPY --from=builder --chown=gleam:gleam /build/gleam.toml /app/

USER gleam

# Expose API port
EXPOSE 8080

# Health check endpoint
HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
  CMD curl -f http://localhost:8080/health || exit 1

# Start the application
# Note: This will need to be updated once the HTTP server is implemented
CMD ["gleam", "run"]
