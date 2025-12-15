#!/bin/bash

# Parallel Endpoint Testing with 12 Agents
# Agent Mail + Claude Flow Orchestration

set -e

PROJECT_KEY="/home/lewis/src/meal-planner"
API_BASE="http://localhost:8080"
RESULTS_DIR="/tmp/endpoint_test_results"
mkdir -p "$RESULTS_DIR"

# Color output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}🚀 Starting Parallel Endpoint Tests - 12 Agent Distribution${NC}\n"

# ============================================================================
# AGENT 1: Health & Status
# ============================================================================
test_health_status() {
    local agent_name="HealthTester"
    local results_file="$RESULTS_DIR/agent_1_health.json"

    echo -e "${YELLOW}[Agent 1] Testing Health & Status Endpoints...${NC}"

    {
        echo "{"
        echo "  \"agent_id\": \"agent-1\","
        echo "  \"agent_name\": \"$agent_name\","
        echo "  \"category\": \"Health & Status\","
        echo "  \"tests\": ["

        # Test 1: GET /
        response=$(curl -s -w "\n%{http_code}" "$API_BASE/")
        http_code=$(echo "$response" | tail -n1)
        body=$(echo "$response" | head -n-1)
        echo "    {\"endpoint\": \"GET /\", \"method\": \"GET\", \"status_code\": $http_code, \"timestamp\": \"$(date -u +%Y-%m-%dT%H:%M:%SZ)\"}"

        # Test 2: GET /health
        response=$(curl -s -w "\n%{http_code}" "$API_BASE/health")
        http_code=$(echo "$response" | tail -n1)
        body=$(echo "$response" | head -n-1)
        echo "    ,{\"endpoint\": \"GET /health\", \"method\": \"GET\", \"status_code\": $http_code, \"timestamp\": \"$(date -u +%Y-%m-%dT%H:%M:%SZ)\"}"

        echo "  ]"
        echo "}"
    } > "$results_file"
    echo -e "${GREEN}✓ Health tests completed${NC}"
}

# ============================================================================
# AGENT 2: OAuth
# ============================================================================
test_oauth() {
    local agent_name="OAuthValidator"
    local results_file="$RESULTS_DIR/agent_2_oauth.json"

    echo -e "${YELLOW}[Agent 2] Testing OAuth Endpoints...${NC}"

    {
        echo "{"
        echo "  \"agent_id\": \"agent-2\","
        echo "  \"agent_name\": \"$agent_name\","
        echo "  \"category\": \"OAuth\","
        echo "  \"tests\": ["

        # Test OAuth endpoints
        for endpoint in "/fatsecret/connect" "/fatsecret/status"; do
            response=$(curl -s -w "\n%{http_code}" "$API_BASE$endpoint" 2>/dev/null || echo "error\n0")
            http_code=$(echo "$response" | tail -n1)
            echo "    {\"endpoint\": \"GET $endpoint\", \"method\": \"GET\", \"status_code\": $http_code, \"timestamp\": \"$(date -u +%Y-%m-%dT%H:%M:%SZ)\"},"
        done

        # Last one without comma
        response=$(curl -s -w "\n%{http_code}" "$API_BASE/fatsecret/disconnect" 2>/dev/null || echo "error\n0")
        http_code=$(echo "$response" | tail -n1)
        echo "    {\"endpoint\": \"POST /fatsecret/disconnect\", \"method\": \"POST\", \"status_code\": $http_code, \"timestamp\": \"$(date -u +%Y-%m-%dT%H:%M:%SZ)\"}"

        echo "  ]"
        echo "}"
    } > "$results_file"
    echo -e "${GREEN}✓ OAuth tests completed${NC}"
}

