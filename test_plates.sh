#!/bin/bash

# Tectonic Plates System Test Suite
# Complete validation of plate generation endpoints

set -e

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

# Configuration
BACKEND_URL="http://localhost:5000"
TEST_OUTPUT_DIR="test_results/plates"
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")

echo -e "${BLUE}🌍 Tectonic Plates System Test Suite${NC}"
echo "========================================"
echo "Backend URL: $BACKEND_URL"
echo "Timestamp: $TIMESTAMP"
echo ""

# Create output directory
mkdir -p "$TEST_OUTPUT_DIR"

# Function to check JSON success
check_json_success() {
    local response="$1"
    if echo "$response" | grep -q '"success": *true'; then
        return 0
    else
        return 1
    fi
}

# Function to save test result
save_test_result() {
    local test_name="$1"
    local response="$2"
    local filename="$TEST_OUTPUT_DIR/${test_name}_${TIMESTAMP}.json"
    echo "$response" | jq '.' > "$filename" 2>/dev/null || echo "$response" > "$filename"
    echo -e "${CYAN}💾 Saved to: $filename${NC}"
}

# Test 1: Check plate endpoints availability
test_plate_endpoints() {
    echo -e "\n${BLUE}📡 Test 1: Plate Endpoints Availability${NC}"
    echo "----------------------------------------"
    
    # Test parameters endpoint
    echo -n "Plate parameters endpoint: "
    params_response=$(curl -s --max-time 10 "$BACKEND_URL/api/plates/parameters" 2>/dev/null || echo "")
    if [ -n "$params_response" ] && check_json_success "$params_response"; then
        echo -e "${GREEN}✅ PASS${NC}"
        save_test_result "plate_parameters" "$params_response"
    else
        echo -e "${RED}❌ FAIL${NC}"
        echo -e "${YELLOW}Response: $params_response${NC}"
        return 1
    fi
    
    # Test presets endpoint
    echo -n "Plate presets endpoint: "
    presets_response=$(curl -s --max-time 10 "$BACKEND_URL/api/plates/presets" 2>/dev/null || echo "")
    if [ -n "$presets_response" ] && check_json_success "$presets_response"; then
        echo -e "${GREEN}✅ PASS${NC}"
        save_test_result "plate_presets" "$presets_response"
    else
        echo -e "${RED}❌ FAIL${NC}"
        return 1
    fi
}

# Test 2: Generate noise for plate testing
generate_test_noise() {
    echo -e "\n${BLUE}🌊 Test 2: Generate Noise for Plate Testing${NC}"
    echo "--------------------------------------------"
    
    # Generate Worley noise (best for plates)
    echo -n "Generating Worley noise (128x128): "
    worley_payload='{
        "width": 128,
        "height": 128,
        "frequency": 0.08,
        "distance_function": "euclidean",
        "cell_type": "F1",
        "seed": 12345
    }'
    
    worley_response=$(curl -s --max-time 30 \
        -H "Content-Type: application/json" \
        -d "$worley_payload" \
        "$BACKEND_URL/api/noise/worley" 2>/dev/null || echo "")
    
    if [ -n "$worley_response" ] && check_json_success "$worley_response"; then
        echo -e "${GREEN}✅ PASS${NC}"
        # Extract image data for plate generation
        NOISE_DATA=$(echo "$worley_response" | jq -r '.data.image_data' 2>/dev/null || echo "")
        save_test_result "worley_for_plates" "$worley_response"
        return 0
    else
        echo -e "${RED}❌ FAIL${NC}"
        return 1
    fi
}

