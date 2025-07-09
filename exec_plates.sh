#!/bin/bash

# Direct docker exec commands for plate system testing
# Useful for debugging and manual testing

set -e

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

echo -e "${BLUE}🐳 Docker Exec Commands for Plate System${NC}"
echo "========================================="

# Function to run command in backend container
run_in_backend() {
    docker exec tectonic_backend "$@"
}

# Test 1: Check module structure
test_module_structure() {
    echo -e "\n${BLUE}📁 Test 1: Module Structure${NC}"
    echo "----------------------------"
    
    echo "Checking tectonic_plates directory:"
    run_in_backend ls -la /app/backend/tectonic_plates/ || echo -e "${RED}Directory not found${NC}"
    
    echo -e "\nChecking Python path:"
    run_in_backend python -c "import sys; print('\\n'.join(sys.path))"
}

# Test 2: Test individual imports
test_imports() {
    echo -e "\n${BLUE}🧪 Test 2: Testing Imports${NC}"
    echo "---------------------------"
    
    echo -n "Testing hex_grid import: "
    if run_in_backend python -c "from backend.tectonic_plates.hex_grid import HexagonalGrid; print('✅')" 2>/dev/null; then
        echo -e "${GREEN}Success${NC}"
    else
        echo -e "${RED}Failed${NC}"
        run_in_backend python -c "from backend.tectonic_plates.hex_grid import HexagonalGrid" 2>&1 || true
    fi
    
    echo -n "Testing watershed import: "
    if run_in_backend python -c "from backend.tectonic_plates.watershed import WatershedSegmentation; print('✅')" 2>/dev/null; then
        echo -e "${GREEN}Success${NC}"
    else
        echo -e "${RED}Failed${NC}"
    fi
    
    echo -n "Testing plate_generator import: "
    if run_in_backend python -c "from backend.tectonic_plates.plate_generator import PlateGenerator; print('✅')" 2>/dev/null; then
        echo -e "${GREEN}Success${NC}"
    else
        echo -e "${RED}Failed${NC}"
    fi
}

# Test 3: Create test hexagonal grid
test_hex_grid() {
    echo -e "\n${BLUE}🔷 Test 3: Hexagonal Grid Creation${NC}"
    echo "------------------------------------"
    
    run_in_backend python << 'EOF'
import sys
sys.path.append('/app')

try:
    from backend.tectonic_plates.hex_grid import HexagonalGrid
    
    # Create small grid
    grid = HexagonalGrid(10, 10, wrap_edges=False)
    print(f"✅ Created grid: {grid.width}x{grid.height}")
    
    # Test neighbor calculation
    neighbors = grid.get_neighbors(5, 5)
    print(f"✅ Neighbors of (5,5): {len(neighbors)} hexagons")
    
    # Test hex to pixel conversion
    px, py = grid.hex_to_pixel(5, 5, 10.0)
    print(f"✅ Hex (5,5) -> Pixel ({px:.1f}, {py:.1f})")
    
except Exception as e:
    print(f"❌ Error: {e}")
    import traceback
    traceback.print_exc()
EOF
}

# Test 4: Test watershed algorithm
test_watershed() {
    echo -e "\n${BLUE}💧 Test 4: Watershed Algorithm${NC}"
    echo "-------------------------------"
    
    run_in_backend python << 'EOF'
import sys
sys.path.append('/app')

try:
    import numpy as np
    from backend.tectonic_plates.hex_grid import HexagonalGrid
    from backend.tectonic_plates.watershed import WatershedSegmentation
    
    # Create test data
    grid = HexagonalGrid(20, 20)
    watershed = WatershedSegmentation(grid)
    
    # Create simple noise map
    noise_map = np.random.rand(20, 20)
    print("✅ Created test noise map")
    
    # Find local minima
    seeds = watershed.find_local_minima(noise_map, target_plates=5)
    print(f"✅ Found {len(seeds)} seed points")
    
    # Run segmentation
    result = watershed.segment(noise_map, sensitivity=0.15, target_plates=5)
    unique_plates = np.unique(result[result > 0])
    print(f"✅ Generated {len(unique_plates)} plates")
    
except Exception as e:
    print(f"❌ Error: {e}")
    import traceback
    traceback.print_exc()
EOF
}

# Test 5: API endpoint integration
test_api_endpoints() {
    echo -e "\n${BLUE}🌐 Test 5: API Endpoints${NC}"
    echo "-------------------------"
    
    # Test from inside container
    echo "Testing parameters endpoint from inside container:"
    run_in_backend curl -s http://localhost:5000/api/plates/parameters | head -20
    
    echo -e "\nTesting presets endpoint from inside container:"
    run_in_backend curl -s http://localhost:5000/api/plates/presets | head -20
}

