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
    if echo "$RESPONSE" | grep -q '"success":\s*