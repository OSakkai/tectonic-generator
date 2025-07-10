#!/bin/bash

# =====================================================
# TECTONIC GENERATOR - COMPLETE TEST SUITE RUNNER
# Executes all diagnostic tests in proper sequence
# =====================================================

set -euo pipefail

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m'

# Configuration
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
RESULTS_DIR="complete_test_results_${TIMESTAMP}"
mkdir -p "$RESULTS_DIR"

echo "🚀 TECTONIC GENERATOR - COMPLETE TEST SUITE"
echo "============================================="
echo "Timestamp: $TIMESTAMP"
echo "Results Directory: $RESULTS_DIR"
echo ""

# =====================================================
# UTILITY FUNCTIONS
# =====================================================
log_section() {
    echo -e "${CYAN}$1${NC}"
    echo "$(echo "$1" | sed 's/./-/g')"
}

log_test() {
    echo -e "${BLUE}🔍 $1${NC}"
}

log_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

log_warning() {
    echo -e "${YELLOW}⚠️ $1${NC}"
}

log_error() {
    echo -e "${RED}❌ $1${NC}"
}

# Function to run a test and capture results
run_test() {
    local test_name="$1"
    local test_script="$2"
    local required="$3"  # "required" or "optional"
    
    log_test "Running $test_name..."
    
    if [ ! -f "$test_script" ]; then
        log_error "$test_script not found!"
        if [ "$required" = "required" ]; then
            echo "FAIL: $test_name - Script missing" >> "$RESULTS_DIR/test_summary.log"
            return 1
        else
            echo "SKIP: $test_name - Script missing" >> "$RESULTS_DIR/test_summary.log"
            return 0
        fi
    fi
    
    chmod +x "$test_script"
    
    local start_time=$(date +%s)
    if timeout 600 "./$test_script" > "$RESULTS_DIR/${test_name}_output.log" 2>&1; then
        local end_time=$(date +%s)
        local duration=$((end_time - start_time))
        log_success "$test_name completed successfully (${duration}s)"
        echo "PASS: $test_name - Duration: ${duration}s" >> "$RESULTS_DIR/test_summary.log"
        return 0
    else
        local exit_code=$?
        local end_time=$(date +%s)
        local duration=$((end_time - start_time))
        
        if [ $exit_code -eq 124 ]; then
            log_error "$test_name timed out after 10 minutes"
            echo "TIMEOUT: $test_name - Duration: ${duration}s" >> "$RESULTS_DIR/test_summary.log"
        else
            log_error "$test_name failed (exit code: $exit_code, duration: ${duration}s)"
            echo "FAIL: $test_name - Exit code: $exit_code, Duration: ${duration}s" >> "$RESULTS_DIR/test_summary.log"
        fi
        
        # Show last few lines of output for debugging
        echo "Last 10 lines of output:"
        tail -10 "$RESULTS_DIR/${test_name}_output.log" || echo "No output available"
        
        if [ "$required" = "required" ]; then
            return 1
        else
            return 0
        fi
    fi
}

# =====================================================
# PRE-TEST SYSTEM CHECK
# =====================================================
log_section "🔍 PRE-TEST SYSTEM VERIFICATION"

# Check if we're in the right directory
if [ ! -f "docker-compose.yml" ]; then
    log_error "docker-compose.yml not found! Are you in the Tectonic Generator project directory?"
    exit 1
fi

if ! grep -q "tectonic" docker-compose.yml; then
    log_error "This doesn't appear to be a Tectonic Generator project!"
    exit 1
fi

log_success "Tectonic Generator project detected"

# Check if Docker is running
if ! docker info > /dev/null 2>&1; then
    log_error "Docker is not running! Please start Docker and try again."
    exit 1
fi

log_success "Docker is running"

# Check if containers are up
log_test "Checking container status..."
docker-compose ps > "$RESULTS_DIR/initial_container_status.log" 2>&1

if docker-compose ps | grep -q "Up"; then
    log_success "Some containers are already running"
else
    log_warning "No containers running, starting Tectonic Generator..."
    docker-compose up -d > "$RESULTS_DIR/startup.log" 2>&1
    sleep 15
    
    if docker-compose ps | grep -q "Up"; then
        log_success "Containers started successfully"
    else
        log_error "Failed to start containers"
        cat "$RESULTS_DIR/startup.log"
        exit 1
    fi
fi

