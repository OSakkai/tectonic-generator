#!/bin/bash

# Tectonic Generator Test Runner Script
# Comprehensive testing for the entire system

set -e  # Exit on any error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
BACKEND_URL="http://localhost:5000"
FRONTEND_URL="http://localhost:3000"
TEST_OUTPUT_DIR="test_results"
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")

echo -e "${BLUE}🧪 Tectonic Generator Test Runner${NC}"
echo "=================================================="
echo "Timestamp: $(date)"
echo "Backend URL: $BACKEND_URL"
echo "Frontend URL: $FRONTEND_URL"
echo "Output Directory: $TEST_OUTPUT_DIR"
echo ""

# Create output directory
mkdir -p "$TEST_OUTPUT_DIR"

# Function to check if service is running
check_service() {
    local url=$1
    local name=$2
    local timeout=30
    local count=0
    
    echo -e "${YELLOW}⏳ Checking $name connection...${NC}"
    
    while [ $count -lt $timeout ]; do
        if curl -s --max-time 5 "$url" > /dev/null 2>&1; then
            echo -e "${GREEN}✅ $name is responding${NC}"
            return 0
        fi
        
        echo -n "."
        sleep 2
        count=$((count + 1))
    done
    
    echo -e "${RED}❌ $name not responding after ${timeout} seconds${NC}"
    return 1
}

# Function to run docker containers if needed
start_containers() {
    echo -e "${YELLOW}🐳 Checking Docker containers...${NC}"
    
    if ! docker ps | grep -q "tectonic_backend"; then
        echo -e "${YELLOW}⚡ Starting backend container...${NC}"
        docker-compose up -d backend
        sleep 10
    else
        echo -e "${GREEN}✅ Backend container already running${NC}"
    fi
    
    if ! docker ps | grep -q "tectonic_frontend"; then
        echo -e "${YELLOW}⚡ Starting frontend container...${NC}"
        docker-compose up -d frontend
        sleep 15
    else
        echo -e "${GREEN}✅ Frontend container already running${NC}"
    fi
}

# Function to run backend API tests
test_backend_api() {
    echo -e "${BLUE}🔧 Testing Backend API Endpoints${NC}"
    echo "----------------------------------"
    
    # Health check
    echo -n "Health endpoint: "
    if curl -s --max-time 10 "$BACKEND_URL/api/health" | jq -e '.success' > /dev/null 2>&1; then
        echo -e "${GREEN}✅ PASS${NC}"
    else
        echo -e "${RED}❌ FAIL${NC}"
        return 1
    fi
    
    # Parameters endpoint
    echo -n "Parameters endpoint: "
    if curl -s --max-time 10 "$BACKEND_URL/api/noise/parameters" | jq -e '.success' > /dev/null 2>&1; then
        echo -e "${GREEN}✅ PASS${NC}"
    else
        echo -e "${RED}❌ FAIL${NC}"
        return 1
    fi
    
    # Presets endpoint
    echo -n "Presets endpoint: "
    if curl -s --max-time 10 "$BACKEND_URL/api/noise/presets" | jq -e '.success' > /dev/null 2>&1; then
        echo -e "${GREEN}✅ PASS${NC}"
    else
        echo -e "${RED}❌ FAIL${NC}"
        return 1
    fi
    
    # Test Perlin generation
    echo -n "Perlin generation: "
    perlin_payload='{"width":64,"height":64,"scale":0.05,"octaves":4,"seed":12345}'
    if curl -s --max-time 30 -H "Content-Type: application/json" -d "$perlin_payload" "$BACKEND_URL/api/noise/perlin" | jq -e '.success' > /dev/null 2>&1; then
        echo -e "${GREEN}✅ PASS${NC}"
    else
        echo -e "${RED}❌ FAIL${NC}"
        return 1
    fi
    
    # Test Simplex generation
    echo -n "Simplex generation: "
    simplex_payload='{"width":64,"height":64,"scale":0.02,"octaves":5,"seed":12345}'
    if curl -s --max-time 30 -H "Content-Type: application/json" -d "$simplex_payload" "$BACKEND_URL/api/noise/simplex" | jq -e '.success' > /dev/null 2>&1; then
        echo -e "${GREEN}✅ PASS${NC}"
    else
        echo -e "${RED}❌ FAIL${NC}"
        return 1
    fi
    
    # Test Worley generation
    echo -n "Worley generation: "
    worley_payload='{"width":64,"height":64,"frequency":0.1,"distance_function":"euclidean","cell_type":"F1","seed":12345}'
    if curl -s --max-time 30 -H "Content-Type: application/json" -d "$worley_payload" "$BACKEND_URL/api/noise/worley" | jq -e '.success' > /dev/null 2>&1; then
        echo -e "${GREEN}✅ PASS${NC}"
    else
        echo -e "${RED}❌ FAIL${NC}"
        return 1
    fi
    
    # Test error handling
    echo -n "Error handling: "
    invalid_payload='{"width":64,"height":64,"scale":999,"octaves":50}'
    if curl -s --max-time 10 -H "Content-Type: application/json" -d "$invalid_payload" "$BACKEND_URL/api/noise/perlin" | jq -e '.success == false' > /dev/null 2>&1; then
        echo -e "${GREEN}✅ PASS${NC}"
    else
        echo -e "${RED}❌ FAIL${NC}"
        return 1
    fi
    
    echo -e "${GREEN}🎉 All backend API tests passed!${NC}"
    return 0
}