# Test 3: Basic plate generation
test_basic_plate_generation() {
    echo -e "\n${BLUE}🗺️ Test 3: Basic Plate Generation${NC}"
    echo "-----------------------------------"
    
    if [ -z "$NOISE_DATA" ]; then
        echo -e "${RED}❌ No noise data available${NC}"
        return 1
    fi
    
    echo -n "Generating plates (50x50 grid): "
    plate_payload=$(cat <<EOF
{
    "noise_data": "$NOISE_DATA",
    "grid_size": {"width": 50, "height": 50},
    "plate_sensitivity": 0.15,
    "min_plates": 5,
    "max_plates": 10,
    "complexity": "medium",
    "wrap_edges": false,
    "seed": 12345
}
EOF
)
    
    plate_response=$(curl -s --max-time 30 \
        -H "Content-Type: application/json" \
        -d "$plate_payload" \
        "$BACKEND_URL/api/plates/generate" 2>/dev/null || echo "")
    
    if [ -n "$plate_response" ] && check_json_success "$plate_response"; then
        echo -e "${GREEN}✅ PASS${NC}"
        
        # Extract plate count
        plate_count=$(echo "$plate_response" | jq '.data.metadata.plate_count' 2>/dev/null || echo "0")
        echo -e "${CYAN}   Generated $plate_count plates${NC}"
        
        save_test_result "basic_plates" "$plate_response"
        return 0
    else
        echo -e "${RED}❌ FAIL${NC}"
        echo -e "${YELLOW}Response: $plate_response${NC}"
        return 1
    fi
}

# Test 4: Different complexity levels
test_complexity_levels() {
    echo -e "\n${BLUE}🎨 Test 4: Complexity Levels${NC}"
    echo "-----------------------------"
    
    if [ -z "$NOISE_DATA" ]; then
        echo -e "${RED}❌ No noise data available${NC}"
        return 1
    fi
    
    complexities=("low" "medium" "high")
    
    for complexity in "${complexities[@]}"; do
        echo -n "Testing complexity '$complexity': "
        
        plate_payload=$(cat <<EOF
{
    "noise_data": "$NOISE_DATA",
    "grid_size": {"width": 40, "height": 40},
    "plate_sensitivity": 0.15,
    "min_plates": 6,
    "max_plates": 12,
    "complexity": "$complexity",
    "wrap_edges": false
}
EOF
)
        
        response=$(curl -s --max-time 30 \
            -H "Content-Type: application/json" \
            -d "$plate_payload" \
            "$BACKEND_URL/api/plates/generate" 2>/dev/null || echo "")
        
        if [ -n "$response" ] && check_json_success "$response"; then
            echo -e "${GREEN}✅ PASS${NC}"
            save_test_result "plates_${complexity}_complexity" "$response"
        else
            echo -e "${RED}❌ FAIL${NC}"
        fi
    done
}

# Test 5: Sensitivity variations
test_sensitivity_variations() {
    echo -e "\n${BLUE}🎛️ Test 5: Sensitivity Variations${NC}"
    echo "-----------------------------------"
    
    if [ -z "$NOISE_DATA" ]; then
        echo -e "${RED}❌ No noise data available${NC}"
        return 1
    fi
    
    sensitivities=("0.08" "0.15" "0.25" "0.35")
    
    for sensitivity in "${sensitivities[@]}"; do
        echo -n "Testing sensitivity $sensitivity: "
        
        plate_payload=$(cat <<EOF
{
    "noise_data": "$NOISE_DATA",
    "grid_size": {"width": 60, "height": 60},
    "plate_sensitivity": $sensitivity,
    "min_plates": 4,
    "max_plates": 20,
    "complexity": "medium",
    "wrap_edges": false
}
EOF
)
        
        response=$(curl -s --max-time 30 \
            -H "Content-Type: application/json" \
            -d "$plate_payload" \
            "$BACKEND_URL/api/plates/generate" 2>/dev/null || echo "")
        
        if [ -n "$response" ] && check_json_success "$response"; then
            plate_count=$(echo "$response" | jq '.data.metadata.plate_count' 2>/dev/null || echo "0")
            echo -e "${GREEN}✅ PASS${NC} (Generated $plate_count plates)"
            save_test_result "plates_sensitivity_${sensitivity}" "$response"
        else
            echo -e "${RED}❌ FAIL${NC}"
        fi
    done
}

