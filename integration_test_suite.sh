#!/bin/bash

# =====================================================
# TECTONIC GENERATOR INTEGRATION TEST SUITE v2.1
# End-to-end testing of the complete system
# =====================================================

set -euo pipefail

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
NC='\033[0m'

TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
TEST_DIR="tectonic_integration_${TIMESTAMP}"
BACKEND_URL="http://localhost:5000"
CONTAINER_NAME="tectonic-backend"
mkdir -p "$TEST_DIR"

echo "🔗 TECTONIC GENERATOR INTEGRATION TEST SUITE v2.1"
echo "=================================================="
echo "Timestamp: $TIMESTAMP"
echo ""

test_result() {
    local test_name="$1"
    local result="$2"
    local details="$3"
    
    if [ "$result" = "PASS" ]; then
        echo -e "✅ $test_name: ${GREEN}PASS${NC} - $details"
    elif [ "$result" = "WARN" ]; then
        echo -e "⚠️ $test_name: ${YELLOW}WARN${NC} - $details"
    else
        echo -e "❌ $test_name: ${RED}FAIL${NC} - $details"
    fi
    
    echo "$test_name: $result - $details" >> "$TEST_DIR/integration_results.log"
}

# =====================================================
# PHASE 1: SYSTEM READINESS VERIFICATION
# =====================================================
echo -e "${BLUE}📋 PHASE 1: System Readiness Verification${NC}"
echo "------------------------------------------"

# Check container status
echo "🔍 Verifying Tectonic Generator system status..."
if docker-compose ps | grep -q "Up.*tectonic-backend"; then
    test_result "Backend Container" "PASS" "Running and accessible"
else
    test_result "Backend Container" "FAIL" "Not running"
    echo "Starting Tectonic Generator..."
    docker-compose up -d > "$TEST_DIR/startup.log" 2>&1
    sleep 15
fi

# Wait for API to be ready
echo "⏳ Waiting for Tectonic Generator API to be ready..."
READY_ATTEMPTS=0
while [ $READY_ATTEMPTS -lt 30 ]; do
    if curl -s "$BACKEND_URL/api/health" | grep -q '"success":\s*true'; then
        test_result "API Readiness" "PASS" "API responding correctly"
        break
    fi
    sleep 2
    ((READY_ATTEMPTS++))
done

if [ $READY_ATTEMPTS -eq 30 ]; then
    test_result "API Readiness" "FAIL" "API not responding after 60 seconds"
fi

# Verify all critical endpoints are accessible
echo "🌐 Verifying critical endpoints..."
CRITICAL_ENDPOINTS=("api/health" "api/noise/parameters" "api/noise/presets")
ENDPOINT_FAILURES=0

for endpoint in "${CRITICAL_ENDPOINTS[@]}"; do
    HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" "$BACKEND_URL/$endpoint" 2>/dev/null || echo "000")
    if [ "$HTTP_CODE" = "200" ]; then
        test_result "Endpoint: $endpoint" "PASS" "HTTP 200"
    else
        test_result "Endpoint: $endpoint" "FAIL" "HTTP $HTTP_CODE"
        ((ENDPOINT_FAILURES++))
    fi
done

# =====================================================
# PHASE 2: COMPLETE WORKFLOW TESTING
# =====================================================
echo ""
echo -e "${BLUE}🔄 PHASE 2: Complete Workflow Testing${NC}"
echo "------------------------------------"

# Test complete workflow: Parameters → Presets → Generation → Validation
echo "🛠️ Testing complete noise generation workflow..."

# Step 1: Get parameters
echo "📋 Step 1: Retrieving parameters..."
PARAMS_RESPONSE=$(curl -s "$BACKEND_URL/api/noise/parameters" 2>/dev/null || echo "ERROR")
echo "$PARAMS_RESPONSE" > "$TEST_DIR/workflow_parameters.json"

if echo "$PARAMS_RESPONSE" | grep -q '"success":\s*true'; then
    test_result "Workflow Step 1: Parameters" "PASS" "Parameters retrieved successfully"
    
    # Verify parameter structure
    if echo "$PARAMS_RESPONSE" | grep -q "perlin.*simplex.*worley"; then
        test_result "Parameter Structure" "PASS" "All algorithm parameters present"
    else
        test_result "Parameter Structure" "WARN" "Limited parameter information"
    fi
else
    test_result "Workflow Step 1: Parameters" "FAIL" "Cannot retrieve parameters"
fi

# Step 2: Get presets
echo "🎨 Step 2: Retrieving presets..."
PRESETS_RESPONSE=$(curl -s "$BACKEND_URL/api/noise/presets" 2>/dev/null || echo "ERROR")
echo "$PRESETS_RESPONSE" > "$TEST_DIR/workflow_presets.json"

if echo "$PRESETS_RESPONSE" | grep -q '"success":\s*true'; then
    test_result "Workflow Step 2: Presets" "PASS" "Presets retrieved successfully"
else
    test_result "Workflow Step 2: Presets" "WARN" "Limited or missing presets"
fi

# Step 3: Generate noise with each algorithm
echo "🌊 Step 3: Testing complete generation workflow..."

