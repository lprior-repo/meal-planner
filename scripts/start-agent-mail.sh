#!/usr/bin/env bash
# Simple Agent Mail Server Starter
# Just run it - everything is automatic

set -euo pipefail

INSTALL_DIR="$HOME/.local/mcp_agent_mail"
MAILBOX_DIR="$HOME/.mcp_agent_mail_git_mailbox_repo"
ENV_FILE="$MAILBOX_DIR/.env"
PORT=8765

# Check if server is already running
if pgrep -f "mcp_agent_mail" > /dev/null 2>&1; then
    # Verify it's actually responding
    if curl -s -f "http://127.0.0.1:$PORT/health/liveness" > /dev/null 2>&1; then
        echo "✓ Server is already running and healthy"
        echo ""
        echo "Web UI: http://127.0.0.1:$PORT/mail"
        echo "Logs: $MAILBOX_DIR/server.log"
        echo ""
        exit 0
    else
        echo "⚠ Server process found but not responding - will restart"
        pkill -f "mcp_agent_mail" || true
        sleep 1
    fi
fi

# Install if needed
if [ ! -d "$INSTALL_DIR" ] || [ ! -f "$INSTALL_DIR/scripts/run_server_with_token.sh" ]; then
    echo "Installing Agent Mail..."

    # Install uv if needed
    if ! command -v uv &> /dev/null; then
        curl -LsSf https://astral.sh/uv/install.sh | sh
        export PATH="$HOME/.local/bin:$PATH"
    fi

    # Clone and install
    mkdir -p "$(dirname "$INSTALL_DIR")"
    git clone https://github.com/Dicklesworthstone/mcp_agent_mail.git "$INSTALL_DIR"
    cd "$INSTALL_DIR"
    uv venv -p 3.14 || uv venv -p 3.13 || uv venv -p 3.12
    uv sync

    echo "✓ Installation complete"
    echo ""
fi

# Setup config if needed
if [ ! -f "$ENV_FILE" ]; then
    echo "Setting up configuration..."
    mkdir -p "$MAILBOX_DIR"

    # Generate secure token
    cd "$INSTALL_DIR"
    TOKEN=$(uv run python -c "import secrets; print(secrets.token_hex(32))")

    # Create config
    cat > "$ENV_FILE" <<EOF
HTTP_PORT=$PORT
HTTP_HOST=127.0.0.1
HTTP_BEARER_TOKEN=$TOKEN
EOF

    chmod 600 "$ENV_FILE"
    echo "✓ Configuration created"
    echo ""
fi

# Start server
echo "Starting Agent Mail server..."
cd "$INSTALL_DIR"
nohup "$INSTALL_DIR/scripts/run_server_with_token.sh" > "$MAILBOX_DIR/server.log" 2>&1 &

# Wait and verify process started
sleep 2
if ! pgrep -f "mcp_agent_mail" > /dev/null 2>&1; then
    echo "✗ Server process failed to start"
    echo "Check logs: $MAILBOX_DIR/server.log"
    exit 1
fi

# Wait for HTTP server to be ready (max 10 seconds)
echo "Testing server readiness..."
MAX_ATTEMPTS=20
ATTEMPT=0
while [ $ATTEMPT -lt $MAX_ATTEMPTS ]; do
    if curl -s -f "http://127.0.0.1:$PORT/health/liveness" > /dev/null 2>&1; then
        echo "✓ Server is ready and responding"
        echo ""
        echo "Web UI: http://127.0.0.1:$PORT/mail"
        echo "Logs: $MAILBOX_DIR/server.log"
        echo ""
        exit 0
    fi
    ATTEMPT=$((ATTEMPT + 1))
    sleep 0.5
done

echo "✗ Server started but not responding to HTTP requests"
echo "Check logs: $MAILBOX_DIR/server.log"
exit 1