# Test 6: Wrap-around functionality
test_wrap_around() {
    echo -e "\n${BLUE}🌐 Test 6: Wrap-Around (Spherical) Mode${NC}"
    echo "-----------------------------------------"
    
    if [ -z "$NOISE_DATA" ]; then
        echo -e "${RED}❌ No noise data available${NC}"
        return 1
    fi
    
    echo -n "Testing with wrap_edges=true: "
    
    plate_payload=$(cat <<EOF
{
    "noise_data": "$NOISE_DATA",
    "grid_size": {"width": 80, "height": 80},
    "plate_sensitivity": 0.15,
    "min_plates": 8,
    "max_plates": 15,
    "complexity": "medium",
    "wrap_edges": true,
    "seed": 54321
}
EOF
)
    
    response=$(curl -s --max-time 30 \
        -H "Content-Type: application/json" \
        -d "$plate_payload" \
        "$BACKEND_URL/api/plates/generate" 2>/dev/null || echo "")
    
    if [ -n "$response" ] && check_json_success "$response"; then
        echo -e "${GREEN}✅ PASS${NC}"
        save_test_result "plates_wrap_around" "$response"
    else
        echo -e "${RED}❌ FAIL${NC}"
    fi
}

# Test 7: Preset configurations
test_presets() {
    echo -e "\n${BLUE}🎯 Test 7: Preset Configurations${NC}"
    echo "---------------------------------"
    
    if [ -z "$NOISE_DATA" ]; then
        echo -e "${RED}❌ No noise data available${NC}"
        return 1
    fi
    
    # Get presets first
    presets_response=$(curl -s "$BACKEND_URL/api/plates/presets" 2>/dev/null)
    if [ -z "$presets_response" ]; then
        echo -e "${RED}❌ Could not fetch presets${NC}"
        return 1
    fi
    
    # Test Earth-like preset
    echo -n "Testing Earth-like preset: "
    
    earth_config=$(echo "$presets_response" | jq '.data.earth_like' 2>/dev/null)
    if [ -n "$earth_config" ] && [ "$earth_config" != "null" ]; then
        plate_payload=$(cat <<EOF
{
    "noise_data": "$NOISE_DATA",
    "grid_size": $(echo "$earth_config" | jq '.grid_size'),
    "plate_sensitivity": $(echo "$earth_config" | jq '.plate_sensitivity'),
    "min_plates": $(echo "$earth_config" | jq '.min_plates'),
    "max_plates": $(echo "$earth_config" | jq '.max_plates'),
    "complexity": $(echo "$earth_config" | jq '.complexity'),
    "wrap_edges": $(echo "$earth_config" | jq '.wrap_edges')
}
EOF
)
        
        response=$(curl -s --max-time 45 \
            -H "Content-Type: application/json" \
            -d "$plate_payload" \
            "$BACKEND_URL/api/plates/generate" 2>/dev/null || echo "")
        
        if [ -n "$response" ] && check_json_success "$response"; then
            plate_count=$(echo "$response" | jq '.data.metadata.plate_count' 2>/dev/null || echo "0")
            echo -e "${GREEN}✅ PASS${NC} (Generated $plate_count plates)"
            save_test_result "plates_earth_like_preset" "$response"
        else
            echo -e "${RED}❌ FAIL${NC}"
        fi
    else
        echo -e "${YELLOW}⚠️ SKIP (No preset data)${NC}"
    fi
}

# Test 8: Performance with different grid sizes
test_performance() {
    echo -e "\n${BLUE}⚡ Test 8: Performance Testing${NC}"
    echo "--------------------------------"
    
    if [ -z "$NOISE_DATA" ]; then
        echo -e "${RED}❌ No noise data available${NC}"
        return 1
    fi
    
    grid_sizes=("30" "60" "100" "150")
    
    for size in "${grid_sizes[@]}"; do
        echo -n "Testing ${size}x${size} grid: "
        
        plate_payload=$(cat <<EOF
{
    "noise_data": "$NOISE_DATA",
    "grid_size": {"width": $size, "height": $size},
    "plate_sensitivity": 0.15,
    "min_plates": 5,
    "max_plates": 15,
    "complexity": "medium",
    "wrap_edges": false
}
EOF
)
        
        start_time=$(date +%s.%N)
        response=$(curl -s --max-time 60 \
            -H "Content-Type: application/json" \
            -d "$plate_payload" \
            "$BACKEND_URL/api/plates/generate" 2>/dev/null || echo "")
        end_time=$(date +%s.%N)
        
        if [ -n "$response" ] && check_json_success "$response"; then
            duration=$(echo "$end_time - $start_time" | bc 2>/dev/null || echo "N/A")
            gen_time=$(echo "$response" | jq '.generation_time' 2>/dev/null || echo "N/A")
            echo -e "${GREEN}✅ PASS${NC} (Total: ${duration}s, Generation: ${gen_time}s)"
            save_test_result "plates_performance_${size}x${size}" "$response"
        else
            echo -e "${RED}❌ FAIL${NC}"
        fi
    done
}

