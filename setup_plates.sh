#!/bin/bash

# Setup script for Tectonic Plates module
# Installs files into backend container via docker exec

set -e

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}🔧 Tectonic Plates Module Setup${NC}"
echo "================================"

# Check if backend container is running
echo -n "Checking backend container: "
if docker ps | grep -q "tectonic_backend"; then
    echo -e "${GREEN}✅ Running${NC}"
else
    echo -e "${RED}❌ Not running${NC}"
    echo -e "${YELLOW}Starting backend container...${NC}"
    docker-compose up -d backend
    sleep 10
fi

# Create tectonic_plates directory in container
echo -e "\n${BLUE}📁 Creating module directory...${NC}"
docker exec tectonic_backend mkdir -p /app/backend/tectonic_plates

# Create module files
echo -e "\n${BLUE}📝 Creating module files...${NC}"

# Create __init__.py
echo -n "Creating __init__.py: "
docker exec tectonic_backend bash -c 'cat > /app/backend/tectonic_plates/__init__.py << "EOF"
#!/usr/bin/env python3
"""
Tectonic plates generation module
"""

from . import hex_grid
from . import watershed
from . import plate_generator
from . import plate_endpoints

__all__ = ["hex_grid", "watershed", "plate_generator", "plate_endpoints"]
EOF'
echo -e "${GREEN}✅ Done${NC}"

# Create hex_grid.py (truncated for SSH - you'll need to copy the full version)
echo -n "Creating hex_grid.py: "
docker exec tectonic_backend bash -c 'cat > /app/backend/tectonic_plates/hex_grid.py << "EOF"
#!/usr/bin/env python3
"""
Hexagonal grid system for tectonic plate generation
Note: This is a placeholder - copy the full implementation
"""

import numpy as np
from typing import List, Tuple, Set, Dict
from dataclasses import dataclass
import math

@dataclass
class Hexagon:
    x: int
    y: int
    plate_id: int = -1
    noise_value: float = 0.0

@dataclass
class TectonicPlate:
    id: int
    hexagons: List[Tuple[int, int]]
    size: int
    neighbors: Set[int]
    color: str

# Placeholder - implement full HexagonalGrid class
class HexagonalGrid:
    def __init__(self, width: int, height: int, wrap_edges: bool = False):
        self.width = width
        self.height = height
        self.wrap_edges = wrap_edges
        self.grid = np.zeros((height, width), dtype=int)
        self.noise_values = np.zeros((height, width), dtype=float)
EOF'
echo -e "${GREEN}✅ Done${NC}"

# Update requirements.txt
echo -e "\n${BLUE}📦 Updating requirements.txt...${NC}"
docker exec tectonic_backend bash -c 'grep -q "scipy" /app/requirements.txt || echo "scipy==1.11.1" >> /app/requirements.txt'

# Install new requirements
echo -e "\n${BLUE}📥 Installing dependencies...${NC}"
docker exec tectonic_backend pip install scipy==1.11.1

# Test import
echo -e "\n${BLUE}🧪 Testing module import...${NC}"
echo -n "Testing tectonic_plates import: "
if docker exec tectonic_backend python -c "import backend.tectonic_plates" 2>/dev/null; then
    echo -e "${GREEN}✅ Success${NC}"
else
    echo -e "${RED}❌ Failed${NC}"
    echo -e "${YELLOW}Note: You need to copy the full implementation files${NC}"
fi

# Create file transfer script
echo -e "\n${BLUE}📄 Creating file transfer helper...${NC}"
cat > transfer_plates_files.sh << 'TRANSFER_EOF'
#!/bin/bash

# Transfer complete plate module files to container
# Usage: ./transfer_plates_files.sh /path/to/source/files

SOURCE_DIR="${1:-.}"
CONTAINER="tectonic_backend"

echo "Transferring plate module files from $SOURCE_DIR to container..."

# List of files to transfer
FILES=(
    "hex_grid.py"
    "watershed.py"
    "plate_generator.py"
    "plate_endpoints.py"
    "__init__.py"
)

for file in "${FILES[@]}"; do
    if [ -f "$SOURCE_DIR/$file" ]; then
        echo -n "Transferring $file: "
        docker cp "$SOURCE_DIR/$file" "$CONTAINER:/app/backend/tectonic_plates/$file"
        echo "✅"
    else
        echo "⚠️  $file not found in $SOURCE_DIR"
    fi
done

# Update app.py
if [ -f "$SOURCE_DIR/app.py" ]; then
    echo -n "Updating app.py: "
    docker cp "$SOURCE_DIR/app.py" "$CONTAINER:/app/app.py"
    echo "✅"
fi

echo "Transfer complete!"
TRANSFER_EOF

chmod +x transfer_plates_files.sh
echo -e "${GREEN}✅ Created transfer_plates_files.sh${NC}"

# Create verification script
echo -e "\n${BLUE}🔍 Creating verification script...${NC}"
cat > verify_plates_installation.sh << 'VERIFY_EOF'
#!/bin/bash

# Verify plate module installation

echo "🔍 Verifying Tectonic Plates Module Installation"
echo "================================================"

# Check files exist
echo -e "\n📁 Checking module files:"
docker exec tectonic_backend ls -la /app/backend/tectonic_plates/

# Test imports
echo -e "\n🧪 Testing imports:"
docker exec tectonic_backend python -c "
try:
    from backend.tectonic_plates import hex_grid
    print('✅ hex_grid import successful')
except Exception as e:
    print(f'❌ hex_grid import failed: {e}')

try:
    from backend.tectonic_plates import watershed
    print('✅ watershed import successful')
except Exception as e:
    print(f'❌ watershed import failed: {e}')

try:
    from backend.tectonic_plates import plate_generator
    print('✅ plate_generator import successful')
except Exception as e:
    print(f'❌ plate_generator import failed: {e}')

try:
    from backend.tectonic_plates import plate_endpoints
    print('✅ plate_endpoints import successful')
except Exception as e:
    print(f'❌ plate_endpoints import failed: {e}')
"

# Test endpoints
echo -e "\n🌐 Testing API endpoints:"
curl -s http://localhost:5000/api/plates/parameters | jq '.success' || echo "❌ Parameters endpoint failed"
curl -s http://localhost:5000/api/plates/presets | jq '.success' || echo "❌ Presets endpoint failed"

echo -e "\n✅ Verification complete!"
VERIFY_EOF

chmod +x verify_plates_installation.sh
echo -e "${GREEN}✅ Created verify_plates_installation.sh${NC}"

# Summary
echo -e "\n${BLUE}📋 Setup Summary${NC}"
echo "================"
echo -e "${GREEN}✅ Created tectonic_plates module directory${NC}"
echo -e "${GREEN}✅ Created placeholder module files${NC}"
echo -e "${GREEN}✅ Updated requirements.txt with scipy${NC}"
echo -e "${GREEN}✅ Created helper scripts:${NC}"
echo "   - transfer_plates_files.sh - Transfer complete files to container"
echo "   - verify_plates_installation.sh - Verify installation"
echo ""
echo -e "${YELLOW}⚠️  IMPORTANT: The module files are placeholders!${NC}"
echo -e "${YELLOW}   You need to copy the full implementation files.${NC}"
echo ""
echo -e "${CYAN}Next steps:${NC}"
echo "1. Save the complete module files locally"
echo "2. Run: ./transfer_plates_files.sh /path/to/files"
echo "3. Run: ./verify_plates_installation.sh"
echo "4. Run: ./test_plates.sh"

echo -e "\n${GREEN}🎉 Setup script complete!${NC}"