# Test 6: Generate small plate map
test_plate_generation() {
    echo -e "\n${BLUE}🗺️ Test 6: Plate Generation${NC}"
    echo "-----------------------------"
    
    run_in_backend python << 'EOF'
import sys
sys.path.append('/app')

try:
    import numpy as np
    import base64
    from io import BytesIO
    from PIL import Image
    from backend.tectonic_plates.plate_generator import PlateGenerator
    
    # Create simple noise image
    noise_array = np.random.rand(32, 32)
    noise_array = (noise_array * 255).astype(np.uint8)
    
    # Convert to base64
    img = Image.fromarray(noise_array, mode='L')
    buffer = BytesIO()
    img.save(buffer, format='PNG')
    noise_data = f"data:image/png;base64,{base64.b64encode(buffer.getvalue()).decode()}"
    
    print("✅ Created test noise data")
    
    # Generate plates
    generator = PlateGenerator()
    result = generator.generate_plates(
        noise_data=noise_data,
        grid_width=20,
        grid_height=20,
        sensitivity=0.15,
        min_plates=3,
        max_plates=8,
        complexity="medium",
        wrap_edges=False,
        seed=12345
    )
    
    print(f"✅ Generated {result['metadata']['plate_count']} plates")
    print(f"✅ Grid size: {result['metadata']['grid_size']}")
    print(f"✅ Total hexagons: {result['metadata']['total_hexagons']}")
    
except Exception as e:
    print(f"❌ Error: {e}")
    import traceback
    traceback.print_exc()
EOF
}

# Test 7: Check scipy installation
test_dependencies() {
    echo -e "\n${BLUE}📦 Test 7: Dependencies${NC}"
    echo "------------------------"
    
    echo -n "Checking scipy: "
    if run_in_backend python -c "import scipy; print(f'✅ Version {scipy.__version__}')" 2>/dev/null; then
        echo -e "${GREEN}Installed${NC}"
    else
        echo -e "${RED}Not installed${NC}"
        echo "Installing scipy..."
        run_in_backend pip install scipy==1.11.1
    fi
    
    echo -n "Checking PIL/Pillow: "
    run_in_backend python -c "import PIL; print(f'✅ Version {PIL.__version__}')" 2>/dev/null || echo -e "${RED}Not installed${NC}"
}

# Test 8: Memory and performance check
test_performance() {
    echo -e "\n${BLUE}⚡ Test 8: Performance Check${NC}"
    echo "------------------------------"
    
    run_in_backend python << 'EOF'
import sys
sys.path.append('/app')
import time
import numpy as np

try:
    from backend.tectonic_plates.hex_grid import HexagonalGrid
    from backend.tectonic_plates.watershed import WatershedSegmentation
    
    sizes = [(50, 50), (100, 100), (200, 200)]
    
    for width, height in sizes:
        start_time = time.time()
        
        # Create grid and run watershed
        grid = HexagonalGrid(width, height)
        watershed = WatershedSegmentation(grid)
        noise_map = np.random.rand(height, width)
        
        result = watershed.segment(noise_map, 0.15, 10, "medium")
        
        end_time = time.time()
        duration = end_time - start_time
        
        unique_plates = len(np.unique(result[result > 0]))
        total_hexagons = width * height
        
        print(f"✅ {width}x{height} grid: {duration:.3f}s ({total_hexagons} hexagons, {unique_plates} plates)")
        
except Exception as e:
    print(f"❌ Error: {e}")
EOF
}

# Menu system
show_menu() {
    echo -e "\n${CYAN}Select test to run:${NC}"
    echo "1) Module Structure"
    echo "2) Import Tests"
    echo "3) Hexagonal Grid"
    echo "4) Watershed Algorithm"
    echo "5) API Endpoints"
    echo "6) Plate Generation"
    echo "7) Dependencies"
    echo "8) Performance"
    echo "9) Run All Tests"
    echo "0) Exit"
}

# Main loop
while true; do
    show_menu
    read -p "Enter choice (0-9): " choice
    
    case $choice in
        1) test_module_structure ;;
        2) test_imports ;;
        3) test_hex_grid ;;
        4) test_watershed ;;
        5) test_api_endpoints ;;
        6) test_plate_generation ;;
        7) test_dependencies ;;
        8) test_performance ;;
        9) 
            test_module_structure
            test_imports
            test_hex_grid
            test_watershed
            test_api_endpoints
            test_plate_generation
            test_dependencies
            test_performance
            ;;
        0) 
            echo -e "${GREEN}Exiting...${NC}"
            exit 0
            ;;
        *)
            echo -e "${RED}Invalid choice${NC}"
            ;;
    esac
done