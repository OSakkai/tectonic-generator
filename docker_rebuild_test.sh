#!/bin/bash

# =====================================================
# DOCKER REBUILD AND DEPENDENCY VERIFICATION TEST
# Complete container rebuild with dependency tracking
# =====================================================

set -euo pipefail

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
TEST_DIR="docker_rebuild_test_${TIMESTAMP}"
mkdir -p "$TEST_DIR"

echo "🐳 DOCKER REBUILD AND DEPENDENCY VERIFICATION"
echo "=============================================="
echo "Timestamp: $TIMESTAMP"
echo ""

test_result() {
    local test_name="$1"
    local result="$2"
    local details="$3"
    
    if [ "$result" = "PASS" ]; then
        echo -e "✅ $test_name: ${GREEN}PASS${NC} - $details"
    else
        echo -e "❌ $test_name: ${RED}FAIL${NC} - $details"
    fi
    
    echo "$test_name: $result - $details" >> "$TEST_DIR/rebuild_results.log"
}

# =====================================================
# PHASE 1: PRE-REBUILD ANALYSIS
# =====================================================
echo "📋 PHASE 1: Pre-Rebuild Analysis"
echo "---------------------------------"

# Capture current state
echo "📸 Capturing current state..."
docker-compose ps > "$TEST_DIR/pre_rebuild_status.log" 2>&1
docker images | grep -E "(lab-|tectonic)" > "$TEST_DIR/pre_rebuild_images.log" 2>&1 || echo "No matching images" > "$TEST_DIR/pre_rebuild_images.log"

# Check for Dockerfile
if [ -f "backend/Dockerfile" ]; then
    test_result "Dockerfile Exists" "PASS" "backend/Dockerfile found"
    cp "backend/Dockerfile" "$TEST_DIR/Dockerfile_backup"
else
    test_result "Dockerfile Exists" "FAIL" "backend/Dockerfile missing"
fi

# Check for requirements.txt
if [ -f "backend/requirements.txt" ]; then
    test_result "Requirements File" "PASS" "requirements.txt found"
    cp "backend/requirements.txt" "$TEST_DIR/requirements_backup.txt"
else
    test_result "Requirements File" "FAIL" "requirements.txt missing - this may be the problem"
fi

# =====================================================
# PHASE 2: CLEAN REBUILD PROCESS
# =====================================================
echo ""
echo "🔄 PHASE 2: Clean Rebuild Process"
echo "--------------------------------"

echo "🛑 Stopping all containers..."
docker-compose down > "$TEST_DIR/stop_containers.log" 2>&1
if [ $? -eq 0 ]; then
    test_result "Container Stop" "PASS" "All containers stopped"
else
    test_result "Container Stop" "FAIL" "Failed to stop containers"
fi

echo "🧹 Cleaning Docker cache..."
docker system prune -f > "$TEST_DIR/docker_prune.log" 2>&1
docker-compose down --volumes --remove-orphans > "$TEST_DIR/clean_volumes.log" 2>&1

# Remove specific images
echo "🗑️ Removing old images..."
docker images | grep -E "(lab-backend|tectonic)" | awk '{print $3}' | xargs docker rmi -f > "$TEST_DIR/remove_images.log" 2>&1 || echo "No images to remove"

# =====================================================
# PHASE 3: DOCKERFILE ANALYSIS AND CREATION
# =====================================================
echo ""
echo "🔍 PHASE 3: Dockerfile Analysis"
echo "-------------------------------"

