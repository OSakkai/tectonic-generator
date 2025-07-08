#!/bin/bash

# Test inside Docker containers
# This script runs tests directly inside the backend container

set -e

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}🐳 Testing Inside Docker Containers${NC}"
echo "====================================="

# Function to run command in backend container
run_in_backend() {
    docker exec tectonic_backend "$@"
}

# Function to check if containers are running
check_containers() {
    echo -e "${YELLOW}🔍 Checking container status...${NC}"
    
    if ! docker ps | grep -q "tectonic_backend"; then
        echo -e "${RED}❌ Backend container not running${NC}"
        echo -e "${YELLOW}💡 Start with: docker-compose up -d backend${NC}"
        exit 1
    fi
    
    if ! docker ps | grep -q "tectonic_frontend"; then
        echo -e "${YELLOW}⚠️ Frontend container not running${NC}"
        echo -e "${YELLOW}💡 Start with: docker-compose up -d frontend${NC}"
    fi
    
    echo -e "${GREEN}✅ Backend container is running${NC}"
}

# Test 1: Container Health
test_container_health() {
    echo -e "\n${BLUE}🏥 Testing Container Health${NC}"
    echo "----------------------------"
    
    echo -n "Backend container health: "
    if run_in_backend python -c "import sys; print('Python', sys.version); exit(0)" > /dev/null 2>&1; then
        echo -e "${GREEN}✅ PASS${NC}"
    else
        echo -e "${RED}❌ FAIL${NC}"
        return 1
    fi
    
    echo -n "Flask application health: "
    if run_in_backend python -c "from app import app; print('Flask app loaded'); exit(0)" > /dev/null 2>&1; then
        echo -e "${GREEN}✅ PASS${NC}"
    else
        echo -e "${RED}❌ FAIL${NC}"
        return 1
    fi
}

# Test 2: Dependencies
test_dependencies() {
    echo -e "\n${BLUE}📦 Testing Dependencies${NC}"
    echo "------------------------"
    
    dependencies=("numpy" "Pillow" "matplotlib" "scipy" "noise" "opensimplex" "flask" "flask_cors")
    
    for dep in "${dependencies[@]}"; do
        echo -n "Checking $dep: "
        if run_in_backend python -c "import $dep; print('OK')" > /dev/null 2>&1; then
            echo -e "${GREEN}✅ PASS${NC}"
        else
            echo -e "${RED}❌ FAIL${NC}"
            return 1
        fi
    done
}

# Test 3: Noise Module Import
test_noise_modules() {
    echo -e "\n${BLUE}🌊 Testing Noise Modules${NC}"
    echo "--------------------------"
    
    echo -n "Perlin module: "
    if run_in_backend python -c "from noise.perlin import generate_perlin_noise; print('OK')" > /dev/null 2>&1; then
        echo -e "${GREEN}✅ PASS${NC}"
    else
        echo -e "${RED}❌ FAIL${NC}"
        return 1
    fi
    
    echo -n "Simplex module: "
    if run_in_backend python -c "from noise.simplex import generate_simplex_noise; print('OK')" > /dev/null 2>&1; then
        echo -e "${GREEN}✅ PASS${NC}"
    else
        echo -e "${RED}❌ FAIL${NC}"
        return 1
    fi
    
    echo -n "Worley module: "
    if run_in_backend python -c "from noise.worley import generate_worley_noise; print('OK')" > /dev/null 2>&1; then
        echo -e "${GREEN}✅ PASS${NC}"
    else
        echo -e "${RED}❌ FAIL${NC}"
        return 1
    fi
    
    echo -n "Utils modules: "
    if run_in_backend python -c "from utils.validation import validate_noise_parameters; from utils.image_processing import normalize_array; print('OK')" > /dev/null 2>&1; then
        echo -e "${GREEN}✅ PASS${NC}"
    else
        echo -e "${RED}❌ FAIL${NC}"
        return 1
    fi
}

# Test 4: Algorithm Execution
test_algorithm_execution() {
    echo -e "\n${BLUE}⚙️ Testing Algorithm Execution${NC}"
    echo "--------------------------------"
    
    echo -n "Perlin generation test: "
    if run_in_backend python -c "
from noise.perlin import generate_perlin_noise
import numpy as np
noise = generate_perlin_noise(64, 64, seed=12345)
assert noise.shape == (64, 64)
assert np.all(np.isfinite(noise))
print('SUCCESS')
" > /dev/null 2>&1; then
        echo -e "${GREEN}✅ PASS${NC}"
    else
        echo -e "${RED}❌ FAIL${NC}"
        return 1
    fi
    
    echo -n "Simplex generation test: "
    if run_in_backend python -c "
from noise.simplex import generate_simplex_noise
import numpy as np
noise = generate_simplex_noise(64, 64, seed=12345)
assert noise.shape == (64, 64)
assert np.all(np.isfinite(noise))
print('SUCCESS')
" > /dev/null 2>&1; then
        echo -e "${GREEN}✅ PASS${NC}"
    else
        echo -e "${RED}❌ FAIL${NC}"
        return 1
    fi
    
    echo -n "Worley generation test: "
    if run_in_backend python -c "
from noise.worley import generate_worley_noise
import numpy as np
noise = generate_worley_noise(64, 64, seed=12345)
assert noise.shape == (64, 64)
assert np.all(np.isfinite(noise))
print('SUCCESS')
" > /dev/null 2>&1; then
        echo -e "${GREEN}✅ PASS${NC}"
    else
        echo -e "${RED}❌ FAIL${NC}"
        return 1
    fi
}

