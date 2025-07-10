#!/bin/bash

# =====================================================
# TECTONIC GENERATOR ALGORITHM-SPECIFIC TESTS v2.1
# Deep testing of noise algorithms and performance
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
TEST_DIR="tectonic_algorithm_test_${TIMESTAMP}"
BACKEND_URL="http://localhost:5000"
CONTAINER_NAME="tectonic-backend"
mkdir -p "$TEST_DIR"

echo "🌍 TECTONIC GENERATOR ALGORITHM-SPECIFIC TESTS v2.1"
echo "===================================================="
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
    
    echo "$test_name: $result - $details" >> "$TEST_DIR/algorithm_results.log"
}

# =====================================================
# TEST 1: ALGORITHM MODULE INTEGRITY
# =====================================================
echo -e "${BLUE}🔍 TEST 1: Algorithm Module Integrity${NC}"
echo "------------------------------------"

# Check if all algorithm modules are present and functional
if docker exec "$CONTAINER_NAME" python -c "
import sys
sys.path.insert(0, '/app')

print('=== TECTONIC NOISE MODULE INTEGRITY ===')

# Test individual algorithm imports
algorithms = ['perlin', 'simplex', 'worley', 'generators']
for algo in algorithms:
    try:
        module = __import__(f'tectonic_noise.{algo}', fromlist=[algo])
        print(f'✅ {algo}: Module imported successfully')
    except Exception as e:
        print(f'❌ {algo}: Import failed - {e}')

# Test class instantiation
try:
    from tectonic_noise.perlin import PerlinNoise
    perlin = PerlinNoise()
    print('✅ PerlinNoise: Class instantiation successful')
except Exception as e:
    print(f'❌ PerlinNoise: Instantiation failed - {e}')

try:
    from tectonic_noise.simplex import SimplexNoise
    simplex = SimplexNoise()
    print('✅ SimplexNoise: Class instantiation successful')
except Exception as e:
    print(f'❌ SimplexNoise: Instantiation failed - {e}')

try:
    from tectonic_noise.worley import WorleyNoise
    worley = WorleyNoise()
    print('✅ WorleyNoise: Class instantiation successful')
except Exception as e:
    print(f'❌ WorleyNoise: Instantiation failed - {e}')

# Test generators module
try:
    from tectonic_noise import generators
    print('✅ generators: Module accessible')
    
    # Check if main functions exist
    functions = ['generate_perlin', 'generate_simplex', 'generate_worley']
    for func in functions:
        if hasattr(generators, func):
            print(f'✅ {func}: Function available')
        else:
            print(f'❌ {func}: Function missing')
except Exception as e:
    print(f'❌ generators: Module failed - {e}')
" > "$TEST_DIR/module_integrity.log" 2>&1; then
    
    # Analyze results
    SUCCESS_COUNT=$(grep -c "✅" "$TEST_DIR/module_integrity.log" || echo "0")
    FAIL_COUNT=$(grep -c "❌" "$TEST_DIR/module_integrity.log" || echo "0")
    
    if [ "$FAIL_COUNT" -eq 0 ]; then
        test_result "Module Integrity" "PASS" "All modules and classes functional ($SUCCESS_COUNT components)"
    elif [ "$SUCCESS_COUNT" -gt "$FAIL_COUNT" ]; then
        test_result "Module Integrity" "WARN" "$SUCCESS_COUNT working, $FAIL_COUNT failed"
    else
        test_result "Module Integrity" "FAIL" "$FAIL_COUNT failures, $SUCCESS_COUNT working"
    fi
else
    test_result "Module Integrity" "FAIL" "Cannot access container for testing"
fi

# =====================================================
# TEST 2: ALGORITHM PARAMETER VALIDATION
# =====================================================
echo ""
echo -e "${BLUE}📏 TEST 2: Algorithm Parameter Validation${NC}"
echo "-------------------------------------------"

# Test parameter constraints for each algorithm
echo "🧪 Testing Perlin parameter constraints..."

# Valid parameters
VALID_PERLIN='{"size":{"width":64,"height":64},"scale":0.05,"octaves":4,"persistence":0.5,"lacunarity":2.0,"seed":12345}'
PERLIN_RESPONSE=$(curl -s -X POST -H "Content-Type: application/json" -d "$VALID_PERLIN" "$BACKEND_URL/api/noise/perlin" 2>/dev/null || echo "ERROR")

if echo "$PERLIN_RESPONSE" | grep -q '"success":\s*true'; then
    test_result "Perlin Valid Parameters" "PASS" "Accepts valid parameter set"
else
    test_result "Perlin Valid Parameters" "FAIL" "Rejects valid parameters"
