#!/bin/bash

# Quick test for plate generation system
# Minimal tests to verify basic functionality

set -e

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

BACKEND_URL="http://localhost:5000"

echo -e "${BLUE}⚡ Quick Plate System Test${NC}"
echo "=========================="

# Function to check JSON success without jq
check_success() {
    if echo "$1" | grep -q '"success": *true'; then
        return 0
    else
        return 1
    fi
}

# Test 1: Backend health
echo -n "1. Backend Health: "
if curl -s --max-time 5 "$BACKEND_URL/api/health" > /dev/null 2>&1; then
    echo -e "${GREEN}✅ PASS${NC}"
else
    echo -e "${RED}❌ FAIL${NC}"
    echo -e "${YELLOW}Start backend: docker-compose up -d backend${NC}"
    exit 1
fi

# Test 2: Plate endpoints exist
echo -n "2. Plate Endpoints: "
response=$(curl -s --max-time 5 "$BACKEND_URL/api/plates/parameters" 2>/dev/null || echo "")
if [ -n "$response" ] && check_success "$response"; then
    echo -e "${GREEN}✅ PASS${NC}"
else
    echo -e "${RED}❌ FAIL${NC}"
    echo -e "${YELLOW}Module not installed. Run setup_plates.sh${NC}"
    exit 1
fi

# Test 3: Generate test noise
echo -n "3. Generate Noise: "
noise_response=$(curl -s --max-time 10 \
    -H "Content-Type: application/json" \
    -d '{"width":32,"height":32,"frequency":0.1,"seed":12345}' \
    "$BACKEND_URL/api/noise/worley" 2>/dev/null || echo "")

if [ -n "$noise_response" ] && check_success "$noise_response"; then
    echo -e "${GREEN}✅ PASS${NC}"
    # Extract noise data (basic extraction without jq)
    NOISE_DATA=$(echo "$noise_response" | sed -n 's/.*"image_data": *"\([^"]*\)".*/\1/p')
else
    echo -e "${RED}❌ FAIL${NC}"
    exit 1
fi

# Test 4: Generate plates
echo -n "4. Generate Plates: "
plate_payload=$(cat <<EOF
{
    "noise_data": "$NOISE_DATA",
    "grid_size": {"width": 30, "height": 30},
    "plate_sensitivity": 0.15,
    "min_plates": 4,
    "max_plates": 10,
    "complexity": "medium",
    "wrap_edges": false
}
EOF
)

plate_response=$(curl -s --max-time 20 \
    -H "Content-Type: application/json" \
    -d "$plate_payload" \
    "$BACKEND_URL/api/plates/generate" 2>/dev/null || echo "")

if [ -n "$plate_response" ] && check_success "$plate_response"; then
    echo -e "${GREEN}✅ PASS${NC}"
    
    # Extract plate count (basic extraction)
    plate_count=$(echo "$plate_response" | sed -n 's/.*"plate_count": *\([0-9]*\).*/\1/p')
    echo -e "${BLUE}   Generated ${plate_count:-?} plates${NC}"
else
    echo -e "${RED}❌ FAIL${NC}"
    echo "Response: ${plate_response:0:200}..."
    exit 1
fi

# Test 5: Error handling
echo -n "5. Error Handling: "
error_response=$(curl -s --max-time 5 \
    -H "Content-Type: application/json" \
    -d '{}' \
    "$BACKEND_URL/api/plates/generate" 2>/dev/null || echo "")

if [ -n "$error_response" ] && ! check_success "$error_response"; then
    echo -e "${GREEN}✅ PASS${NC} (correctly rejected)"
else
    echo -e "${RED}❌ FAIL${NC} (should have failed)"
fi

echo -e "\n${GREEN}🎉 Quick tests complete!${NC}"
echo -e "${BLUE}Run ./test_plates.sh for comprehensive testing${NC}"