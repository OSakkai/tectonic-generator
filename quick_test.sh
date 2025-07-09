#!/bin/bash

# Quick Test Script for Tectonic Generator
# Fast validation of core functionality

set -e

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

BACKEND_URL="http://localhost:5000"

echo -e "${BLUE}⚡ Tectonic Generator Quick Test${NC}"
echo "================================"

# Function to check JSON success without jq dependency
check_json_success() {
    local response="$1"
    if echo "$response" | grep -q '"success": *true'; then
        return 0
    else
        return 1
    fi
}

# Test 1: Health Check
echo -n "1. Health Check: "
health_response=$(curl -s --max-time 5 "$BACKEND_URL/api/health" 2>/dev/null || echo "")
if [ -n "$health_response" ] && check_json_success "$health_response"; then
    echo -e "${GREEN}✅ PASS${NC}"
else
    echo -e "${RED}❌ FAIL${NC}"
    echo -e "${YELLOW}💡 Make sure backend is running: docker-compose up backend${NC}"
    exit 1
fi

# Test 2: Quick Perlin Generation
echo -n "2. Perlin Generation: "
perlin_payload='{"width":32,"height":32,"scale":0.05,"octaves":4,"seed":12345}'
perlin_response=$(curl -s --max-time 10 -H "Content-Type: application/json" -d "$perlin_payload" "$BACKEND_URL/api/noise/perlin" 2>/dev/null || echo "")
if [ -n "$perlin_response" ] && check_json_success "$perlin_response"; then
    echo -e "${GREEN}✅ PASS${NC}"
else
    echo -e "${RED}❌ FAIL${NC}"
    exit 1
fi

# Test 3: Quick Simplex Generation
echo -n "3. Simplex Generation: "
simplex_payload='{"width":32,"height":32,"scale":0.02,"octaves":5,"seed":12345}'
simplex_response=$(curl -s --max-time 10 -H "Content-Type: application/json" -d "$simplex_payload" "$BACKEND_URL/api/noise/simplex" 2>/dev/null || echo "")
if [ -n "$simplex_response" ] && check_json_success "$simplex_response"; then
    echo -e "${GREEN}✅ PASS${NC}"
else
    echo -e "${RED}❌ FAIL${NC}"
    exit 1
fi

# Test 4: Quick Worley Generation
echo -n "4. Worley Generation: "
worley_payload='{"width":32,"height":32,"frequency":0.1,"distance_function":"euclidean","cell_type":"F1","seed":12345}'
worley_response=$(curl -s --max-time 10 -H "Content-Type: application/json" -d "$worley_payload" "$BACKEND_URL/api/noise/worley" 2>/dev/null || echo "")
if [ -n "$worley_response" ] && check_json_success "$worley_response"; then
    echo -e "${GREEN}✅ PASS${NC}"
else
    echo -e "${RED}❌ FAIL${NC}"
    exit 1
fi

# Test 5: Parameters Endpoint
echo -n "5. Parameters Endpoint: "
params_response=$(curl -s --max-time 5 "$BACKEND_URL/api/noise/parameters" 2>/dev/null || echo "")
if [ -n "$params_response" ] && check_json_success "$params_response"; then
    echo -e "${GREEN}✅ PASS${NC}"
else
    echo -e "${RED}❌ FAIL${NC}"
    exit 1
fi

# Test 6: Performance Check
echo -n "6. Performance Check: "
start_time=$(date +%s.%N)
perf_response=$(curl -s --max-time 15 -H "Content-Type: application/json" -d '{"width":128,"height":128,"scale":0.05,"octaves":4,"seed":12345}' "$BACKEND_URL/api/noise/perlin" 2>/dev/null || echo "")
end_time=$(date +%s.%N)
if [ -n "$perf_response" ] && check_json_success "$perf_response"; then
    duration=$(echo "$end_time - $start_time" | bc -l 2>/dev/null || echo "unknown")
    echo -e "${GREEN}✅ PASS${NC} (${duration}s)"
else
    echo -e "${RED}❌ FAIL${NC}"
    exit 1
fi

echo ""
echo -e "${GREEN}🎉 All quick tests passed!${NC}"
echo -e "${BLUE}💡 Run './test_runner.sh' for comprehensive testing${NC}"