# Function to test frontend connectivity
test_frontend() {
    echo -e "${BLUE}🖥️  Testing Frontend${NC}"
    echo "--------------------"
    
    echo -n "Frontend accessibility: "
    if curl -s --max-time 10 "$FRONTEND_URL" > /dev/null 2>&1; then
        echo -e "${GREEN}✅ PASS${NC}"
    else
        echo -e "${RED}❌ FAIL${NC}"
        return 1
    fi
    
    echo -e "${GREEN}🎉 Frontend tests passed!${NC}"
    return 0
}

# Function to run performance tests
test_performance() {
    echo -e "${BLUE}⚡ Performance Tests${NC}"
    echo "--------------------"
    
    # Test different resolutions
    resolutions=("64,64" "128,128" "256,256" "512,512")
    
    for res in "${resolutions[@]}"; do
        width=$(echo $res | cut -d',' -f1)
        height=$(echo $res | cut -d',' -f2)
        
        echo -n "Testing ${width}x${height}: "
        
        payload="{\"width\":$width,\"height\":$height,\"scale\":0.05,\"octaves\":4,\"seed\":12345}"
        
        start_time=$(date +%s.%N)
        response=$(curl -s --max-time 60 -H "Content-Type: application/json" -d "$payload" "$BACKEND_URL/api/noise/perlin")
        end_time=$(date +%s.%N)
        
        if echo "$response" | jq -e '.success' > /dev/null 2>&1; then
            duration=$(echo "$end_time - $start_time" | bc)
            generation_time=$(echo "$response" | jq -r '.generation_time')
            echo -e "${GREEN}✅ PASS${NC} (${duration}s total, ${generation_time}s generation)"
        else
            echo -e "${RED}❌ FAIL${NC}"
            return 1
        fi
    done
    
    echo -e "${GREEN}🎉 All performance tests passed!${NC}"
    return 0
}

# Function to run comprehensive Python test suite
run_python_tests() {
    echo -e "${BLUE}🐍 Running Python Test Suite${NC}"
    echo "------------------------------"
    
    cd backend
    
    # Check if test file exists
    if [ ! -f "tests/test_complete_suite.py" ]; then
        echo -e "${RED}❌ Test file not found: tests/test_complete_suite.py${NC}"
        return 1
    fi
    
    # Run the comprehensive test suite
    if python tests/test_complete_suite.py --api-url "$BACKEND_URL" --output "../$TEST_OUTPUT_DIR/test_results_$TIMESTAMP.json"; then
        echo -e "${GREEN}🎉 Python test suite passed!${NC}"
        cd ..
        return 0
    else
        echo -e "${RED}❌ Python test suite failed!${NC}"
        cd ..
        return 1
    fi
}