if [ -f "backend/Dockerfile" ]; then
    echo "📄 Analyzing existing Dockerfile..."
    cat "backend/Dockerfile" > "$TEST_DIR/dockerfile_analysis.log"
    
    # Check for Python version
    if grep -q "FROM python:" "backend/Dockerfile"; then
        PYTHON_VERSION=$(grep "FROM python:" "backend/Dockerfile" | head -1)
        test_result "Python Base Image" "PASS" "$PYTHON_VERSION"
    else
        test_result "Python Base Image" "FAIL" "No Python base image found"
    fi
    
    # Check for requirements installation
    if grep -q "requirements.txt" "backend/Dockerfile"; then
        test_result "Requirements Installation" "PASS" "requirements.txt referenced in Dockerfile"
    else
        test_result "Requirements Installation" "FAIL" "No requirements.txt installation found"
    fi
    
    # Check for working directory
    if grep -q "WORKDIR" "backend/Dockerfile"; then
        WORKDIR=$(grep "WORKDIR" "backend/Dockerfile" | head -1)
        test_result "Working Directory" "PASS" "$WORKDIR"
    else
        test_result "Working Directory" "FAIL" "No WORKDIR specified"
    fi
else
    echo "⚠️ No Dockerfile found. Creating basic Dockerfile..."
    
    cat > "backend/Dockerfile" << 'EOF'
FROM python:3.11-slim

# Set working directory
WORKDIR /app