# Quick API check
log_test "Checking API accessibility..."
HEALTH_CHECK_ATTEMPTS=0
while [ $HEALTH_CHECK_ATTEMPTS -lt 30 ]; do
    if curl -s http://localhost:5000/api/health > /dev/null 2>&1; then
        log_success "API is accessible"
        break
    fi
    sleep 2
    ((HEALTH_CHECK_ATTEMPTS++))
done

if [ $HEALTH_CHECK_ATTEMPTS -eq 30 ]; then
    log_error "API not accessible after 60 seconds"
    exit 1
fi

# =====================================================
# OFFICIAL TECTONIC GENERATOR TEST (BASELINE)
# =====================================================
log_section "🏃 OFFICIAL TECTONIC GENERATOR TESTS"

if [ -f "./quick_test.sh" ]; then
    log_test "Running official quick_test.sh..."
    chmod +x "./quick_test.sh"
    
    if ./quick_test.sh > "$RESULTS_DIR/official_quick_test.log" 2>&1; then
        OFFICIAL_PASSED=$(grep -c "✅" "$RESULTS_DIR/official_quick_test.log" || echo "0")
        OFFICIAL_FAILED=$(grep -c "❌" "$RESULTS_DIR/official_quick_test.log" || echo "0")
        log_success "Official tests: $OFFICIAL_PASSED passed, $OFFICIAL_FAILED failed"
        echo "OFFICIAL: quick_test.sh - Passed: $OFFICIAL_PASSED, Failed: $OFFICIAL_FAILED" >> "$RESULTS_DIR/test_summary.log"
    else
        log_error "Official quick_test.sh failed"
        echo "FAIL: quick_test.sh - Execution failed" >> "$RESULTS_DIR/test_summary.log"
    fi
else
    log_warning "Official quick_test.sh not found"
    echo "SKIP: quick_test.sh - Not found" >> "$RESULTS_DIR/test_summary.log"
fi

# =====================================================
# COMPREHENSIVE TEST SUITE EXECUTION
# =====================================================
log_section "🧪 COMPREHENSIVE DIAGNOSTIC TEST SUITE"

# Initialize test summary
echo "# Tectonic Generator Test Suite Results - $TIMESTAMP" > "$RESULTS_DIR/test_summary.log"
echo "# Format: STATUS: TestName - Details" >> "$RESULTS_DIR/test_summary.log"
echo "" >> "$RESULTS_DIR/test_summary.log"

# Test execution tracking
TOTAL_TESTS=0
PASSED_TESTS=0
FAILED_TESTS=0
SKIPPED_TESTS=0
CRITICAL_FAILURES=0

# Test 1: Master Diagnostic
log_test "TEST 1: Master System Diagnostic"
((TOTAL_TESTS++))
if run_test "master_diagnostic" "tectonic_diagnostic_master.sh" "required"; then
    ((PASSED_TESTS++))
else
    ((FAILED_TESTS++))
    ((CRITICAL_FAILURES++))
fi

# Test 2: Algorithm-Specific Testing
echo ""
log_test "TEST 2: Algorithm-Specific Testing"
((TOTAL_TESTS++))
if run_test "algorithm_tests" "tectonic_algorithm_tests.sh" "required"; then
    ((PASSED_TESTS++))
else
    ((FAILED_TESTS++))
    ((CRITICAL_FAILURES++))
fi

# Test 3: Integration Testing
echo ""
log_test "TEST 3: Integration Testing"
((TOTAL_TESTS++))
if run_test "integration_tests" "tectonic_integration_suite.sh" "required"; then
    ((PASSED_TESTS++))
else
    ((FAILED_TESTS++))
fi

# Test 4: Docker Rebuild Test (Optional - only if issues detected)
echo ""
log_test "TEST 4: Docker Environment Validation"
((TOTAL_TESTS++))
if run_test "docker_validation" "docker_rebuild_test.sh" "optional"; then
    ((PASSED_TESTS++))
else
    ((FAILED_TESTS++))
fi

# Test 5: Performance Validation (if available)
echo ""
if [ -f "test_runner.sh" ]; then
    log_test "TEST 5: Extended Performance Testing"
    ((TOTAL_TESTS++))
    if run_test "performance_tests" "test_runner.sh" "optional"; then
        ((PASSED_TESTS++))
    else
        ((FAILED_TESTS++))
    fi
else
    log_warning "Extended performance tests not available"
    echo "SKIP: performance_tests - test_runner.sh not found" >> "$RESULTS_DIR/test_summary.log"
    ((SKIPPED_TESTS++))
