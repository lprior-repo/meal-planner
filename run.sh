#!/bin/bash

# Meal Planner - Automated Startup Script
# This is a temporary wrapper until go-task is installed
# Install go-task: sudo pacman -S go-task (or see https://taskfile.dev)

set -e

GLEAM_DIR="./gleam"
MEALIE_DB="mealie"
APP_DB="meal_planner"
POSTGRES_USER="postgres"

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

banner() {
    echo -e "${BLUE}🍽️  Meal Planner - Full Stack Startup${NC}"
    echo "======================================"
    echo ""
}

check_dependencies() {
    echo -e "${BLUE}🔍 Checking dependencies...${NC}"

    # Check Gleam
    if ! command -v gleam &> /dev/null; then
        echo -e "${RED}❌ Gleam not found.${NC} Install from: https://gleam.run"
        exit 1
    fi
    echo -e "   ${GREEN}✓${NC} Gleam $(gleam --version | grep -oP '\d+\.\d+\.\d+' || echo 'installed')"

    # Check PostgreSQL
    if ! command -v psql &> /dev/null; then
        echo -e "${RED}❌ PostgreSQL not found.${NC} Install: sudo pacman -S postgresql"
        exit 1
    fi
    echo -e "   ${GREEN}✓${NC} PostgreSQL installed"

    # Check Docker
    if ! command -v docker &> /dev/null; then
        echo -e "${RED}❌ Docker not found.${NC} Install from: https://docker.com"
        exit 1
    fi
    echo -e "   ${GREEN}✓${NC} Docker installed"

    echo ""
}

check_postgres() {
    echo -e "${BLUE}📊 Checking PostgreSQL...${NC}"
    if ! pg_isready -q 2>/dev/null; then
        echo -e "   ${YELLOW}⚠️  PostgreSQL is not running. Please start it:${NC}"
        echo "      sudo systemctl start postgresql"
        exit 1
    fi
    echo -e "   ${GREEN}✓${NC} PostgreSQL is running"
}

create_databases() {
    # Check and create meal_planner database
    if ! psql -U $POSTGRES_USER -lqt 2>/dev/null | cut -d \| -f 1 | grep -qw $APP_DB; then
        echo "   Creating $APP_DB database..."
        createdb -U $POSTGRES_USER $APP_DB
    fi

    # Check and create mealie database
    if ! psql -U $POSTGRES_USER -lqt 2>/dev/null | cut -d \| -f 1 | grep -qw $MEALIE_DB; then
        echo "   Creating $MEALIE_DB database..."
        createdb -U $POSTGRES_USER $MEALIE_DB
    fi
}

verify_database() {
    FOOD_COUNT=$(psql -U $POSTGRES_USER -d $APP_DB -tAc "SELECT COUNT(*) FROM foods" 2>/dev/null || echo "0")
    if [ "$FOOD_COUNT" -gt "0" ]; then
        echo -e "   ${GREEN}✓${NC} Database has $FOOD_COUNT foods"
    else
        echo -e "   ${YELLOW}⚠️  Database is empty.${NC} You may want to run migrations."
    fi
    echo ""
}

start_mealie() {
    echo -e "${BLUE}🍲 Starting Mealie...${NC}"

    # Stop if already running
    docker rm -f meal-planner-mealie 2>/dev/null || true

    # Start Mealie
    docker run -d \
        --name meal-planner-mealie \
        --network host \
        --restart unless-stopped \
        -e DB_ENGINE=postgres \
        -e POSTGRES_USER=$POSTGRES_USER \
        -e POSTGRES_PASSWORD=postgres \
        -e POSTGRES_SERVER=localhost \
        -e POSTGRES_PORT=5432 \
        -e POSTGRES_DB=$MEALIE_DB \
        -e BASE_URL=http://localhost:9000 \
        -e API_PORT=9000 \
        -e API_DOCS=true \
        -e ALLOW_SIGNUP=true \
        -e ALLOW_PASSWORD_LOGIN=true \
        -v mealie_data:/app/data \
        ghcr.io/mealie-recipes/mealie:v3.6.1 > /dev/null

    # Wait for Mealie to be ready
    echo "   Waiting for Mealie to start..."
    for i in {1..30}; do
        if curl -sf http://localhost:9000/api/app/about > /dev/null 2>&1; then
            echo -e "   ${GREEN}✓${NC} Mealie is ready"
            echo ""
            break
        fi
        sleep 1
    done
}