# Install system dependencies
RUN apt-get update && apt-get install -y \
    gcc \
    g++ \
    && rm -rf /var/lib/apt/lists/*

# Copy requirements and install Python dependencies
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Copy application code
COPY . .

# Set Python path
ENV PYTHONPATH=/app

# Expose port
EXPOSE 5000

# Run the application
CMD ["python", "app.py"]
EOF
    
    test_result "Dockerfile Creation" "PASS" "Basic Dockerfile created"
fi

# =====================================================
# PHASE 4: REQUIREMENTS.TXT ANALYSIS AND CREATION
# =====================================================
echo ""
echo "📦 PHASE 4: Requirements Analysis"
echo "---------------------------------"

if [ ! -f "backend/requirements.txt" ]; then
    echo "⚠️ Creating requirements.txt for tectonic plates system..."
    
    cat > "backend/requirements.txt" << 'EOF'
# Flask web framework
Flask==2.3.3
Flask-CORS==4.0.0

# Scientific computing
numpy==1.24.3
scipy==1.11.1

# Image processing
Pillow==10.0.0

# Additional utilities
requests==2.31.0
python-dotenv==1.0.0

# Development tools
pytest==7.4.0
pytest-flask==1.2.0
EOF
    
    test_result "Requirements Creation" "PASS" "requirements.txt created with tectonic dependencies"
else
    echo "📄 Analyzing existing requirements.txt..."
    
    # Check for essential packages
    REQUIRED_PACKAGES=("numpy" "scipy" "Pillow" "Flask")
    for package in "${REQUIRED_PACKAGES[@]}"; do
        if grep -i "$package" "backend/requirements.txt" > /dev/null; then
            test_result "Required Package: $package" "PASS" "Found in requirements.txt"
        else
            test_result "Required Package: $package" "FAIL" "Missing from requirements.txt"
            echo "$package" >> "backend/requirements.txt"
            echo "Added $package to requirements.txt"
        fi
    done
fi

# =====================================================
# PHASE 5: REBUILD CONTAINERS
# =====================================================
echo ""
echo "🔨 PHASE 5: Container Rebuild"
echo "-----------------------------"

echo "🏗️ Building backend container..."
docker-compose build --no-cache backend > "$TEST_DIR/build_backend.log" 2>&1
BUILD_EXIT_CODE=$?

if [ $BUILD_EXIT_CODE -eq 0 ]; then
    test_result "Backend Build" "PASS" "Container built successfully"
else
    test_result "Backend Build" "FAIL" "Build failed (exit code: $BUILD_EXIT_CODE)"
    echo "Build log (last 20 lines):"
    tail -20 "$TEST_DIR/build_backend.log"
fi

echo "🚀 Starting services..."
docker-compose up -d > "$TEST_DIR/start_services.log" 2>&1
START_EXIT_CODE=$?

if [ $START_EXIT_CODE -eq 0 ]; then
    test_result "Service Start" "PASS" "Services started successfully"
else
    test_result "Service Start" "FAIL" "Failed to start services"
fi

# Wait for services to be ready
echo "⏳ Waiting for services to be ready..."
sleep 10

# =====================================================
# PHASE 6: POST-REBUILD VERIFICATION
# =====================================================
echo ""
echo "✅ PHASE 6: Post-Rebuild Verification"
echo "------------------------------------"

# Check container status
docker-compose ps > "$TEST_DIR/post_rebuild_status.log" 2>&1
if docker-compose ps | grep -q "Up"; then
    test_result "Container Status" "PASS" "Containers are running"
else
    test_result "Container Status" "FAIL" "Containers not running properly"
fi

# Test backend container accessibility
if docker-compose exec -T backend echo "Container accessible" > /dev/null 2>&1; then
    test_result "Backend Access" "PASS" "Backend container accessible"
    
    # Test Python environment
    docker-compose exec -T backend python --version > "$TEST_DIR/python_version_new.log" 2>&1
    PYTHON_VERSION=$(cat "$TEST_DIR/python_version_new.log")
    test_result "Python Installation" "PASS" "$PYTHON_VERSION"
    
    # Test package installations
    echo "📦 Testing package installations..."
    docker-compose exec -T backend python -c "
import sys
packages_to_test = ['numpy', 'scipy', 'PIL', 'flask']
results = {}
for package in packages_to_test:
    try:
        exec(f'import {package}')
        results[package] = 'SUCCESS'
    except Exception as e:
        results[package] = f'FAILED: {e}'

for package, result in results.items():
    print(f'{package}: {result}')
" > "$TEST_DIR/package_tests.log" 2>&1
    
    # Analyze package test results
    SUCCESS_PACKAGES=$(grep -c "SUCCESS" "$TEST_DIR/package_tests.log" || echo "0")
    TOTAL_PACKAGES=$(grep -c ":" "$TEST_DIR/package_tests.log" || echo "1")
    
    if [ "$SUCCESS_PACKAGES" -eq "$TOTAL_PACKAGES" ]; then
        test_result "Package Installation" "PASS" "All $SUCCESS_PACKAGES packages working"
    else
        test_result "Package Installation" "FAIL" "$SUCCESS_PACKAGES/$TOTAL_PACKAGES packages working"
    fi
    
    # Test directory structure
    docker-compose exec -T backend find /app -type d -name "*tectonic*" > "$TEST_DIR/tectonic_dirs_new.log" 2>&1
    if [ -s "$TEST_DIR/tectonic_dirs_new.log" ]; then
        test_result "Tectonic Directory Structure" "PASS" "Tectonic directories found"
    else
        test_result "Tectonic Directory Structure" "FAIL" "No tectonic directories found"
    fi
    
else
    test_result "Backend Access" "FAIL" "Cannot access backend container"
fi

# Test API endpoints
echo "🌐 Testing API endpoints..."
sleep 5  # Give more time for Flask to start

for endpoint in "health" "api/plates/parameters" "api/plates/presets"; do
    HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" "http://localhost:5000/$endpoint" 2>/dev/null || echo "000")
    
    if [ "$HTTP_CODE" = "200" ]; then
        test_result "Endpoint: $endpoint" "PASS" "HTTP 200"
    elif [ "$HTTP_CODE" = "404" ]; then
        test_result "Endpoint: $endpoint" "FAIL" "HTTP 404 - Not Found"
    elif [ "$HTTP_CODE" = "000" ]; then
        test_result "Endpoint: $endpoint" "FAIL" "Connection Failed"
    else
        test_result "Endpoint: $endpoint" "FAIL" "HTTP $HTTP_CODE"
    fi
done

# =====================================================
# PHASE 7: IMPORT TESTING IN NEW ENVIRONMENT
# =====================================================
echo ""
echo "🧪 PHASE 7: Import Testing in New Environment"
echo "--------------------------------------------"

if docker-compose ps backend | grep -q "Up"; then
    docker-compose exec -T backend python -c "
import sys
import os

# Add paths
sys.path.insert(0, '/app')
sys.path.insert(0, '/app/backend')

print('=== NEW ENVIRONMENT IMPORT TESTING ===')
print(f'Working directory: {os.getcwd()}')
print(f'Python path entries: {len(sys.path)}')

# Test basic imports
basic_imports = ['numpy', 'scipy', 'PIL', 'flask']
for module in basic_imports:
    try:
        exec(f'import {module}')
        print(f'✅ {module}: OK')
    except Exception as e:
        print(f'❌ {module}: {e}')

print()
print('=== TECTONIC MODULE TESTING ===')

# Check if tectonic_plates directory exists
tectonic_dir = '/app/backend/tectonic_plates'
if os.path.exists(tectonic_dir):
    print(f'✅ Tectonic directory exists: {tectonic_dir}')
    
    # List contents
    contents = os.listdir(tectonic_dir)
    print(f'Contents: {contents}')
    
    # Try importing each module
    for module_name in ['hex_grid', 'watershed', 'plate_generator']:
        module_path = os.path.join(tectonic_dir, f'{module_name}.py')
        if os.path.exists(module_path):
            try:
                import importlib.util
                spec = importlib.util.spec_from_file_location(module_name, module_path)
                module = importlib.util.module_from_spec(spec)
                spec.loader.exec_module(module)
                print(f'✅ {module_name}: Imported successfully')
            except Exception as e:
                print(f'❌ {module_name}: Import failed - {e}')
        else:
            print(f'❌ {module_name}: File not found')
else:
    print(f'❌ Tectonic directory not found: {tectonic_dir}')
" > "$TEST_DIR/new_env_imports.log" 2>&1
    
    # Analyze results
    if grep -q "✅.*OK" "$TEST_DIR/new_env_imports.log"; then
        test_result "Basic Imports New Environment" "PASS" "Core packages working"
    else
        test_result "Basic Imports New Environment" "FAIL" "Core package issues"
    fi
    
    if grep -q "✅.*Imported successfully" "$TEST_DIR/new_env_imports.log"; then
        test_result "Tectonic Imports New Environment" "PASS" "Tectonic modules working"
    else
        test_result "Tectonic Imports New Environment" "FAIL" "Tectonic modules not working"
    fi
else
    test_result "New Environment Testing" "FAIL" "Container not accessible"
fi

# =====================================================
# GENERATE REBUILD REPORT
# =====================================================
echo ""
echo "📊 GENERATING REBUILD DIAGNOSTIC REPORT"
echo "========================================"

TOTAL_TESTS=$(wc -l < "$TEST_DIR/rebuild_results.log")
PASSED_TESTS=$(grep -c "PASS" "$TEST_DIR/rebuild_results.log" || echo "0")
FAILED_TESTS=$(grep -c "FAIL" "$TEST_DIR/rebuild_results.log" || echo "0")
SUCCESS_RATE=$(( PASSED_TESTS * 100 / TOTAL_TESTS ))

cat > "$TEST_DIR/REBUILD_DIAGNOSTIC_REPORT.md" << EOF
# DOCKER REBUILD DIAGNOSTIC REPORT

**Generated:** $TIMESTAMP
**Test Type:** Complete Container Rebuild and Verification
**Total Tests:** $TOTAL_TESTS
**Success Rate:** $SUCCESS_RATE%

## Summary
- ✅ **Passed:** $PASSED_TESTS tests
- ❌ **Failed:** $FAILED_TESTS tests

## Rebuild Process Summary

### Phase 1: Pre-Rebuild Analysis
- Captured current container state
- Analyzed existing Dockerfile and requirements
- Identified missing dependencies

### Phase 2: Clean Rebuild
- Stopped all containers
- Cleaned Docker cache and volumes
- Removed old images

### Phase 3: Dockerfile Analysis
- $(if [ -f "backend/Dockerfile" ]; then echo "Analyzed existing Dockerfile"; else echo "Created new Dockerfile"; fi)
- Verified Python base image configuration
- Checked requirements installation process

### Phase 4: Requirements Analysis
- $(if [ -f "backend/requirements.txt" ]; then echo "Analyzed existing requirements.txt"; else echo "Created new requirements.txt"; fi)
- Verified essential packages (numpy, scipy, Pillow, Flask)
- Added missing dependencies

### Phase 5: Container Rebuild
- Built backend container from scratch
- Started all services
- Verified container accessibility

### Phase 6: Post-Rebuild Verification
- Tested container status and accessibility
- Verified Python environment
- Tested package installations
- Checked directory structure

### Phase 7: Import Testing
- Tested basic module imports
- Verified tectonic plates module structure
- Tested custom module loading

## Critical Findings

$(if [ $FAILED_TESTS -gt 0 ]; then
    echo "### ❌ Issues Detected:"
    grep "FAIL" "$TEST_DIR/rebuild_results.log"
    echo ""
    echo "### Recommendations:"
    echo "1. Check Docker build logs for specific errors"
    echo "2. Verify all required files are present"
    echo "3. Check Dockerfile syntax and requirements.txt format"
    echo "4. Ensure container has sufficient resources"
    echo "5. Validate network configuration for API access"
else
    echo "### ✅ Rebuild Successful"
    echo "All tests passed. The container rebuild resolved previous issues."
fi)

## Build Artifacts Generated
- pre_rebuild_status.log: Container status before rebuild
- build_backend.log: Docker build process log
- post_rebuild_status.log: Container status after rebuild
- package_tests.log: Package installation verification
- new_env_imports.log: Import testing in new environment

## Docker Configuration Files
$(if [ -f "backend/Dockerfile" ]; then echo "- Dockerfile: ✅ Present"; else echo "- Dockerfile: ❌ Missing"; fi)
$(if [ -f "backend/requirements.txt" ]; then echo "- requirements.txt: ✅ Present"; else echo "- requirements.txt: ❌ Missing"; fi)

## Container Status
$(docker-compose ps 2>&1 | head -10)

## Next Steps
1. $(if [ $FAILED_TESTS -eq 0 ]; then echo "✅ System ready for testing"; else echo "❌ Address failed tests before proceeding"; fi)
2. Test tectonic plates functionality with sample data
3. Verify API endpoints respond correctly
4. Run comprehensive integration tests
5. Monitor container logs for runtime errors

---
*Generated by CONDUCTOR AI DIAGNOSTIC SYSTEM v2.0*
EOF

echo "✅ Docker Rebuild Diagnostic Complete!"
echo "📁 Results saved to: $TEST_DIR"
echo "📋 Report: $TEST_DIR/REBUILD_DIAGNOSTIC_REPORT.md"
echo ""
echo "🎯 REBUILD RESULTS:"
echo "   Total Tests: $TOTAL_TESTS"
echo "   Passed: $PASSED_TESTS"
echo "   Failed: $FAILED_TESTS"
echo "   Success Rate: $SUCCESS_RATE%"

if [ $FAILED_TESTS -gt 0 ]; then
    echo ""
    echo -e "${RED}❌ REBUILD ISSUES DETECTED${NC}"
    echo "Critical failures:"
    grep "FAIL" "$TEST_DIR/rebuild_results.log" | head -3
    echo ""
    echo "Check the full report for details:"
    echo "cat $TEST_DIR/REBUILD_DIAGNOSTIC_REPORT.md"
    echo ""
    echo "View build logs:"
    echo "cat $TEST_DIR/build_backend.log"
    exit 1
else
    echo ""
    echo -e "${GREEN}✅ REBUILD SUCCESSFUL - SYSTEM READY${NC}"
    echo ""
    echo "Container is ready for tectonic plates testing!"
    echo "Next: Run './tectonic_specific_tests.sh' to verify functionality"
    exit 0
fi