fi

# =====================================================
# RESULTS ANALYSIS AND REPORTING
# =====================================================
log_section "📊 TEST RESULTS ANALYSIS"

# Calculate success rates
SUCCESS_RATE=$(( (PASSED_TESTS * 100) / TOTAL_TESTS ))
CRITICAL_SUCCESS_RATE=$(( ((TOTAL_TESTS - CRITICAL_FAILURES) * 100) / TOTAL_TESTS ))

# Generate comprehensive report
cat > "$RESULTS_DIR/COMPLETE_TEST_REPORT.md" << EOF
# TECTONIC GENERATOR - COMPLETE TEST SUITE REPORT

**Generated:** $TIMESTAMP
**Test Suite Version:** v2.1
**Total Test Categories:** $TOTAL_TESTS
**Overall Success Rate:** $SUCCESS_RATE%

## Executive Summary
- ✅ **Passed:** $PASSED_TESTS test categories
- ❌ **Failed:** $FAILED_TESTS test categories
- ⏭️ **Skipped:** $SKIPPED_TESTS test categories
- 🔴 **Critical Failures:** $CRITICAL_FAILURES test categories

## System Health Assessment
$(if [ $CRITICAL_FAILURES -eq 0 ]; then
    echo "### ✅ SYSTEM FULLY OPERATIONAL"
    echo "All critical tests passed. Tectonic Generator is production-ready."
elif [ $CRITICAL_FAILURES -eq 1 ]; then
    echo "### ⚠️ MINOR CRITICAL ISSUE"
    echo "One critical test failed. System may be functional but needs attention."
else
    echo "### ❌ CRITICAL SYSTEM ISSUES"
    echo "$CRITICAL_FAILURES critical tests failed. System requires immediate attention."
fi)

## Test Categories Executed

### 1. Master System Diagnostic
- **Purpose:** Comprehensive system validation
- **Status:** $(grep "master_diagnostic" "$RESULTS_DIR/test_summary.log" | cut -d':' -f1)
- **Details:** Complete infrastructure and module testing

### 2. Algorithm-Specific Testing  
- **Purpose:** Noise generation algorithm validation
- **Status:** $(grep "algorithm_tests" "$RESULTS_DIR/test_summary.log" | cut -d':' -f1)
- **Details:** Perlin, Simplex, and Worley algorithm testing

### 3. Integration Testing
- **Purpose:** End-to-end system integration
- **Status:** $(grep "integration_tests" "$RESULTS_DIR/test_summary.log" | cut -d':' -f1)
- **Details:** Complete workflow and cross-component testing

### 4. Docker Environment Validation
- **Purpose:** Container and dependency validation
- **Status:** $(grep "docker_validation" "$RESULTS_DIR/test_summary.log" | cut -d':' -f1 || echo "SKIPPED")
- **Details:** Environment consistency and rebuild testing

### 5. Extended Performance Testing
- **Purpose:** Advanced performance and stress testing
- **Status:** $(grep "performance_tests" "$RESULTS_DIR/test_summary.log" | cut -d':' -f1 || echo "SKIPPED")
- **Details:** Comprehensive performance benchmarking

## Official Test Results
$(if [ -f "$RESULTS_DIR/official_quick_test.log" ]; then
    echo "- **Official Quick Tests:** $OFFICIAL_PASSED passed, $OFFICIAL_FAILED failed"
    echo "- **Official Status:** $([ $OFFICIAL_FAILED -eq 0 ] && echo "✅ All official tests passed" || echo "⚠️ Some official tests failed")"
else
    echo "- **Official Tests:** Not available"
fi)

## Critical Issues Detected
$(if [ $CRITICAL_FAILURES -eq 0 ]; then
    echo "No critical issues detected. System is stable and operational."
else
    echo "$(grep "FAIL.*required" "$RESULTS_DIR/test_summary.log" || echo "Critical test failures detected - review individual test logs")"
fi)

## Performance Summary
$(if [ -f "$RESULTS_DIR/master_diagnostic_output.log" ]; then
    echo "Based on diagnostic results:"
    grep -i "performance\|time\|ms" "$RESULTS_DIR/master_diagnostic_output.log" | head -5 || echo "Performance data available in diagnostic logs"
else
    echo "Performance data available in individual test logs"
fi)

## Recommendations