fi

# Invalid scale (outside range 0.001-0.1)
INVALID_PERLIN='{"size":{"width":64,"height":64},"scale":99,"octaves":4,"persistence":0.5,"lacunarity":2.0}'
INVALID_RESPONSE=$(curl -s -X POST -H "Content-Type: application/json" -d "$INVALID_PERLIN" "$BACKEND_URL/api/noise/perlin" 2>/dev/null || echo "ERROR")

if echo "$INVALID_RESPONSE" | grep -q '"success":\s*false\|error'; then
    test_result "Perlin Parameter Validation" "PASS" "Properly rejects invalid scale"
else
    test_result "Perlin Parameter Validation" "FAIL" "Does not validate scale range"
fi

# Test Simplex constraints
echo "🔀 Testing Simplex parameter constraints..."

VALID_SIMPLEX='{"size":{"width":64,"height":64},"scale":0.02,"octaves":6,"persistence":0.4,"lacunarity":2.5,"seed":54321}'
SIMPLEX_RESPONSE=$(curl -s -X POST -H "Content-Type: application/json" -d "$VALID_SIMPLEX" "$BACKEND_URL/api/noise/simplex" 2>/dev/null || echo "ERROR")

if echo "$SIMPLEX_RESPONSE" | grep -q '"success":\s*true'; then
    test_result "Simplex Valid Parameters" "PASS" "Accepts valid parameter set"
else
    test_result "Simplex Valid Parameters" "FAIL" "Rejects valid parameters"
fi

# Test Worley constraints
echo "🕸️ Testing Worley parameter constraints..."

VALID_WORLEY='{"size":{"width":64,"height":64},"frequency":0.1,"distance":"euclidean","cell_type":"F1","seed":98765}'
WORLEY_RESPONSE=$(curl -s -X POST -H "Content-Type: application/json" -d "$VALID_WORLEY" "$BACKEND_URL/api/noise/worley" 2>/dev/null || echo "ERROR")

if echo "$WORLEY_RESPONSE" | grep -q '"success":\s*true'; then
    test_result "Worley Valid Parameters" "PASS" "Accepts valid parameter set"
else
    test_result "Worley Valid Parameters" "FAIL" "Rejects valid parameters"
fi

# Test invalid distance metric
INVALID_WORLEY='{"size":{"width":64,"height":64},"frequency":0.1,"distance":"invalid_metric","cell_type":"F1"}'
INVALID_WORLEY_RESPONSE=$(curl -s -X POST -H "Content-Type: application/json" -d "$INVALID_WORLEY" "$BACKEND_URL/api/noise/worley" 2>/dev/null || echo "ERROR")

if echo "$INVALID_WORLEY_RESPONSE" | grep -q '"success":\s*false\|error'; then
    test_result "Worley Distance Validation" "PASS" "Rejects invalid distance metric"
else
    test_result "Worley Distance Validation" "FAIL" "Does not validate distance metric"
fi

# =====================================================
# TEST 3: ALGORITHM OUTPUT VALIDATION
# =====================================================
echo ""
echo -e "${BLUE}🎨 TEST 3: Algorithm Output Validation${NC}"
echo "-------------------------------------"

# Test output format consistency
echo "📊 Testing output data format..."

for algorithm in "perlin" "simplex" "worley"; do
    case $algorithm in
        "perlin")
            PAYLOAD="$VALID_PERLIN"
            ;;
        "simplex")
            PAYLOAD="$VALID_SIMPLEX"
            ;;
        "worley")
            PAYLOAD="$VALID_WORLEY"
            ;;
    esac
    
    RESPONSE=$(curl -s -X POST -H "Content-Type: application/json" -d "$PAYLOAD" "$BACKEND_URL/api/noise/$algorithm" 2>/dev/null || echo "ERROR")
    echo "$RESPONSE" > "$TEST_DIR/${algorithm}_output.json"
    
    # Check response structure
    if echo "$RESPONSE" | grep -q '"success":\s*true'; then
        # Check for required fields
        REQUIRED_FIELDS=("data" "message" "generation_time")
        MISSING_FIELDS=0
        
        for field in "${REQUIRED_FIELDS[@]}"; do
            if ! echo "$RESPONSE" | grep -q "\"$field\":"; then
                ((MISSING_FIELDS++))
            fi
        done
        
        if [ $MISSING_FIELDS -eq 0 ]; then
            test_result "$algorithm Output Format" "PASS" "All required fields present"
        else
            test_result "$algorithm Output Format" "WARN" "$MISSING_FIELDS required fields missing"
        fi
        
        # Check if data contains base64 image
        if echo "$RESPONSE" | grep -q '"data":\s*"[A-Za-z0-9+/=]'; then
            test_result "$algorithm Base64 Data" "PASS" "Contains base64 encoded image"
        else
            test_result "$algorithm Base64 Data" "FAIL" "Missing or invalid base64 data"
        fi
        
        # Extract and validate generation time
        GEN_TIME=$(echo "$RESPONSE" | grep -o '"generation_time":[0-9.]*' | cut -d':' -f2 || echo "999")
        if (( $(echo "$GEN_TIME < 1.0" | bc -l 2>/dev/null || echo "0") )); then
            test_result "$algorithm Generation Time" "PASS" "${GEN_TIME}s (under 1 second)"
        else
            test_result "$algorithm Generation Time" "WARN" "${GEN_TIME}s (slower than expected)"
        fi
    else
        test_result "$algorithm Output Format" "FAIL" "Generation failed or invalid response"
    fi
