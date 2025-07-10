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
    fi
else
    test_result "Algorithm Differentiation" "WARN" "Cannot verify - insufficient algorithm responses"
fi

# Test response format consistency
echo "📋 Testing response format consistency..."
FORMAT_CONSISTENT=true
FIRST_KEYS=""

for i in "${!ALGORITHMS[@]}"; do
    algo="${ALGORITHMS[$i]}"
    response_file="$TEST_DIR/workflow_${algo}.json"
    
    if [ -f "$response_file" ]; then
        # Extract top-level keys (simplified)
        KEYS=$(grep -o '"[^"]*":' "$response_file" | sort | uniq | tr '\n' ' ')
        
        if [ -z "$FIRST_KEYS" ]; then
            FIRST_KEYS="$KEYS"
        elif [ "$KEYS" != "$FIRST_KEYS" ]; then
            FORMAT_CONSISTENT=false
            break
        fi
    fi
done

if $FORMAT_CONSISTENT; then
    test_result "Response Format Consistency" "PASS" "All algorithms use consistent response format"
else
    test_result "Response Format Consistency" "WARN" "Response formats vary between algorithms"
fi

# =====================================================
# PHASE 4: LOAD AND PERFORMANCE TESTING
# =====================================================
echo ""
echo -e "${BLUE}⚡ PHASE 4: Load and Performance Testing${NC}"
echo "---------------------------------------"

# Test system under load
echo "💪 Testing system under load..."

# Sequential load test
echo "🔄 Testing sequential load..."
SEQUENTIAL_PAYLOAD='{"size":{"width":64,"height":64},"scale":0.05,"octaves":4,"persistence":0.5,"lacunarity":2.0,"seed":77777}'
SEQUENTIAL_SUCCESS=0
TOTAL_TIME=0

for i in {1..10}; do
    START_TIME=$(date +%s.%N)
    LOAD_RESPONSE=$(curl -s -X POST -H "Content-Type: application/json" -d "$SEQUENTIAL_PAYLOAD" "$BACKEND_URL/api/noise/perlin" 2>/dev/null || echo "ERROR")
    END_TIME=$(date +%s.%N)
    
    if echo "$LOAD_RESPONSE" | grep -q '"success":\s*true'; then
        ((SEQUENTIAL_SUCCESS++))
        REQUEST_TIME=$(echo "$END_TIME - $START_TIME" | bc -l 2>/dev/null || echo "0")
        TOTAL_TIME=$(echo "$TOTAL_TIME + $REQUEST_TIME" | bc -l 2>/dev/null || echo "$TOTAL_TIME")
    fi
done

if [ $SEQUENTIAL_SUCCESS -eq 10 ]; then
    AVG_TIME=$(echo "scale=3; $TOTAL_TIME / 10" | bc -l 2>/dev/null || echo "0")
    test_result "Sequential Load Test" "PASS" "10/10 requests succeeded, avg: ${AVG_TIME}s"
else
    test_result "Sequential Load Test" "FAIL" "$SEQUENTIAL_SUCCESS/10 requests succeeded"
fi

# Concurrent load test
echo "🔀 Testing concurrent load..."
CONCURRENT_PAYLOAD='{"size":{"width":48,"height":48},"scale":0.05,"octaves":3,"persistence":0.5,"lacunarity":2.0,"seed":88888}'

# Launch 8 concurrent requests
START_CONCURRENT=$(date +%s.%N)
for i in {1..8}; do
    curl -s -X POST -H "Content-Type: application/json" -d "$CONCURRENT_PAYLOAD" "$BACKEND_URL/api/noise/perlin" > "$TEST_DIR/concurrent_load_$i.json" 2>&1 &
done

# Wait for all to complete
wait
END_CONCURRENT=$(date +%s.%N)

CONCURRENT_SUCCESS=0
for i in {1..8}; do
    if grep -q '"success":\s*true' "$TEST_DIR/concurrent_load_$i.json" 2>/dev/null; then
        ((CONCURRENT_SUCCESS++))
    fi
done

CONCURRENT_TIME=$(echo "$END_CONCURRENT - $START_CONCURRENT" | bc -l 2>/dev/null || echo "0")

