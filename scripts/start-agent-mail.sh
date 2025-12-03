#!/bin/bash
# Start MCP Agent Mail Server
# Simple launcher for mcp_agent_mail MCP server

set -e

# Color codes for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BLUE}  MCP Agent Mail Server Launcher${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

# Default values
PORT="${AGENT_MAIL_PORT:-8765}"
HOST="${AGENT_MAIL_HOST:-127.0.0.1}"
INSTALL_DIR="${AGENT_MAIL_INSTALL_DIR:-$HOME/.local/mcp_agent_mail}"
AUTO_INSTALL="${AGENT_MAIL_AUTO_INSTALL:-true}"

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --port)
            PORT="$2"
            shift 2
            ;;
        --host)
            HOST="$2"
            shift 2
            ;;
        --install-dir)
            INSTALL_DIR="$2"
            shift 2
            ;;
        --no-install)
            AUTO_INSTALL="false"
            shift
            ;;
        --help|-h)
            echo "Usage: $0 [OPTIONS]"
            echo ""
            echo "Options:"
            echo "  --port PORT         Server port (default: 8765, env: AGENT_MAIL_PORT)"
            echo "  --host HOST         Server host (default: 127.0.0.1, env: AGENT_MAIL_HOST)"
            echo "  --install-dir DIR   Installation directory (default: ~/.local/mcp_agent_mail)"
            echo "  --no-install        Skip auto-installation if not found"
            echo "  --help, -h          Show this help message"
            echo ""
            echo "Environment variables:"
            echo "  AGENT_MAIL_PORT         - Override default port"
            echo "  AGENT_MAIL_HOST         - Override default host"
            echo "  AGENT_MAIL_INSTALL_DIR  - Override installation directory"
            echo "  AGENT_MAIL_AUTO_INSTALL - Auto-install if not found (default: true)"
            echo "  AGENT_NAME              - Set agent name for file reservations"
            echo ""
            echo "Web interface: http://127.0.0.1:8765/mail"
            exit 0
            ;;
        *)
            echo -e "${RED}✗ Unknown option: $1${NC}"
            echo "Use --help for usage information"
            exit 1
            ;;
    esac
done

echo -e "${GREEN}✓ Configuration:${NC}"
echo -e "  Host:        ${BLUE}${HOST}${NC}"
echo -e "  Port:        ${BLUE}${PORT}${NC}"
echo -e "  Install Dir: ${BLUE}${INSTALL_DIR}${NC}"
if [ -n "$AGENT_NAME" ]; then
    echo -e "  Agent:       ${BLUE}${AGENT_NAME}${NC}"
fi
echo ""

# Check if mcp_agent_mail is installed
if [ ! -d "$INSTALL_DIR" ]; then
    if [ "$AUTO_INSTALL" = "true" ]; then
        echo -e "${YELLOW}⧗ MCP Agent Mail not found at ${INSTALL_DIR}${NC}"
        echo -e "${YELLOW}⧗ Installing manually...${NC}"
        echo ""

        # Create parent directory
        mkdir -p "$(dirname "$INSTALL_DIR")"

        # Clone the repository
        echo -e "${BLUE}  → Cloning repository...${NC}"
        git clone https://github.com/Dicklesworthstone/mcp_agent_mail.git "$INSTALL_DIR"

        # Navigate to install directory
        cd "$INSTALL_DIR"

        # Create virtual environment
        echo -e "${BLUE}  → Creating Python 3.14 virtual environment...${NC}"
        uv venv -p 3.14 || uv venv -p 3.13 || uv venv -p 3.12

        # Install dependencies
        echo -e "${BLUE}  → Installing dependencies...${NC}"
        uv sync

        echo ""
        echo -e "${GREEN}✓ Installation complete${NC}"
        echo ""
    else
        echo -e "${RED}✗ Error: MCP Agent Mail not found at ${INSTALL_DIR}${NC}"
        echo -e "${YELLOW}Run without --no-install to auto-install, or install manually:${NC}"
        echo -e "${BLUE}git clone https://github.com/Dicklesworthstone/mcp_agent_mail.git ${INSTALL_DIR}${NC}"
        echo -e "${BLUE}cd ${INSTALL_DIR} && uv venv -p 3.14 && uv sync${NC}"
        exit 1
    fi
fi

# Check if uv is available
if ! command -v uv &> /dev/null; then
    echo -e "${RED}✗ Error: uv not found in PATH${NC}"
    echo -e "${YELLOW}Installing uv...${NC}"
    curl -LsSf https://astral.sh/uv/install.sh | sh
    export PATH="$HOME/.local/bin:$PATH"
fi

# Navigate to installation directory
cd "$INSTALL_DIR"

echo -e "${GREEN}✓ Starting MCP Agent Mail server...${NC}"
echo -e "${BLUE}  Web interface: http://${HOST}:${PORT}/mail${NC}"
echo ""
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

# Start the server
exec uv run python -m mcp_agent_mail.http --host "$HOST" --port "$PORT"
