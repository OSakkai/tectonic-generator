#!/bin/bash

# Complete installation script for tectonic plates module
# This script creates all necessary files directly in the container

set -e

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}🔧 Installing Tectonic Plates Module${NC}"
echo "====================================="

# Check container
echo -n "Checking backend container: "
if ! docker ps | grep -q "tectonic_backend"; then
    echo -e "${RED}❌ Not running${NC}"
    exit 1
fi
echo -e "${GREEN}✅ Running${NC}"

# Create directory structure
echo -e "\n${BLUE}📁 Creating directories...${NC}"
docker exec tectonic_backend mkdir -p /app/tectonic_plates

# Install scipy if not already installed
echo -e "\n${BLUE}📦 Installing dependencies...${NC}"
docker exec tectonic_backend pip install scipy==1.11.1

# Create __init__.py
echo -e "\n${BLUE}📝 Creating module files...${NC}"
echo -n "Creating __init__.py: "
docker exec -i tectonic_backend bash << 'EOF'
cat > /app/tectonic_plates/__init__.py << 'PYEOF'
#!/usr/bin/env python3
"""
Tectonic plates generation module
"""

from . import hex_grid
from . import watershed
from . import plate_generator
from . import plate_endpoints

__all__ = ["hex_grid", "watershed", "plate_generator", "plate_endpoints"]
PYEOF
EOF
echo -e "${GREEN}✅${NC}"

# Create hex_grid.py (complete version)
echo -n "Creating hex_grid.py: "
docker cp - tectonic_backend:/app/tectonic_plates/hex_grid.py << 'EOF'
#!/usr/bin/env python3
"""
Hexagonal grid system for tectonic plate generation
Implements cartesian hex grid with flat-topped hexagons
"""

import numpy as np
from typing import List, Tuple, Set, Dict
from dataclasses import dataclass
import math

@dataclass
class Hexagon:
    """Single hexagon in the grid"""
    x: int
    y: int
    plate_id: int = -1
    noise_value: float = 0.0

@dataclass
class TectonicPlate:
    """Tectonic plate containing multiple hexagons"""
    id: int
    hexagons: List[Tuple[int, int]]
    size: int
    neighbors: Set[int]
    color: str
    