done

# =====================================================
# TEST 4: REPRODUCIBILITY AND SEED TESTING
# =====================================================
echo ""
echo -e "${BLUE}🔄 TEST 4: Reproducibility and Seed Testing${NC}"
echo "--------------------------------------------"

# Test that same seed produces same output
echo "🌱 Testing seed reproducibility..."

SEED_PAYLOAD='{"size":{"width":32,"height":32},"scale":0.05,"octaves":4,"persistence":0.5,"lacunarity":2.0,"seed":42}'

# Generate twice with same seed
FIRST_RESPONSE=$(curl -s -X POST -H "Content-Type: application/json" -d "$SEED_PAYLOAD" "$BACKEND_URL/api/noise/perlin" 2>/dev/null || echo "ERROR")
sleep 1
SECOND_RESPONSE=$(curl -s -X POST -H "Content-Type: application/json" -d "$SEED_PAYLOAD" "$BACKEND_URL/api/noise/perlin" 2>/dev/null || echo "ERROR")

# Extract data portions
FIRST_DATA=$(echo "$FIRST_RESPONSE" | grep -o '"data":"[^"]*"' | cut -d'"' -f4 || echo "")
SECOND_DATA=$(echo "$SECOND_RESPONSE" | grep -o '"data":"[^"]*"' | cut -d'"' -f4 || echo "")

if [ "$FIRST_DATA" = "$SECOND_DATA" ] && [ -n "$FIRST_DATA" ]; then
    test_result "Seed Reproducibility" "PASS" "Same seed produces identical output"
else
    test_result "Seed Reproducibility" "FAIL" "Same seed produces different output"
fi

# Test that different seeds produce different output
DIFFERENT_SEED_PAYLOAD='{"size":{"width":32,"height":32},"scale":0.05,"octaves":4,"persistence":0.5,"lacunarity":2.0,"seed":123}'
DIFFERENT_RESPONSE=$(curl -s -X POST -H "Content-Type: application/json" -d "$DIFFERENT_SEED_PAYLOAD" "$BACKEND_URL/api/noise/perlin" 2>/dev/null || echo "ERROR")
DIFFERENT_DATA=$(echo "$DIFFERENT_RESPONSE" | grep -o '"data":"[^"]*"' | cut -d'"' -f4 || echo "")

if [ "$FIRST_DATA" != "$DIFFERENT_DATA" ] && [ -n "$DIFFERENT_DATA" ]; then
    test_result "Seed Variation" "PASS" "Different seeds produce different output"
else
    test_result "Seed Variation" "FAIL" "Different seeds produce same output"
fi

# =====================================================
# TEST 5: PERFORMANCE BENCHMARKING
# =====================================================
echo ""
echo -e "${BLUE}⚡ TEST 5: Performance Benchmarking${NC}"
echo "----------------------------------"

# Test performance across different resolutions
echo "📏 Testing performance across resolutions..."

RESOLUTIONS=("32:32" "64:64" "128:128" "256:256")
TARGETS=(50 50 200 1000)  # Target times in ms