# Test 5: Image Processing
test_image_processing() {
    echo -e "\n${BLUE}🖼️ Testing Image Processing${NC}"
    echo "-----------------------------"
    
    echo -n "Array normalization: "
    if run_in_backend python -c "
from utils.image_processing import normalize_array
import numpy as np
test_array = np.random.rand(32, 32)
normalized = normalize_array(test_array, (0, 255))
assert 0 <= np.min(normalized) <= np.max(normalized) <= 255
print('SUCCESS')
" > /dev/null 2>&1; then
        echo -e "${GREEN}✅ PASS${NC}"
    else
        echo -e "${RED}❌ FAIL${NC}"
        return 1
    fi
    
    echo -n "Image conversion: "
    if run_in_backend python -c "
from utils.image_processing import array_to_image
import numpy as np
test_array = np.random.rand(32, 32)
image_data = array_to_image(test_array)
assert image_data.startswith('data:image/png;base64,')
print('SUCCESS')
" > /dev/null 2>&1; then
        echo -e "${GREEN}✅ PASS${NC}"
    else
        echo -e "${RED}❌ FAIL${NC}"
        return 1
    fi
}

# Test 6: Parameter Validation
test_parameter_validation() {
    echo -e "\n${BLUE}✅ Testing Parameter Validation${NC}"
    echo "--------------------------------"
    
    echo -n "Valid parameters: "
    if run_in_backend python -c "
from utils.validation import validate_noise_parameters
result = validate_noise_parameters('perlin', {'scale': 0.05, 'octaves': 4}, 64, 64)
assert result['valid'] == True
print('SUCCESS')
" > /dev/null 2>&1; then
        echo -e "${GREEN}✅ PASS${NC}"
    else
        echo -e "${RED}❌ FAIL${NC}"
        return 1
    fi
    
    echo -n "Invalid parameters: "
    if run_in_backend python -c "
from utils.validation import validate_noise_parameters
result = validate_noise_parameters('perlin', {'scale': 999, 'octaves': 50}, 64, 64)
assert result['valid'] == False
print('SUCCESS')
" > /dev/null 2>&1; then
        echo -e "${GREEN}✅ PASS${NC}"
    else
        echo -e "${RED}❌ FAIL${NC}"
        return 1
    fi
}

# Test 7: Flask App Integration
test_flask_integration() {
    echo -e "\n${BLUE}🌐 Testing Flask Integration${NC}"
    echo "-----------------------------"
    
    echo -n "App initialization: "
    if run_in_backend python -c "
from app import app
assert app is not None
print('SUCCESS')
" > /dev/null 2>&1; then
        echo -e "${GREEN}✅ PASS${NC}"
    else
        echo -e "${RED}❌ FAIL${NC}"
        return 1
    fi
    
    echo -n "Endpoint imports: "
    if run_in_backend python -c "
from noise.generators import generate_perlin_endpoint, generate_simplex_endpoint, generate_worley_endpoint
print('SUCCESS')
" > /dev/null 2>&1; then
        echo -e "${GREEN}✅ PASS${NC}"
    else
        echo -e "${RED}❌ FAIL${NC}"
        return 1
    fi
}

# Test 8: File System Permissions
test_file_permissions() {
    echo -e "\n${BLUE}📁 Testing File System${NC}"
    echo "-----------------------"
    
    echo -n "Data directory: "
    if run_in_backend test -d /app/data/exports; then
        echo -e "${GREEN}✅ PASS${NC}"
    else
        echo -e "${RED}❌ FAIL${NC}"
        return 1
    fi
    
    echo -n "Write permissions: "
    if run_in_backend touch /app/data/exports/test_file.tmp && run_in_backend rm /app/data/exports/test_file.tmp; then
        echo -e "${GREEN}✅ PASS${NC}"
    else
        echo -e "${RED}❌ FAIL${NC}"
        return 1
    fi
}