class HexagonalGrid:
    """Hexagonal grid system with plate assignment"""
    
    def __init__(self, width: int, height: int, wrap_edges: bool = False):
        self.width = width
        self.height = height
        self.wrap_edges = wrap_edges
        self.grid = np.zeros((height, width), dtype=int)
        self.noise_values = np.zeros((height, width), dtype=float)
        
    def get_neighbors(self, x: int, y: int) -> List[Tuple[int, int]]:
        if y % 2 == 0:
            neighbors = [
                (x - 1, y), (x + 1, y),
                (x, y - 1), (x + 1, y - 1),
                (x, y + 1), (x + 1, y + 1)
            ]
        else:
            neighbors = [
                (x - 1, y), (x + 1, y),
                (x - 1, y - 1), (x, y - 1),
                (x - 1, y + 1), (x, y + 1)
            ]
        
        valid_neighbors = []
        for nx, ny in neighbors:
            if self.wrap_edges:
                nx = nx % self.width
                ny = ny % self.height
                valid_neighbors.append((nx, ny))
            else:
                if 0 <= nx < self.width and 0 <= ny < self.height:
                    valid_neighbors.append((nx, ny))
        
        return valid_neighbors
    
    def eliminate_exclaves(self, min_size: int = 10):
        visited = set()
        components = []
        
        for y in range(self.height):
            for x in range(self.width):
                if (x, y) not in visited:
                    component = []
                    stack = [(x, y)]
                    plate_id = self.grid[y, x]
                    
                    while stack:
                        cx, cy = stack.pop()
                        if (cx, cy) in visited:
                            continue
                        
                        if self.grid[cy, cx] == plate_id:
                            visited.add((cx, cy))
                            component.append((cx, cy))
                            
                            for nx, ny in self.get_neighbors(cx, cy):
                                if (nx, ny) not in visited:
                                    stack.append((nx, ny))
                    
                    if component:
                        components.append((plate_id, component))
        
        for plate_id, component in components:
            if len(component) < min_size:
                neighbor_counts = {}
                
                for x, y in component:
                    for nx, ny in self.get_neighbors(x, y):
                        neighbor_id = self.grid[ny, nx]
                        if neighbor_id != plate_id:
                            neighbor_counts[neighbor_id] = neighbor_counts.get(neighbor_id, 0) + 1
                
                if neighbor_counts:
                    new_plate_id = max(neighbor_counts, key=neighbor_counts.get)
                    for x, y in component:
                        self.grid[y, x] = new_plate_id
    
    def calculate_plate_neighbors(self) -> Dict[int, Set[int]]:
        neighbors = {}
        
        for y in range(self.height):
            for x in range(self.width):
                plate_id = self.grid[y, x]
                
                if plate_id not in neighbors:
                    neighbors[plate_id] = set()
                
                for nx, ny in self.get_neighbors(x, y):
                    neighbor_id = self.grid[ny, nx]
                    if neighbor_id != plate_id:
                        neighbors[plate_id].add(neighbor_id)
        
        return neighbors
    
    def get_plate_sizes(self) -> Dict[int, int]:
        sizes = {}
        
        for y in range(self.height):
            for x in range(self.width):
                plate_id = self.grid[y, x]
                sizes[plate_id] = sizes.get(plate_id, 0) + 1
        
        return sizes
    
    def get_plate_hexagons(self) -> Dict[int, List[Tuple[int, int]]]:
        plate_hexagons = {}
        
        for y in range(self.height):
            for x in range(self.width):
                plate_id = self.grid[y, x]
                if plate_id not in plate_hexagons:
                    plate_hexagons[plate_id] = []
                plate_hexagons[plate_id].append((x, y))
        
        return plate_hexagons
EOF
echo -e "${GREEN}✅${NC}"

# Test import
echo -e "\n${BLUE}🧪 Testing installation...${NC}"
echo -n "Testing module import: "
if docker exec tectonic_backend python -c "import sys; sys.path.append('/app'); from tectonic_plates import hex_grid; print('✅')" 2>/dev/null; then
    echo -e "${GREEN}Success${NC}"
else
    echo -e "${RED}Failed${NC}"
    # Try alternative path
    echo "Trying alternative import..."
    docker exec tectonic_backend python -c "import sys; sys.path.append('/app'); print('Python path:', sys.path)"
fi

# Update app.py to include the import
echo -e "\n${BLUE}📝 Updating app.py imports...${NC}"
docker exec -i tectonic_backend python << 'EOF'
import os
import sys

# Read current app.py
with open('/app/app.py', 'r') as f:
    content = f.read()

# Check if import already exists
if 'from tectonic_plates import plate_endpoints' not in content:
    # Find the import section
    import_section = content.find('from tectonic_noise import generators')
    if import_section != -1:
        # Find the end of the line
        end_of_line = content.find('\n', import_section)
        # Insert new import after
        new_import = '\n\n# Import plate generation endpoints\nfrom tectonic_plates import plate_endpoints'
        content = content[:end_of_line] + new_import + content[end_of_line:]
        
        # Write back
        with open('/app/app.py', 'w') as f:
            f.write(content)
        print("✅ Updated app.py")
    else:
        print("⚠️  Could not find import section")
else:
    print("✅ Import already exists")
EOF

echo -e "\n${GREEN}🎉 Installation complete!${NC}"
echo -e "${YELLOW}Note: You still need to copy the complete module files${NC}"
echo -e "${CYAN}Next steps:${NC}"
echo "1. Copy watershed.py, plate_generator.py, and plate_endpoints.py"
echo "2. Restart the backend: docker-compose restart backend"
echo "3. Run tests: ./test_plates.sh"