# ============================================================================
# AGENT 3: Foods API
# ============================================================================
test_foods_api() {
    local agent_name="FoodsTester"
    local results_file="$RESULTS_DIR/agent_3_foods.json"

    echo -e "${YELLOW}[Agent 3] Testing Foods API...${NC}"

    {
        echo "{"
        echo "  \"agent_id\": \"agent-3\","
        echo "  \"agent_name\": \"$agent_name\","
        echo "  \"category\": \"Foods API\","
        echo "  \"tests\": ["

        # Search endpoint
        response=$(curl -s -w "\n%{http_code}" "$API_BASE/api/fatsecret/foods/search?search_expression=chicken" 2>/dev/null || echo "error\n0")
        http_code=$(echo "$response" | tail -n1)
        echo "    {\"endpoint\": \"GET /api/fatsecret/foods/search\", \"method\": \"GET\", \"status_code\": $http_code, \"timestamp\": \"$(date -u +%Y-%m-%dT%H:%M:%SZ)\"},"

        # Get food by ID
        response=$(curl -s -w "\n%{http_code}" "$API_BASE/api/fatsecret/foods/123456" 2>/dev/null || echo "error\n0")
        http_code=$(echo "$response" | tail -n1)
        echo "    {\"endpoint\": \"GET /api/fatsecret/foods/:id\", \"method\": \"GET\", \"status_code\": $http_code, \"timestamp\": \"$(date -u +%Y-%m-%dT%H:%M:%SZ)\"}"

        echo "  ]"
        echo "}"
    } > "$results_file"
    echo -e "${GREEN}✓ Foods API tests completed${NC}"
}

