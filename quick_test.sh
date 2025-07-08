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

# Test 1: Health Check
echo -n "1. Health Check: "
if curl -s --max-time 5 "$BACKEND_URL/api/health" | jq -e '.success' > /dev/null 2>&1; then
    echo -e "${GREEN}✅ PASS${NC}"
else
    echo -e "${RED}❌ FAIL${NC}"
    echo -e "${YELLOW}💡 Make sure backend is running: docker-compose up backend${NC}"
    exit 1
fi

# Test 2: Quick Perlin Generation
echo -n "2. Perlin Generation: "
perlin_payload='{"width":32,"height":32,"scale":0.05,"octaves":4,"seed":12345}'
if curl -s --max-time 10 -H "Content-Type: application/json" -d "$perlin_payload" "$BACKEND_URL/api/noise/perlin" | jq -e '.success' > /dev/null 2>&1; then
    echo -e "${GREEN}✅ PASS${NC}"
else
    echo -e "${RED}❌ FAIL${NC}"
    exit 1
fi

# Test 3: Quick Simplex Generation
echo -n "3. Simplex Generation: "
simplex_payload='{"width":32,"height":32,"scale":0.02,"octaves":5,"seed":12345}'
if curl -s --max-time 10 -H "Content-Type: application/json" -d "$simplex_payload" "$BACKEND_URL/api/noise/simplex" | jq -e '.success' > /dev/null 2>&1; then
    echo -e "${GREEN}✅ PASS${NC}"
else
    echo -e "${RED}❌ FAIL${NC}"
    exit 1
fi

# Test 4: Quick Worley Generation
echo -n "4. Worley Generation: "
worley_payload='{"width":32,"height":32,"frequency":0.1,"distance_function":"euclidean","cell_type":"F1","seed":12345}'
if curl -s --max-time 10 -H "Content-Type: application/json" -d "$worley_payload" "$BACKEND_URL/api/noise/worley" | jq -e '.success' > /dev/null 2>&1; then
    echo -e "${GREEN}✅ PASS${NC}"
else
    echo -e "${RED}❌ FAIL${NC}"
    exit 1
fi

# Test 5: Parameters Endpoint
echo -n "5. Parameters Endpoint: "
if curl -s --max-time 5 "$BACKEND_URL/api/noise/parameters" | jq -e '.success' > /dev/null 2>&1; then
    echo -e "${GREEN}✅ PASS${NC}"
else
    echo -e "${RED}❌ FAIL${NC}"
    exit 1
fi

echo ""
echo -e "${GREEN}🎉 All quick tests passed!${NC}"
echo -e "${BLUE}💡 Run './test_runner.sh' for comprehensive testing${NC}"