# Test 9: Error handling
test_error_handling() {
    echo -e "\n${BLUE}🚨 Test 9: Error Handling${NC}"
    echo "--------------------------"
    
    # Test missing parameters
    echo -n "Missing required parameters: "
    empty_payload='{}'
    response=$(curl -s --max-time 10 \
        -H "Content-Type: application/json" \
        -d "$empty_payload" \
        "$BACKEND_URL/api/plates/generate" 2>/dev/null || echo "")
    
    if [ -n "$response" ] && ! check_json_success "$response"; then
        echo -e "${GREEN}✅ PASS${NC} (Correctly rejected)"
    else
        echo -e "${RED}❌ FAIL${NC} (Should have failed)"
    fi
    
    # Test invalid grid size
    echo -n "Invalid grid size (too small): "
    invalid_payload=$(cat <<EOF
{
    "noise_data": "$NOISE_DATA",
    "grid_size": {"width": 5, "height": 5},
    "plate_sensitivity": 0.15,
    "min_plates": 10,
    "max_plates": 20,
    "complexity": "medium"
}
EOF
)
    
    response=$(curl -s --max-time 10 \
        -H "Content-Type: application/json" \
        -d "$invalid_payload" \
        "$BACKEND_URL/api/plates/generate" 2>/dev/null || echo "")
    
    if [ -n "$response" ] && ! check_json_success "$response"; then
        echo -e "${GREEN}✅ PASS${NC} (Correctly rejected)"
        save_test_result "error_invalid_grid" "$response"
    else
        echo -e "${RED}❌ FAIL${NC} (Should have failed)"
    fi
    
    # Test invalid complexity
    echo -n "Invalid complexity value: "
    invalid_complexity=$(cat <<EOF
{
    "noise_data": "$NOISE_DATA",
    "grid_size": {"width": 50, "height": 50},
    "complexity": "extreme"
}
EOF
)
    
    response=$(curl -s --max-time 10 \
        -H "Content-Type: application/json" \
        -d "$invalid_complexity" \
        "$BACKEND_URL/api/plates/generate" 2>/dev/null || echo "")
    
    if [ -n "$response" ] && ! check_json_success "$response"; then
        echo -e "${GREEN}✅ PASS${NC} (Correctly rejected)"
    else
        echo -e "${RED}❌ FAIL${NC} (Should have failed)"
    fi
}

# Test 10: Different noise types as input
test_different_noise_inputs() {
    echo -e "\n${BLUE}🌈 Test 10: Different Noise Types as Input${NC}"
    echo "-------------------------------------------"
    
    noise_types=("perlin" "simplex" "worley")
    
    for noise_type in "${noise_types[@]}"; do
        echo -n "Generating $noise_type noise: "
        
        # Generate noise based on type
        if [ "$noise_type" = "perlin" ]; then
            noise_payload='{"width":64,"height":64,"scale":0.05,"octaves":4,"seed":99999}'
        elif [ "$noise_type" = "simplex" ]; then
            noise_payload='{"width":64,"height":64,"scale":0.02,"octaves":5,"seed":99999}'
        else  # worley
            noise_payload='{"width":64,"height":64,"frequency":0.1,"distance_function":"euclidean","cell_type":"F1","seed":99999}'
        fi
        
        noise_response=$(curl -s --max-time 30 \
            -H "Content-Type: application/json" \
            -d "$noise_payload" \
            "$BACKEND_URL/api/noise/$noise_type" 2>/dev/null || echo "")
        
        if [ -n "$noise_response" ] && check_json_success "$noise_response"; then
            noise_data=$(echo "$noise_response" | jq -r '.data.image_data' 2>/dev/null || echo "")
            
            if [ -n "$noise_data" ]; then
                echo -e "${GREEN}✅${NC}"
                echo -n "  Generating plates from $noise_type: "
                
                plate_payload=$(cat <<EOF
{
    "noise_data": "$noise_data",
    "grid_size": {"width": 40, "height": 40},
    "plate_sensitivity": 0.15,
    "min_plates": 5,
    "max_plates": 12,
    "complexity": "medium",
    "wrap_edges": false
}
EOF
)
                
                plate_response=$(curl -s --max-time 30 \
                    -H "Content-Type: application/json" \
                    -d "$plate_payload" \
                    "$BACKEND_URL/api/plates/generate" 2>/dev/null || echo "")
                
                if [ -n "$plate_response" ] && check_json_success "$plate_response"; then
                    plate_count=$(echo "$plate_response" | jq '.data.metadata.plate_count' 2>/dev/null || echo "0")
                    echo -e "${GREEN}✅ PASS${NC} ($plate_count plates)"
                    save_test_result "plates_from_${noise_type}" "$plate_response"
                else
                    echo -e "${RED}❌ FAIL${NC}"
                fi
            else
                echo -e "${RED}❌ FAIL${NC} (No noise data)"
            fi
        else
            echo -e "${RED}❌ FAIL${NC}"
        fi
    done
}