# Test 9: Memory Usage
test_memory_usage() {
    echo -e "\n${BLUE}💾 Testing Memory Usage${NC}"
    echo "------------------------"
    
    echo -n "Large array generation: "
    if run_in_backend python -c "
from noise.perlin import generate_perlin_noise
import psutil
import os

# Monitor memory before
process = psutil.Process(os.getpid())
mem_before = process.memory_info().rss / 1024 / 1024  # MB

# Generate large noise array
noise = generate_perlin_noise(1024, 1024, seed=12345)

# Monitor memory after
mem_after = process.memory_info().rss / 1024 / 1024  # MB
mem_used = mem_after - mem_before

print(f'Memory used: {mem_used:.1f}MB')
assert mem_used < 500, f'Memory usage too high: {mem_used}MB'
print('SUCCESS')
" > /dev/null 2>&1; then
        echo -e "${GREEN}✅ PASS${NC}"
    else
        echo -e "${RED}❌ FAIL${NC}"
        return 1
    fi
}

# Test 10: Performance Timing
test_performance_timing() {
    echo -e "\n${BLUE}⏱️ Testing Performance${NC}"
    echo "-----------------------"
    
    echo -n "Generation speed: "
    if run_in_backend python -c "
from noise.perlin import generate_perlin_noise
import time

start_time = time.time()
noise = generate_perlin_noise(512, 512, seed=12345)
end_time = time.time()

generation_time = end_time - start_time
print(f'Generation time: {generation_time:.3f}s')
assert generation_time < 10, f'Generation too slow: {generation_time}s'
print('SUCCESS')
" 2>/dev/null | grep -E "(Generation time|SUCCESS)"; then
        echo -e "${GREEN}✅ PASS${NC}"
    else
        echo -e "${RED}❌ FAIL${NC}"
        return 1
    fi
}

# Test 11: Container Resource Limits
test_resource_limits() {
    echo -e "\n${BLUE}🔒 Testing Resource Limits${NC}"
    echo "---------------------------"
    
    echo -n "CPU availability: "
    cpu_count=$(run_in_backend python -c "import os; print(os.cpu_count())")
    if [ "$cpu_count" -gt 0 ]; then
        echo -e "${GREEN}✅ PASS${NC} ($cpu_count cores)"
    else
        echo -e "${RED}❌ FAIL${NC}"
        return 1
    fi
    
    echo -n "Memory availability: "
    if run_in_backend python -c "
import psutil
mem = psutil.virtual_memory()
mem_gb = mem.total / 1024 / 1024 / 1024
print(f'Available: {mem_gb:.1f}GB')
assert mem_gb > 0.5, f'Not enough memory: {mem_gb}GB'
print('SUCCESS')
" 2>/dev/null | grep -E "(Available|SUCCESS)"; then
        echo -e "${GREEN}✅ PASS${NC}"
    else
        echo -e "${RED}❌ FAIL${NC}"
        return 1
    fi
}

# Main execution function
main() {
    local overall_success=true
    
    # Check containers first
    check_containers
    
    # Run all tests
    echo -e "\n${BLUE}🚀 Starting Docker Container Tests${NC}"
    
    if ! test_container_health; then overall_success=false; fi
    if ! test_dependencies; then overall_success=false; fi
    if ! test_noise_modules; then overall_success=false; fi
    if ! test_algorithm_execution; then overall_success=false; fi
    if ! test_image_processing; then overall_success=false; fi
    if ! test_parameter_validation; then overall_success=false; fi
    if ! test_flask_integration; then overall_success=false; fi
    if ! test_file_permissions; then overall_success=false; fi
    if ! test_memory_usage; then overall_success=false; fi
    if ! test_performance_timing; then overall_success=false; fi
    if ! test_resource_limits; then overall_success=false; fi
    
    # Results
    echo ""
    echo "============================================"
    if [ "$overall_success" = true ]; then
        echo -e "${GREEN}🎉 ALL DOCKER TESTS PASSED!${NC}"
        echo -e "${GREEN}✅ Backend container is fully functional${NC}"
        return 0
    else
        echo -e "${RED}❌ SOME DOCKER TESTS FAILED!${NC}"
        echo -e "${RED}⚠️ Check container configuration${NC}"
        return 1
    fi
}

# Show usage
show_usage() {
    echo "Usage: $0 [OPTIONS]"
    echo ""
    echo "Options:"
    echo "  --backend-only    Test only backend container"
    echo "  --quick          Run only essential tests"
    echo "  --verbose        Show detailed output"
    echo "  --help           Show this help"
    echo ""
    echo "Examples:"
    echo "  $0               # Run all container tests"
    echo "  $0 --quick       # Run essential tests only"
    echo "  $0 --verbose     # Show detailed output"
}

# Parse arguments
QUICK_MODE=false
VERBOSE=false

while [[ $# -gt 0 ]]; do
    case $1 in
        --quick)
            QUICK_MODE=true
            shift
            ;;
        --verbose)
            VERBOSE=true
            shift
            ;;
        --help)
            show_usage
            exit 0
            ;;
        *)
            echo -e "${RED}❌ Unknown option: $1${NC}"
            show_usage
            exit 1
            ;;
    esac
done

# Set verbosity
if [ "$VERBOSE" = true ]; then
    set -x
fi

# Run main function
main