for i in "${!RESOLUTIONS[@]}"; do
    RES="${RESOLUTIONS[$i]}"
    TARGET="${TARGETS[$i]}"
    WIDTH="${RES%:*}"
    HEIGHT="${RES#*:}"
    
    PERF_PAYLOAD="{\"size\":{\"width\":$WIDTH,\"height\":$HEIGHT},\"scale\":0.05,\"octaves\":4,\"persistence\":0.5,\"lacunarity\":2.0,\"seed\":12345}"
    
    # Run performance test
    START_TIME=$(date +%s.%N)
    PERF_RESPONSE=$(curl -s -X POST -H "Content-Type: application/json" -d "$PERF_PAYLOAD" "$BACKEND_URL/api/noise/perlin" 2>/dev/null || echo "ERROR")
    END_TIME=$(date +%s.%N)
    
    ACTUAL_TIME=$(echo "$END_TIME - $START_TIME" | bc -l 2>/dev/null || echo "999")
    ACTUAL_MS=$(echo "$ACTUAL_TIME * 1000" | bc -l 2>/dev/null || echo "999999")
    
    if echo "$PERF_RESPONSE" | grep -q '"success":\s*true'; then
        if (( $(echo "$ACTUAL_MS < $TARGET" | bc -l 2>/dev/null || echo "0") )); then
            test_result "Performance ${WIDTH}x${HEIGHT}" "PASS" "${ACTUAL_MS}ms (target: <${TARGET}ms)"
        elif (( $(echo "$ACTUAL_MS < $TARGET * 2" | bc -l 2>/dev/null || echo "0") )); then
            test_result "Performance ${WIDTH}x${HEIGHT}" "WARN" "${ACTUAL_MS}ms (target: <${TARGET}ms)"
        else
            test_result "Performance ${WIDTH}x${HEIGHT}" "FAIL" "${ACTUAL_MS}ms (target: <${TARGET}ms)"
        fi
    else
        test_result "Performance ${WIDTH}x${HEIGHT}" "FAIL" "Generation failed"
    fi
done

# =====================================================
# TEST 6: STRESS TESTING
# =====================================================
echo ""
echo -e "${BLUE}💪 TEST 6: Stress Testing${NC}"
echo "-------------------------"

# Test concurrent requests
echo "🔀 Testing concurrent request handling..."

CONCURRENT_PAYLOAD='{"size":{"width":64,"height":64},"scale":0.05,"octaves":4,"persistence":0.5,"lacunarity":2.0,"seed":99999}'

# Launch 5 concurrent requests
for i in {1..5}; do
    curl -s -X POST -H "Content-Type: application/json" -d "$CONCURRENT_PAYLOAD" "$BACKEND_URL/api/noise/perlin" > "$TEST_DIR/concurrent_$i.json" 2>&1 &
done

# Wait for all requests to complete
wait

# Check results
CONCURRENT_SUCCESS=0
for i in {1..5}; do
    if grep -q '"success":\s*true' "$TEST_DIR/concurrent_$i.json" 2>/dev/null; then
        ((CONCURRENT_SUCCESS++))
    fi
done

if [ $CONCURRENT_SUCCESS -eq 5 ]; then
    test_result "Concurrent Requests" "PASS" "All 5 concurrent requests succeeded"
elif [ $CONCURRENT_SUCCESS -ge 3 ]; then
    test_result "Concurrent Requests" "WARN" "$CONCURRENT_SUCCESS/5 concurrent requests succeeded"
else
    test_result "Concurrent Requests" "FAIL" "Only $CONCURRENT_SUCCESS/5 concurrent requests succeeded"
fi

# Test rapid sequential requests
echo "🏃 Testing rapid sequential requests..."
RAPID_SUCCESS=0
for i in {1..10}; do
    RAPID_RESPONSE=$(curl -s -X POST -H "Content-Type: application/json" -d "$CONCURRENT_PAYLOAD" "$BACKEND_URL/api/noise/perlin" 2>/dev/null || echo "ERROR")
    if echo "$RAPID_RESPONSE" | grep -q '"success":\s*true'; then
        ((RAPID_SUCCESS++))
    fi
done

if [ $RAPID_SUCCESS -eq 10 ]; then
    test_result "Rapid Sequential Requests" "PASS" "All 10 rapid requests succeeded"
elif [ $RAPID_SUCCESS -ge 8 ]; then
    test_result "Rapid Sequential Requests" "WARN" "$RAPID_SUCCESS/10 rapid requests succeeded"
else
    test_result "Rapid Sequential Requests" "FAIL" "Only $RAPID_SUCCESS/10 rapid requests succeeded"
fi

# =====================================================
# GENERATE ALGORITHM TEST REPORT
# =====================================================
echo ""
echo -e "${PURPLE}📊 GENERATING ALGORITHM TEST REPORT${NC}"
echo "==================================="

TOTAL_TESTS=$(wc -l < "$TEST_DIR/algorithm_results.log")
PASSED_TESTS=$(grep -c "PASS" "$TEST_DIR/algorithm_results.log" || echo "0")
WARNED_TESTS=$(grep -c "WARN" "$TEST_DIR/algorithm_results.log" || echo "0")
FAILED_TESTS=$(grep -c "FAIL" "$TEST_DIR/algorithm_results.log" || echo "0")
SUCCESS_RATE=$(( (PASSED_TESTS + WARNED_TESTS) * 100 / TOTAL_TESTS ))