$(if [ $CRITICAL_FAILURES -eq 0 ] && [ $SUCCESS_RATE -ge 80 ]; then
    echo "### ✅ PRODUCTION READY"
    echo "1. System is ready for production deployment"
    echo "2. All critical components functioning correctly"
    echo "3. Consider implementing monitoring and alerting"
    echo "4. Begin advanced feature development"
elif [ $CRITICAL_FAILURES -le 1 ] && [ $SUCCESS_RATE -ge 60 ]; then
    echo "### ⚠️ MINOR ISSUES TO ADDRESS"
    echo "1. Review failed tests and address specific issues"
    echo "2. Re-run failed test categories after fixes"
    echo "3. Validate system stability before production"
    echo "4. Consider incremental deployment"
else
    echo "### ❌ REQUIRES IMMEDIATE ATTENTION"
    echo "1. Address all critical test failures immediately"
    echo "2. Review system architecture and configuration"
    echo "3. Fix fundamental issues before proceeding"
    echo "4. Re-run complete test suite after major fixes"
fi)

## Generated Files
- test_summary.log: Complete test execution summary
- *_output.log: Individual test detailed outputs
- official_quick_test.log: Official Tectonic Generator test results
- initial_container_status.log: Pre-test system state
- startup.log: Container startup logs (if applicable)

## Next Steps
1. Review individual test logs for detailed failure analysis
2. Address any failed tests based on priority (critical first)
3. Re-run specific test categories after fixes
4. Validate system stability with full test suite
5. Proceed with deployment or development based on results

---
*Complete test suite executed by Tectonic Generator Test Runner v2.1*
EOF

# Display final results
echo ""
log_section "🎯 FINAL TEST RESULTS"

echo "📊 TEST EXECUTION SUMMARY:"
echo "   Total Test Categories: $TOTAL_TESTS"
echo "   Passed: $PASSED_TESTS"
echo "   Failed: $FAILED_TESTS"
echo "   Skipped: $SKIPPED_TESTS"
echo "   Critical Failures: $CRITICAL_FAILURES"
echo "   Success Rate: $SUCCESS_RATE%"
echo ""

echo "📁 Results saved to: $RESULTS_DIR"
echo "📋 Complete report: $RESULTS_DIR/COMPLETE_TEST_REPORT.md"
echo ""

# Display official test results if available
if [ -f "$RESULTS_DIR/official_quick_test.log" ]; then
    echo "🏃 Official Test Results: $OFFICIAL_PASSED passed, $OFFICIAL_FAILED failed"
fi

# Final status determination
if [ $CRITICAL_FAILURES -eq 0 ] && [ $SUCCESS_RATE -ge 80 ]; then
    echo ""
    log_success "🎉 ALL TESTS COMPLETED SUCCESSFULLY!"
    echo -e "${GREEN}✅ TECTONIC GENERATOR IS FULLY OPERATIONAL${NC}"
    echo ""
    echo "System Status: PRODUCTION READY ✅"
    echo ""
    echo "You can now:"
    echo "  • Deploy to production environment"
    echo "  • Begin advanced feature development"
    echo "  • Set up monitoring and alerting"
    echo "  • Conduct user acceptance testing"
    
    exit 0
    
elif [ $CRITICAL_FAILURES -le 1 ] && [ $SUCCESS_RATE -ge 60 ]; then
    echo ""
    log_warning "⚠️ TESTS COMPLETED WITH MINOR ISSUES"
    echo -e "${YELLOW}System is mostly functional but needs attention${NC}"
    echo ""
    echo "System Status: NEEDS MINOR FIXES ⚠️"
    echo ""
    echo "Next steps:"
    echo "  • Review failed tests: grep 'FAIL' $RESULTS_DIR/test_summary.log"
    echo "  • Address specific issues"
    echo "  • Re-run failed test categories"
    echo "  • Validate fixes before deployment"
    
    exit 1
    
else
    echo ""
    log_error "❌ CRITICAL TEST FAILURES DETECTED"
    echo -e "${RED}System has significant issues requiring immediate attention${NC}"
    echo ""
    echo "System Status: NEEDS MAJOR FIXES ❌"
    echo ""
    echo "Immediate actions required:"
    echo "  • Review critical failures: grep 'FAIL.*required' $RESULTS_DIR/test_summary.log"
    echo "  • Check container logs: docker-compose logs"
    echo "  • Fix fundamental issues"
    echo "  • Re-run complete test suite"
    echo ""
    echo "Detailed logs available in: $RESULTS_DIR/"
    
    exit 2
fi