# ============================================================================
# AGENT 4: Recipes API
# ============================================================================
test_recipes_api() {
    local agent_name="RecipesTester"
    local results_file="$RESULTS_DIR/agent_4_recipes.json"

    echo -e "${YELLOW}[Agent 4] Testing Recipes API...${NC}"

    {
        echo "{"
        echo "  \"agent_id\": \"agent-4\","
        echo "  \"agent_name\": \"$agent_name\","
        echo "  \"category\": \"Recipes API\","
        echo "  \"tests\": ["

        endpoints=("/api/fatsecret/recipes/types" "/api/fatsecret/recipes/search" "/api/fatsecret/recipes/999888")

        for i in "${!endpoints[@]}"; do
            endpoint="${endpoints[$i]}"
            response=$(curl -s -w "\n%{http_code}" "$API_BASE$endpoint" 2>/dev/null || echo "error\n0")
            http_code=$(echo "$response" | tail -n1)
            comma=$([ $i -lt $((${#endpoints[@]} - 1)) ] && echo "," || echo "")
            echo "    {\"endpoint\": \"GET $endpoint\", \"method\": \"GET\", \"status_code\": $http_code, \"timestamp\": \"$(date -u +%Y-%m-%dT%H:%M:%SZ)\"}$comma"
        done

        echo "  ]"
        echo "}"
    } > "$results_file"
    echo -e "${GREEN}✓ Recipes API tests completed${NC}"
}

# ============================================================================
# AGENT 5-12: Remaining APIs (simplified)
# ============================================================================
test_other_apis() {
    local agent_num=$1
    local agent_name=$2
    local category=$3
    local endpoints=$4

    local results_file="$RESULTS_DIR/agent_${agent_num}_${agent_name,,}.json"

    echo -e "${YELLOW}[Agent $agent_num] Testing $category...${NC}"

    {
        echo "{"
        echo "  \"agent_id\": \"agent-$agent_num\","
        echo "  \"agent_name\": \"$agent_name\","
        echo "  \"category\": \"$category\","
        echo "  \"tests\": ["

        IFS=';' read -ra ENDPOINT_ARRAY <<< "$endpoints"
        for i in "${!ENDPOINT_ARRAY[@]}"; do
            endpoint="${ENDPOINT_ARRAY[$i]}"
            response=$(curl -s -w "\n%{http_code}" "$API_BASE$endpoint" 2>/dev/null || echo "error\n0")
            http_code=$(echo "$response" | tail -n1)
            comma=$([ $i -lt $((${#ENDPOINT_ARRAY[@]} - 1)) ] && echo "," || echo "")
            echo "    {\"endpoint\": \"GET $endpoint\", \"method\": \"GET\", \"status_code\": $http_code, \"timestamp\": \"$(date -u +%Y-%m-%dT%H:%M:%SZ)\"}$comma"
        done

        echo "  ]"
        echo "}"
    } > "$results_file"
    echo -e "${GREEN}✓ $category tests completed${NC}"
}

# ============================================================================
# Run All Tests in Parallel
# ============================================================================

# Start all agent tests in parallel
test_health_status &
PID[1]=$!

test_oauth &
PID[2]=$!

test_foods_api &
PID[3]=$!

test_recipes_api &
PID[4]=$!

# Agents 5-12 with simplified API tests
test_other_apis 5 "FavoritesFoodsTester" "Favorites Foods" "/api/fatsecret/favorites/foods" &
PID[5]=$!

test_other_apis 6 "FavoritesRecipesTester" "Favorites Recipes" "/api/fatsecret/favorites/recipes" &
PID[6]=$!

test_other_apis 7 "SavedMealsTester" "Saved Meals" "/api/fatsecret/saved-meals" &
PID[7]=$!

test_other_apis 8 "DiaryTester" "Diary API" "/api/fatsecret/diary/day/20241214" &
PID[8]=$!

test_other_apis 9 "ProfileExerciseTester" "Profile & Exercise" "/api/fatsecret/profile" &
PID[9]=$!

test_other_apis 10 "WeightTester" "Weight API" "/api/fatsecret/weight" &
PID[10]=$!

test_other_apis 11 "DashboardLegacyTester" "Legacy Dashboard" "/dashboard;/api/dashboard/data" &
PID[11]=$!

test_other_apis 12 "AITandoorTester" "AI & Tandoor" "/tandoor/status;/api/tandoor/recipes;/api/ai/score-recipe" &
PID[12]=$!

# Wait for all background jobs
echo -e "\n${BLUE}⏳ Waiting for all 12 agents to complete...${NC}\n"
for i in {1..12}; do
    wait ${PID[$i]}
done

# ============================================================================
# Aggregate Results
# ============================================================================
echo -e "\n${BLUE}📊 Aggregating Results...${NC}\n"

REPORT_FILE="$RESULTS_DIR/ENDPOINT_TEST_REPORT.json"

{
    echo "{"
    echo "  \"test_run\": \"$(date -u +%Y-%m-%dT%H:%M:%SZ)\","
    echo "  \"total_agents\": 12,"
    echo "  \"api_base\": \"$API_BASE\","
    echo "  \"agent_results\": ["

    for i in {1..12}; do
        results_file=$(ls "$RESULTS_DIR"/agent_${i}_*.json 2>/dev/null | head -1)
        if [ -f "$results_file" ]; then
            cat "$results_file"
            if [ $i -lt 12 ]; then echo ","; fi
        fi
    done

    echo "  ],"
    echo "  \"summary\": {"

    # Count results
    total_endpoints=$(find "$RESULTS_DIR" -name "agent_*.json" -exec grep -o '"endpoint"' {} \; | wc -l)
    success_endpoints=$(find "$RESULTS_DIR" -name "agent_*.json" -exec grep '"status_code": 2' {} \; | wc -l)

    echo "    \"total_endpoints_tested\": $total_endpoints,"
    echo "    \"successful_responses\": $success_endpoints,"
    echo "    \"timestamp\": \"$(date -u +%Y-%m-%dT%H:%M:%SZ)\""
    echo "  }"
    echo "}"
} > "$REPORT_FILE"

# ============================================================================
# Print Summary
# ============================================================================
echo -e "${GREEN}✅ All Tests Complete!${NC}\n"
echo -e "${BLUE}📈 Test Summary:${NC}"
echo "   Total endpoints tested: $total_endpoints"
echo "   Successful responses (2xx): $success_endpoints"
echo "   Results saved to: $REPORT_FILE"
echo ""
echo -e "${YELLOW}Full Report:${NC}"
cat "$REPORT_FILE" | jq '.' 2>/dev/null || cat "$REPORT_FILE"

exit 0