# Summary function
generate_summary() {
    echo -e "\n${BLUE}📊 Test Summary${NC}"
    echo "================"
    
    # Count JSON files created
    json_count=$(find "$TEST_OUTPUT_DIR" -name "*_${TIMESTAMP}.json" -type f | wc -l)
    echo -e "${CYAN}📁 Test results saved: $json_count files${NC}"
    echo -e "${CYAN}📂 Output directory: $TEST_OUTPUT_DIR${NC}"
    
    # Show file sizes
    echo -e "\n${YELLOW}File sizes:${NC}"
    du -h "$TEST_OUTPUT_DIR"/*_${TIMESTAMP}.json 2>/dev/null | tail -10
}

# Main execution
main() {
    echo -e "${BLUE}🚀 Starting Tectonic Plates System Tests${NC}"
    
    # Check if backend is running
    echo -n "Checking backend status: "
    if curl -s --max-time 5 "$BACKEND_URL/api/health" > /dev/null 2>&1; then
        echo -e "${GREEN}✅ Backend is running${NC}"
    else
        echo -e "${RED}❌ Backend not responding${NC}"
        echo -e "${YELLOW}💡 Start backend with: docker-compose up -d backend${NC}"
        exit 1
    fi
    
    # Run all tests
    test_plate_endpoints
    generate_test_noise
    test_basic_plate_generation
    test_complexity_levels
    test_sensitivity_variations
    test_wrap_around
    test_presets
    test_performance
    test_error_handling
    test_different_noise_inputs
    
    # Generate summary
    generate_summary
    
    echo -e "\n${GREEN}🎉 Tectonic Plates Test Suite Complete!${NC}"
}

# Show usage
if [ "$1" = "--help" ] || [ "$1" = "-h" ]; then
    echo "Usage: $0 [OPTIONS]"
    echo ""
    echo "Options:"
    echo "  --help, -h     Show this help message"
    echo "  --quick        Run only basic tests"
    echo "  --performance  Focus on performance tests"
    echo ""
    echo "Environment variables:"
    echo "  BACKEND_URL    Backend URL (default: http://localhost:5000)"
    echo ""
    echo "Examples:"
    echo "  $0                    # Run all tests"
    echo "  $0 --quick           # Run basic tests only"
    echo "  BACKEND_URL=http://192.168.1.100:5000 $0"
    exit 0
fi

# Quick mode
if [ "$1" = "--quick" ]; then
    echo -e "${YELLOW}⚡ Quick mode - Running essential tests only${NC}"
    test_plate_endpoints
    generate_test_noise
    test_basic_plate_generation
    generate_summary
    exit 0
fi

# Performance mode
if [ "$1" = "--performance" ]; then
    echo -e "${YELLOW}⚡ Performance mode${NC}"
    generate_test_noise
    test_performance
    generate_summary
    exit 0
fi

# Run main tests
main