cat > "$TEST_DIR/ALGORITHM_TEST_REPORT.md" << EOF
# TECTONIC GENERATOR ALGORITHM TEST REPORT

**Generated:** $TIMESTAMP
**Test Suite:** Algorithm-Specific Testing v2.1
**Total Tests:** $TOTAL_TESTS
**Success Rate:** $SUCCESS_RATE%

## Summary
- ✅ **Passed:** $PASSED_TESTS tests
- ⚠️ **Warnings:** $WARNED_TESTS tests
- ❌ **Failed:** $FAILED_TESTS tests

## Algorithm Health Assessment

$(if [ $FAILED_TESTS -eq 0 ]; then
    echo "### ✅ ALL ALGORITHMS HEALTHY"
    echo "All noise generation algorithms are functioning optimally."
elif [ $FAILED_TESTS -le 2 ]; then
    echo "### ⚠️ MINOR ALGORITHM ISSUES"
    echo "Algorithms are mostly functional with minor optimization needed."
else
    echo "### ❌ ALGORITHM ISSUES DETECTED"
    echo "Significant algorithm problems requiring immediate attention."
fi)

## Test Categories Completed

### Test 1: Module Integrity ✅
- Algorithm module imports
- Class instantiation
- Function availability verification

### Test 2: Parameter Validation ✅
- Constraint enforcement
- Invalid parameter rejection
- Range validation

### Test 3: Output Validation ✅
- Response format consistency
- Base64 image generation
- Required field presence

### Test 4: Reproducibility ✅
- Seed-based deterministic output
- Consistent generation verification
- Variation with different seeds

### Test 5: Performance Benchmarking ✅
- Multi-resolution performance
- Target time validation
- Scalability assessment

### Test 6: Stress Testing ✅
- Concurrent request handling
- Rapid sequential processing
- System stability under load

## Performance Summary
Based on resolution testing:
- **Small (32x32)**: Target <50ms
- **Medium (64x64)**: Target <50ms  
- **Large (128x128)**: Target <200ms
- **XL (256x256)**: Target <1000ms

## Failed Tests
$(grep "FAIL" "$TEST_DIR/algorithm_results.log" || echo "No failed tests")

## Warnings
$(grep "WARN" "$TEST_DIR/algorithm_results.log" || echo "No warnings")

## Recommendations

$(if [ $FAILED_TESTS -eq 0 ]; then
    echo "1. ✅ All algorithms performing within specifications"
    echo "2. ✅ Consider advanced feature development"
    echo "3. ✅ Ready for production algorithm usage"
    echo "4. ✅ Performance optimizations successful"
else
    echo "1. Address failed algorithm tests immediately"
    echo "2. Review parameter validation for edge cases"  
    echo "3. Optimize performance for larger resolutions"
    echo "4. Verify preset configurations"
fi)

## Generated Files
- algorithm_results.log: Complete test results
- module_integrity.log: Module analysis
- *_output.json: Algorithm responses
- concurrent_*.json: Stress test results

---
*Algorithm testing completed by Tectonic Generator Test Suite v2.1*
EOF

echo "✅ Algorithm Testing Complete!"
echo "📁 Results saved to: $TEST_DIR"
echo "📋 Report: $TEST_DIR/ALGORITHM_TEST_REPORT.md"
echo ""
echo "🎯 ALGORITHM TEST RESULTS:"
echo "   Total Tests: $TOTAL_TESTS"
echo "   Passed: $PASSED_TESTS"
echo "   Warnings: $WARNED_TESTS"
echo "   Failed: $FAILED_TESTS"
echo "   Success Rate: $SUCCESS_RATE%"

if [ $FAILED_TESTS -eq 0 ]; then
    echo ""
    echo -e "${GREEN}✅ ALL ALGORITHM TESTS PASSED${NC}"
    echo "🎉 All noise generation algorithms are fully functional!"
    exit 0
elif [ $FAILED_TESTS -le 2 ]; then
    echo ""
    echo -e "${YELLOW}⚠️ MINOR ALGORITHM ISSUES${NC}"
    echo "Most algorithms working, review warnings:"
    grep "FAIL\|WARN" "$TEST_DIR/algorithm_results.log" | head -3
    exit 1
else
    echo ""
    echo -e "${RED}❌ CRITICAL ALGORITHM FAILURES${NC}"
    echo "Algorithm system needs attention:"
    grep "FAIL" "$TEST_DIR/algorithm_results.log" | head -5
    exit 2
fi