# Function to save system information
save_system_info() {
    echo -e "${BLUE}📋 Saving System Information${NC}"
    
    cat > "$TEST_OUTPUT_DIR/system_info_$TIMESTAMP.txt" << EOF
Tectonic Generator System Information
=====================================
Date: $(date)
Test Run ID: $TIMESTAMP

Docker Information:
-------------------
$(docker --version)
$(docker-compose --version)

Container Status:
----------------
$(docker ps --filter "name=tectonic" --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}")

Backend Health:
--------------
$(curl -s "$BACKEND_URL/api/health" | jq '.' 2>/dev/null || echo "Backend not responding")

System Resources:
----------------
Memory: $(free -h | grep '^Mem:' | awk '{print $3 "/" $2}')
Disk: $(df -h . | tail -1 | awk '{print $3 "/" $2 " (" $5 " used)"}')
CPU: $(nproc) cores

Network Tests:
-------------
Backend ping: $(curl -s -o /dev/null -w "%{time_total}" "$BACKEND_URL/api/health" 2>/dev/null || echo "FAILED")s
Frontend ping: $(curl -s -o /dev/null -w "%{time_total}" "$FRONTEND_URL" 2>/dev/null || echo "FAILED")s

EOF
}

# Function to generate test report
generate_test_report() {
    echo -e "${BLUE}📊 Generating Test Report${NC}"
    
    report_file="$TEST_OUTPUT_DIR/test_report_$TIMESTAMP.html"
    
    cat > "$report_file" << EOF
<!DOCTYPE html>
<html>
<head>
    <title>Tectonic Generator Test Report</title>
    <style>
        body { font-family: Arial, sans-serif; margin: 40px; }
        .header { background: #2563eb; color: white; padding: 20px; border-radius: 8px; }
        .section { margin: 20px 0; padding: 15px; border: 1px solid #ddd; border-radius: 8px; }
        .pass { color: #10b981; font-weight: bold; }
        .fail { color: #ef4444; font-weight: bold; }
        .warning { color: #f59e0b; font-weight: bold; }
        pre { background: #f8fafc; padding: 10px; border-radius: 4px; overflow-x: auto; }
        .timestamp { color: #64748b; font-size: 0.9em; }
    </style>
</head>
<body>
    <div class="header">
        <h1>🧪 Tectonic Generator Test Report</h1>
        <p class="timestamp">Generated: $(date)</p>
        <p class="timestamp">Test Run ID: $TIMESTAMP</p>
    </div>
    
    <div class="section">
        <h2>📋 Test Summary</h2>
        <p>This report contains the results of comprehensive testing for the Tectonic Generator system.</p>
        <ul>
            <li><strong>Backend API Tests:</strong> Core functionality and endpoint validation</li>
            <li><strong>Frontend Tests:</strong> User interface accessibility</li>
            <li><strong>Performance Tests:</strong> Speed and efficiency benchmarks</li>
            <li><strong>Algorithm Tests:</strong> Noise generation algorithms validation</li>
        </ul>
    </div>
    
    <div class="section">
        <h2>🔧 System Configuration</h2>
        <pre>$(cat "$TEST_OUTPUT_DIR/system_info_$TIMESTAMP.txt")</pre>
    </div>
    
    <div class="section">
        <h2>📊 Detailed Results</h2>
        <p>For detailed test results, see the JSON output file: <code>test_results_$TIMESTAMP.json</code></p>
    </div>
    
    <div class="section">
        <h2>🏁 Conclusion</h2>
        <p>Test execution completed. Check individual test results above for any failures that need attention.</p>
    </div>
</body>
</html>
EOF
    
    echo "📄 HTML report generated: $report_file"
}

# Function to cleanup test artifacts
cleanup() {
    echo -e "${YELLOW}🧹 Cleaning up test artifacts...${NC}"
    
    # Remove temporary files if any
    rm -f /tmp/tectonic_test_*
    
    echo -e "${GREEN}✅ Cleanup completed${NC}"
}

# Function to show usage
show_usage() {
    echo "Usage: $0 [OPTIONS]"
    echo ""
    echo "Options:"
    echo "  --backend-only     Run only backend tests"
    echo "  --frontend-only    Run only frontend tests"
    echo "  --performance      Run only performance tests"
    echo "  --no-docker        Don't start Docker containers"
    echo "  --output-dir DIR   Custom output directory"
    echo "  --backend-url URL  Custom backend URL"
    echo "  --frontend-url URL Custom frontend URL"
    echo "  --help             Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0                           # Run all tests"
    echo "  $0 --backend-only           # Run only backend tests"
    echo "  $0 --performance            # Run only performance tests"
    echo "  $0 --no-docker              # Skip Docker container startup"
}

# Parse command line arguments
BACKEND_ONLY=false
FRONTEND_ONLY=false
PERFORMANCE_ONLY=false
NO_DOCKER=false

while [[ $# -gt 0 ]]; do
    case $1 in
        --backend-only)
            BACKEND_ONLY=true
            shift
            ;;
        --frontend-only)
            FRONTEND_ONLY=true
            shift
            ;;
        --performance)
            PERFORMANCE_ONLY=true
            shift
            ;;
        --no-docker)
            NO_DOCKER=true
            shift
            ;;
        --output-dir)
            TEST_OUTPUT_DIR="$2"
            shift 2
            ;;
        --backend-url)
            BACKEND_URL="$2"
            shift 2
            ;;
        --frontend-url)
            FRONTEND_URL="$2"
            shift 2
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

# Main execution
main() {
    echo -e "${BLUE}🚀 Starting Test Execution${NC}"
    echo ""
    
    # Check dependencies
    echo -e "${YELLOW}🔍 Checking dependencies...${NC}"
    
    if ! command -v curl &> /dev/null; then
        echo -e "${RED}❌ curl is required but not installed${NC}"
        exit 1
    fi
    
    if ! command -v jq &> /dev/null; then
        echo -e "${RED}❌ jq is required but not installed${NC}"
        exit 1
    fi
    
    if ! command -v docker &> /dev/null; then
        echo -e "${RED}❌ docker is required but not installed${NC}"
        exit 1
    fi
    
    if ! command -v docker-compose &> /dev/null; then
        echo -e "${RED}❌ docker-compose is required but not installed${NC}"
        exit 1
    fi
    
    echo -e "${GREEN}✅ All dependencies found${NC}"
    
    # Start containers if needed
    if [ "$NO_DOCKER" = false ]; then
        start_containers
    fi
    
    # Wait for services to be ready
    if [ "$FRONTEND_ONLY" = false ]; then
        if ! check_service "$BACKEND_URL/api/health" "Backend"; then
            echo -e "${RED}❌ Backend service not available${NC}"
            exit 1
        fi
    fi
    
    if [ "$BACKEND_ONLY" = false ] && [ "$PERFORMANCE_ONLY" = false ]; then
        if ! check_service "$FRONTEND_URL" "Frontend"; then
            echo -e "${YELLOW}⚠️  Frontend service not available (skipping frontend tests)${NC}"
            FRONTEND_ONLY=false
        fi
    fi
    
    # Save system information
    save_system_info
    
    # Initialize test results
    overall_success=true
    
    # Run tests based on options
    if [ "$PERFORMANCE_ONLY" = true ]; then
        echo -e "\n${BLUE}🎯 Running Performance Tests Only${NC}"
        if ! test_performance; then
            overall_success=false
        fi
    elif [ "$BACKEND_ONLY" = true ]; then
        echo -e "\n${BLUE}🎯 Running Backend Tests Only${NC}"
        if ! test_backend_api; then
            overall_success=false
        fi
        if ! run_python_tests; then
            overall_success=false
        fi
    elif [ "$FRONTEND_ONLY" = true ]; then
        echo -e "\n${BLUE}🎯 Running Frontend Tests Only${NC}"
        if ! test_frontend; then
            overall_success=false
        fi
    else
        echo -e "\n${BLUE}🎯 Running Complete Test Suite${NC}"
        
        # Backend tests
        if ! test_backend_api; then
            overall_success=false
        fi
        
        # Python test suite
        if ! run_python_tests; then
            overall_success=false
        fi
        
        # Frontend tests
        if ! test_frontend; then
            overall_success=false
        fi
        
        # Performance tests
        if ! test_performance; then
            overall_success=false
        fi
    fi
    
    # Generate report
    generate_test_report
    
    # Cleanup
    cleanup
    
    # Final results
    echo ""
    echo "=================================================="
    if [ "$overall_success" = true ]; then
        echo -e "${GREEN}🎉 ALL TESTS PASSED!${NC}"
        echo -e "${GREEN}✅ Tectonic Generator is working correctly${NC}"
        exit 0
    else
        echo -e "${RED}❌ SOME TESTS FAILED!${NC}"
        echo -e "${RED}⚠️  Check the test output above for details${NC}"
        echo -e "${YELLOW}📁 Test results saved in: $TEST_OUTPUT_DIR/${NC}"
        exit 1
    fi
}

# Trap to ensure cleanup on exit
trap cleanup EXIT

# Run main function
main "$@"