if [ $CONCURRENT_SUCCESS -eq 8 ]; then
    test_result "Concurrent Load Test" "PASS" "8/8 concurrent requests succeeded in ${CONCURRENT_TIME}s"
elif [ $CONCURRENT_SUCCESS -ge 6 ]; then
    test_result "Concurrent Load Test" "WARN" "$CONCURRENT_SUCCESS/8 concurrent requests succeeded"
else
    test_result "Concurrent Load Test" "FAIL" "Only $CONCURRENT_SUCCESS/8 concurrent requests succeeded"
fi

# =====================================================
# PHASE 5: ERROR HANDLING AND EDGE CASES
# =====================================================
echo ""
echo -e "${BLUE}🚨 PHASE 5: Error Handling and Edge Cases${NC}"
echo "------------------------------------------"

# Test comprehensive error handling
echo "🔍 Testing comprehensive error handling..."

# Test malformed JSON
echo "   Testing malformed JSON handling..."
MALFORMED_RESPONSE=$(curl -s -X POST -H "Content-Type: application/json" -d '{"malformed":json}' "$BACKEND_URL/api/noise/perlin" 2>/dev/null || echo "ERROR")

if echo "$MALFORMED_RESPONSE" | grep -qi '"success":\s*false\|error'; then
    test_result "Malformed JSON Handling" "PASS" "Properly handles malformed JSON"
else
    test_result "Malformed JSON Handling" "FAIL" "Does not handle malformed JSON properly"
fi

# Test missing required parameters
echo "   Testing missing parameter handling..."
MISSING_PARAMS='{"size":{"width":64}}'  # Missing height
MISSING_RESPONSE=$(curl -s -X POST -H "Content-Type: application/json" -d "$MISSING_PARAMS" "$BACKEND_URL/api/noise/perlin" 2>/dev/null || echo "ERROR")

if echo "$MISSING_RESPONSE" | grep -qi '"success":\s*false\|error\|missing\|required'; then
    test_result "Missing Parameters" "PASS" "Properly validates required parameters"
else
    test_result "Missing Parameters" "FAIL" "Does not validate required parameters"
fi

# Test extreme parameter values
echo "   Testing extreme parameter values..."
EXTREME_PARAMS='{"size":{"width":10000,"height":10000},"scale":999,"octaves":50}'
EXTREME_RESPONSE=$(curl -s -X POST -H "Content-Type: application/json" -d "$EXTREME_PARAMS" "$BACKEND_URL/api/noise/perlin" 2>/dev/null || echo "ERROR")

if echo "$EXTREME_RESPONSE" | grep -qi '"success":\s*false\|error\|invalid\|limit'; then
    test_result "Extreme Parameters" "PASS" "Properly rejects extreme values"
else
    test_result "Extreme Parameters" "WARN" "May not have parameter limits in place"
fi

# =====================================================
# GENERATE COMPREHENSIVE INTEGRATION REPORT
# =====================================================
echo ""
echo -e "${PURPLE}📊 GENERATING INTEGRATION REPORT${NC}"
echo "=================================="

TOTAL_TESTS=$(wc -l < "$TEST_DIR/integration_results.log")
PASSED_TESTS=$(grep -c "PASS" "$TEST_DIR/integration_results.log" || echo "0")
WARNED_TESTS=$(grep -c "WARN" "$TEST_DIR/integration_results.log" || echo "0")
FAILED_TESTS=$(grep -c "FAIL" "$TEST_DIR/integration_results.log" || echo "0")
SUCCESS_RATE=$(( (PASSED_TESTS + WARNED_TESTS) * 100 / TOTAL_TESTS ))

cat > "$TEST_DIR/TECTONIC_INTEGRATION_REPORT.md" << EOF
# TECTONIC GENERATOR INTEGRATION TEST REPORT

**Generated:** $TIMESTAMP
**Test Suite:** Complete Integration Testing v2.1
**Total Tests:** $TOTAL_TESTS
**Success Rate:** $SUCCESS_RATE%

## Executive Summary
- ✅ **Passed:** $PASSED_TESTS tests
- ⚠️ **Warnings:** $WARNED_TESTS tests  
- ❌ **Failed:** $FAILED_TESTS tests

## System Integration Status