start_api() {
    echo -e "${BLUE}🚀 Starting API server...${NC}"

    # Stop if already running
    pkill -f "gleam run" 2>/dev/null || true

    # Build
    cd $GLEAM_DIR
    gleam build > /dev/null 2>&1

    # Start server with env vars via wrapper script
    nohup ./run-with-env.sh > /tmp/meal-planner-api.log 2>&1 &
    echo $! > /tmp/meal-planner-api.pid
    cd - > /dev/null

    # Wait for server to be ready
    echo "   Waiting for API server..."
    for i in {1..10}; do
        if curl -sf http://localhost:8080/health > /dev/null 2>&1; then
            echo -e "   ${GREEN}✓${NC} API server is ready"
            echo ""
            break
        fi
        sleep 1
    done
}

show_status() {
    echo -e "${BLUE}📊 Service Status${NC}"
    echo "=================="
    echo ""

    # Database
    if pg_isready -q 2>/dev/null; then
        echo -e "${GREEN}✅ PostgreSQL: Running${NC}"
    else
        echo -e "${RED}❌ PostgreSQL: Stopped${NC}"
    fi

    # Mealie
    if docker ps | grep -q meal-planner-mealie; then
        echo -e "${GREEN}✅ Mealie: Running (http://localhost:9000)${NC}"
    else
        echo -e "${RED}❌ Mealie: Stopped${NC}"
    fi

    # API Server
    if curl -sf http://localhost:8080/health > /dev/null 2>&1; then
        echo -e "${GREEN}✅ API Server: Running (http://localhost:8080)${NC}"
    else
        echo -e "${RED}❌ API Server: Stopped${NC}"
    fi
    echo ""
}

stop_all() {
    echo -e "${BLUE}🛑 Stopping all services...${NC}"

    # Stop API
    if [ -f /tmp/meal-planner-api.pid ]; then
        kill $(cat /tmp/meal-planner-api.pid) 2>/dev/null || true
        rm /tmp/meal-planner-api.pid
    fi
    pkill -f "gleam run" 2>/dev/null || true

    # Stop Mealie
    docker rm -f meal-planner-mealie 2>/dev/null || true

    echo -e "${GREEN}✅ All services stopped${NC}"
}

show_help() {
    echo "Meal Planner Control Script"
    echo ""
    echo "Usage: ./run.sh [command]"
    echo ""
    echo "Commands:"
    echo "  start      - Start all services (default)"
    echo "  stop       - Stop all services"
    echo "  restart    - Restart all services"
    echo "  status     - Show service status"
    echo "  logs       - Show API logs"
    echo "  help       - Show this help"
    echo ""
    echo "Install go-task for better experience:"
    echo "  sudo pacman -S go-task"
    echo "  then use: task start"
}

# Main command handling
case "${1:-start}" in
    start)
        banner
        check_dependencies
        check_postgres
        create_databases
        verify_database
        start_mealie
        start_api
        show_status

        echo ""
        echo -e "${GREEN}✅ Meal Planner is ready!${NC}"
        echo ""
        echo "📱 Access points:"
        echo "   - API Server:    http://localhost:8080/health"
        echo "   - Mealie UI:     http://localhost:9000"
        echo ""
        ;;
    stop)
        stop_all
        ;;
    restart)
        stop_all
        sleep 2
        $0 start
        ;;
    status)
        show_status
        ;;
    logs)
        tail -f /tmp/meal-planner-api.log
        ;;
    help)
        show_help
        ;;
    *)
        echo "Unknown command: $1"
        show_help
        exit 1
        ;;
esac
