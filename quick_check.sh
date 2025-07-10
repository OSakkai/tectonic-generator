#!/bin/bash

# =====================================================
# TECTONIC GENERATOR QUICK VERIFICATION SCRIPT
# Fast system check before running full test suite
# =====================================================

set -euo pipefail

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo "🔍 TECTONIC GENERATOR QUICK VERIFICATION"
echo "========================================"
echo ""

check_result() {
    local check_name="$1"
    local result="$2"
    local details="$3"
    
    if [ "$result" = "PASS" ]; then
        echo -e "✅ $check_name: ${GREEN}OK${NC} - $details"
        return 0
    elif [ "$result" = "WARN" ]; then
        echo -e "⚠️ $check_name: ${YELLOW}WARNING${NC} - $details"
        return 1
    else
        echo -e "❌ $check_name: ${RED}FAIL${NC} - $details"
        return 2
    fi
}

TOTAL_CHECKS=0
PASSED_CHECKS=0
WARNING_CHECKS=0
FAILED_CHECKS=0

# Check 1: Project Detection
((TOTAL_CHECKS++))
echo "🔍 Checking project structure..."
if [ -f "docker-compose.yml" ] && grep -q "tectonic" docker-compose.yml; then
    check_result "Project Detection" "PASS" "Tectonic Generator project detected"
    ((PASSED_CHECKS++))
else
    check_result "Project Detection" "FAIL" "Not a Tectonic Generator project"
    ((FAILED_CHECKS++))
fi

# Check 2: Required Files
((TOTAL_CHECKS++))
echo "📁 Checking required files..."
REQUIRED_FILES=("backend/app.py" "backend/tectonic_noise/__init__.py" "backend/utils/__init__.py")
MISSING_FILES=0

for file in "${REQUIRED_FILES[@]}"; do
    if [ ! -f "$file" ]; then
        ((MISSING_FILES++))
    fi
done

if [ $MISSING_FILES -eq 0 ]; then
    check_result "Required Files" "PASS" "All critical files present"
    ((PASSED_CHECKS++))
else
    check_result "Required Files" "FAIL" "$MISSING_FILES critical files missing"
    ((FAILED_CHECKS++))
fi

# Check 3: Docker Status
((TOTAL_CHECKS++))
echo "🐳 Checking Docker status..."
if docker info > /dev/null 2>&1; then
    check_result "Docker Running" "PASS" "Docker is operational"
    ((PASSED_CHECKS++))
else
    check_result "Docker Running" "FAIL" "Docker is not running"
    ((FAILED_CHECKS++))
fi

# Check 4: Container Status
((TOTAL_CHECKS++))
echo "📦 Checking container status..."
if docker-compose ps | grep -q "Up.*tectonic-backend"; then
    check_result "Backend Container" "PASS" "Backend container running"
    ((PASSED_CHECKS++))
elif docker-compose ps | grep -q "tectonic-backend"; then
    check_result "Backend Container" "WARN" "Backend container exists but not running"
    ((WARNING_CHECKS++))
else
    check_result "Backend Container" "FAIL" "Backend container not found"
    ((FAILED_CHECKS++))
fi