ALGORITHMS=("perlin" "simplex" "worley")
PAYLOADS=(
    '{"size":{"width":64,"height":64},"scale":0.05,"octaves":4,"persistence":0.5,"lacunarity":2.0,"seed":12345}'
    '{"size":{"width":64,"height":64},"scale":0.02,"octaves":6,"persistence":0.4,"lacunarity":2.5,"seed":54321}'
    '{"size":{"width":64,"height":64},"frequency":0.1,"distance":"euclidean","cell_type":"F1","seed":98765}'
)

WORKFLOW_SUCCESS=0
for i in "${!ALGORITHMS[@]}"; do
    algo="${ALGORITHMS[$i]}"
    payload="${PAYLOADS[$i]}"
    
    echo "   Testing $algo workflow..."
    START_TIME=$(date +%s.%N)
    WORKFLOW_RESPONSE=$(curl -s -X POST -H "Content-Type: application/json" -d "$payload" "$BACKEND_URL/api/noise/$algo" 2>/dev/null || echo "ERROR")
    END_TIME=$(date +%s.%N)
    
    echo "$WORKFLOW_RESPONSE" > "$TEST_DIR/workflow_${algo}.json"
    
    if echo "$WORKFLOW_RESPONSE" | grep -q '"success":\s*true'; then
        GEN_TIME=$(echo "$END_TIME - $START_TIME" | bc -l 2>/dev/null || echo "0")
        test_result "Workflow $algo Generation" "PASS" "Generated in ${GEN_TIME}s"
        ((WORKFLOW_SUCCESS++))
        
        # Verify output contains expected fields
        EXPECTED_FIELDS=("data" "generation_time" "statistics")
        MISSING_FIELDS=0
        for field in "${EXPECTED_FIELDS[@]}"; do
            if ! echo "$WORKFLOW_RESPONSE" | grep -q "\"$field\":"; then
                ((MISSING_FIELDS++))
            fi
        done
        
        if [ $MISSING_FIELDS -eq 0 ]; then
            test_result "Workflow $algo Output" "PASS" "All expected fields present"
        else
            test_result "Workflow $algo Output" "WARN" "$MISSING_FIELDS fields missing"
        fi
    else
        test_result "Workflow $algo Generation" "FAIL" "Generation failed"
    fi
done

if [ $WORKFLOW_SUCCESS -eq 3 ]; then
    test_result "Complete Workflow" "PASS" "All algorithms working in workflow"
elif [ $WORKFLOW_SUCCESS -gt 0 ]; then
    test_result "Complete Workflow" "WARN" "$WORKFLOW_SUCCESS/3 algorithms working"
else
    test_result "Complete Workflow" "FAIL" "No algorithms working in workflow"
fi

# =====================================================
# PHASE 3: CROSS-ALGORITHM CONSISTENCY
# =====================================================
echo ""
echo -e "${BLUE}🔀 PHASE 3: Cross-Algorithm Consistency${NC}"
echo "--------------------------------------"

# Test consistency across algorithms
echo "📊 Testing cross-algorithm consistency..."

# Test same seed produces different but valid outputs across algorithms
COMMON_SEED=99999
CONSISTENCY_PAYLOADS=(
    "{\"size\":{\"width\":32,\"height\":32},\"scale\":0.05,\"octaves\":4,\"persistence\":0.5,\"lacunarity\":2.0,\"seed\":$COMMON_SEED}"
    "{\"size\":{\"width\":32,\"height\":32},\"scale\":0.02,\"octaves\":6,\"persistence\":0.4,\"lacunarity\":2.5,\"seed\":$COMMON_SEED}"
    "{\"size\":{\"width\":32,\"height\":32},\"frequency\":0.1,\"distance\":\"euclidean\",\"cell_type\":\"F1\",\"seed\":$COMMON_SEED}"
)

ALGORITHM_OUTPUTS=()
CONSISTENCY_SUCCESS=0

for i in "${!ALGORITHMS[@]}"; do
    algo="${ALGORITHMS[$i]}"
    payload="${CONSISTENCY_PAYLOADS[$i]}"
    
    CONSISTENCY_RESPONSE=$(curl -s -X POST -H "Content-Type: application/json" -d "$payload" "$BACKEND_URL/api/noise/$algo" 2>/dev/null || echo "ERROR")
    
    if echo "$CONSISTENCY_RESPONSE" | grep -q '"success":\s*true'; then
        # Extract data field
        DATA=$(echo "$CONSISTENCY_RESPONSE" | grep -o '"data":"[^"]*"' | cut -d'"' -f4)
        ALGORITHM_OUTPUTS+=("$DATA")
        ((CONSISTENCY_SUCCESS++))
        test_result "Consistency $algo Generation" "PASS" "Generated with common seed"
    else
        test_result "Consistency $algo Generation" "FAIL" "Failed to generate with common seed"
        ALGORITHM_OUTPUTS+=("")
    fi
done

# Verify that different algorithms produce different outputs (as expected)
if [ $CONSISTENCY_SUCCESS -eq 3 ]; then
    if [ "${ALGORITHM_OUTPUTS[0]}" != "${ALGORITHM_OUTPUTS[1]}" ] && [ "${ALGORITHM_OUTPUTS[1]}" != "${ALGORITHM_OUTPUTS[2]}" ] && [ "${ALGORITHM_OUTPUTS[0]}" != "${ALGORITHM_OUTPUTS[2]}" ]; then
        test_result "Algorithm Differentiation" "PASS" "Different algorithms produce different outputs"
    else
        test_result "Algorithm Differentiation" "FAIL" "Algorithms producing identical outputs"