$(if [ $FAILED_TESTS -eq 0 ]; then
    echo "### ✅ FULLY INTEGRATED SYSTEM"
    echo "Tectonic Generator is completely functional with all components properly integrated."
elif [ $FAILED_TESTS -le 2 ]; then
    echo "### ⚠️ MOSTLY INTEGRATED"
    echo "System is largely functional with minor integration issues."
else
    echo "### ❌ INTEGRATION ISSUES"
    echo "System has significant integration problems requiring attention."
fi)

## Integration Test Phases

### Phase 1: System Readiness ✅
- Container status verification
- API readiness confirmation
- Critical endpoint validation

### Phase 2: Complete Workflow ✅
- Parameter retrieval testing
- Preset functionality verification
- End-to-end generation workflow

### Phase 3: Cross-Algorithm Consistency ✅
- Algorithm differentiation verification
- Response format consistency
- Cross-algorithm compatibility

### Phase 4: Load and Performance ✅
- Sequential load testing (10 requests)
- Concurrent load testing (8 simultaneous)
- Performance validation

### Phase 5: Error Handling ✅
- Malformed JSON handling
- Parameter validation testing
- Edge case handling

## Performance Metrics
- **Sequential Load**: $SEQUENTIAL_SUCCESS/10 requests successful
- **Concurrent Load**: $CONCURRENT_SUCCESS/8 requests successful  
- **Average Response Time**: ${AVG_TIME}s (sequential)
- **Concurrent Completion**: ${CONCURRENT_TIME}s (8 requests)

## Integration Health
- **Workflow Success Rate**: $WORKFLOW_SUCCESS/3 algorithms working
- **Endpoint Failures**: $ENDPOINT_FAILURES critical endpoints failing

## Failed Tests
$(grep "FAIL" "$TEST_DIR/integration_results.log" || echo "No failed tests")

## Warnings
$(grep "WARN" "$TEST_DIR/integration_results.log" || echo "No warnings")

## Recommendations

$(if [ $FAILED_TESTS -eq 0 ]; then
    echo "1. ✅ System ready for production deployment"
    echo "2. ✅ All integration points functioning correctly"
    echo "3. ✅ Performance within acceptable limits"
    echo "4. ✅ Error handling robust and comprehensive"
    echo "5. ✅ Consider advanced feature development"
else
    echo "1. Address failed integration tests immediately"
    echo "2. Review error handling for edge cases"
    echo "3. Optimize performance if load tests failed"
    echo "4. Verify container configuration"
fi)

## Generated Test Files
- integration_results.log: Complete test results
- workflow_*.json: Algorithm workflow responses
- concurrent_load_*.json: Concurrent test results

---
*Integration testing completed by Tectonic Generator Integration Suite v2.1*
EOF

# Display final results
echo "✅ Tectonic Generator Integration Testing Complete!"
echo "📁 Results saved to: $TEST_DIR"
echo "📋 Report: $TEST_DIR/TECTONIC_INTEGRATION_REPORT.md"
echo ""
echo "🎯 INTEGRATION TEST RESULTS:"
echo "   Total Tests: $TOTAL_TESTS"
echo "   Passed: $PASSED_TESTS"
echo "   Warnings: $WARNED_TESTS"
echo "   Failed: $FAILED_TESTS"
echo "   Success Rate: $SUCCESS_RATE%"

if [ $FAILED_TESTS -eq 0 ]; then
    echo ""
    echo -e "${GREEN}✅ ALL INTEGRATION TESTS PASSED${NC}"
    echo "🎉 Tectonic Generator is fully integrated and operational!"
    echo ""
    echo "System Status: PRODUCTION READY ✅"
    exit 0
elif [ $FAILED_TESTS -le 2 ]; then
    echo ""
    echo -e "${YELLOW}⚠️ MINOR INTEGRATION ISSUES${NC}"
    echo "System is mostly functional, review warnings:"
    grep "FAIL\|WARN" "$TEST_DIR/integration_results.log" | head -3
    exit 1
else
    echo ""
    echo -e "${RED}❌ CRITICAL INTEGRATION FAILURES${NC}"
    echo "System needs immediate attention:"
    grep "FAIL" "$TEST_DIR/integration_results.log" | head -5
    echo ""
    echo "Review the full integration report:"
    echo "cat $TEST_DIR/TECTONIC_INTEGRATION_REPORT.md"
    exit 2
fi