# Check 5: API Accessibility
((TOTAL_CHECKS++))
echo "🌐 Checking API accessibility..."
if curl -s http://localhost:5000/api/health > /dev/null 2>&1; then
    HEALTH_RESPONSE=$(curl -s http://localhost:5000/api/health)
    if echo "$HEALTH_RESPONSE" | grep -q '"success":\s*true'; then
        check_result "API Health" "PASS" "API responding correctly"
        ((PASSED_CHECKS++))
    else
        check_result "API Health" "WARN" "API responding but unhealthy"
        ((WARNING_CHECKS++))
    fi
else
    check_result "API Health" "FAIL" "API not accessible"
    ((FAILED_CHECKS++))
fi

# Check 6: Critical Endpoints
((TOTAL_CHECKS++))
echo "🔗 Checking critical endpoints..."
ENDPOINT_FAILURES=0
ENDPOINTS=("api/noise/parameters" "api/noise/presets" "api/noise/perlin")

for endpoint in "${ENDPOINTS[@]}"; do
    HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" "http://localhost:5000/$endpoint" 2>/dev/null || echo "000")
    if [ "$HTTP_CODE" != "200" ] && [ "$HTTP_CODE" != "405" ]; then
        ((ENDPOINT_FAILURES++))
    fi
done

if [ $ENDPOINT_FAILURES -eq 0 ]; then
    check_result "Critical Endpoints" "PASS" "All endpoints accessible"
    ((PASSED_CHECKS++))
elif [ $ENDPOINT_FAILURES -le 1 ]; then
    check_result "Critical Endpoints" "WARN" "$ENDPOINT_FAILURES endpoint issues"
    ((WARNING_CHECKS++))
else
    check_result "Critical Endpoints" "FAIL" "$ENDPOINT_FAILURES endpoint failures"
    ((FAILED_CHECKS++))
fi

# Check 7: Quick Algorithm Test
((TOTAL_CHECKS++))
echo "🧪 Quick algorithm test..."
QUICK_PAYLOAD='{"size":{"width":32,"height":32},"scale":0.05,"octaves":4,"persistence":0.5,"lacunarity":2.0,"seed":12345}'
QUICK_RESPONSE=$(curl -s -X POST -H "Content-Type: application/json" -d "$QUICK_PAYLOAD" "http://localhost:5000/api/noise/perlin" 2>/dev/null || echo "ERROR")

if echo "$QUICK_RESPONSE" | grep -q '"success":\s*true'; then
    check_result "Algorithm Test" "PASS" "Perlin generation working"
    ((PASSED_CHECKS++))
else
    check_result "Algorithm Test" "FAIL" "Algorithm generation failed"
    ((FAILED_CHECKS++))
fi

# Check 8: Test Scripts Available
((TOTAL_CHECKS++))
echo "📝 Checking test scripts..."
TEST_SCRIPTS=("tectonic_diagnostic_master.sh" "tectonic_algorithm_tests.sh" "tectonic_integration_suite.sh")
MISSING_SCRIPTS=0

for script in "${TEST_SCRIPTS[@]}"; do
    if [ ! -f "$script" ]; then
        ((MISSING_SCRIPTS++))
    fi
done

if [ $MISSING_SCRIPTS -eq 0 ]; then
    check_result "Test Scripts" "PASS" "All test scripts available"
    ((PASSED_CHECKS++))
else
    check_result "Test Scripts" "WARN" "$MISSING_SCRIPTS test scripts missing"
    ((WARNING_CHECKS++))
fi

# Summary
echo ""
echo "📊 QUICK VERIFICATION SUMMARY"
echo "============================="
echo "Total Checks: $TOTAL_CHECKS"
echo "Passed: $PASSED_CHECKS"
echo "Warnings: $WARNING_CHECKS"  
echo "Failed: $FAILED_CHECKS"

SUCCESS_RATE=$(( (PASSED_CHECKS + WARNING_CHECKS) * 100 / TOTAL_CHECKS ))
echo "Success Rate: $SUCCESS_RATE%"
echo ""

# Recommendations
if [ $FAILED_CHECKS -eq 0 ]; then
    echo -e "${GREEN}✅ SYSTEM READY FOR FULL TESTING${NC}"
    echo ""
    echo "You can now run the complete test suite:"
    echo "  ./run_all_tectonic_tests.sh"
    echo ""
    echo "Or run individual tests:"
    echo "  ./tectonic_diagnostic_master.sh"
    echo "  ./tectonic_algorithm_tests.sh"
    echo "  ./tectonic_integration_suite.sh"
    exit 0
    
elif [ $FAILED_CHECKS -le 2 ]; then
    echo -e "${YELLOW}⚠️ MINOR ISSUES DETECTED${NC}"
    echo ""
    echo "Fix these issues before running full tests:"
    
    if [ $FAILED_CHECKS -gt 0 ]; then
        echo "1. Address failed checks above"
    fi
    
    if docker-compose ps | grep -q "Exit\|Restarting"; then
        echo "2. Restart containers: docker-compose restart"
    fi
    
    if ! curl -s http://localhost:5000/api/health > /dev/null 2>&1; then
        echo "3. Wait for API to be ready or restart: docker-compose up -d"
    fi
    
    echo ""
    echo "Then re-run this verification: ./quick_tectonic_check.sh"
    exit 1
    
else
    echo -e "${RED}❌ CRITICAL ISSUES DETECTED${NC}"
    echo ""
    echo "System needs attention before testing:"
    
    if ! docker info > /dev/null 2>&1; then
        echo "1. Start Docker service"
    fi
    
    if [ ! -f "docker-compose.yml" ]; then
        echo "2. Ensure you're in the correct project directory"
    fi
    
    if [ $MISSING_FILES -gt 0 ]; then
        echo "3. Check project integrity - missing critical files"
    fi
    
    if ! docker-compose ps | grep -q "Up.*tectonic-backend"; then
        echo "4. Start containers: docker-compose up -d"
    fi
    
    echo ""
    echo "After fixing issues, re-run: ./quick_tectonic_check.sh"
    exit 2
fi