#!/bin/bash

# Script to copy plate module files to container
# First save the Python files locally, then run this script

set -e

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}📂 Copying Plate Module Files${NC}"
echo "==============================="

# Check if files exist locally
LOCAL_DIR="./tectonic_plates"
if [ ! -d "$LOCAL_DIR" ]; then
    echo -e "${YELLOW}Creating local directory: $LOCAL_DIR${NC}"
    mkdir -p "$LOCAL_DIR"
    echo -e "${RED}⚠️  Please save the Python files to $LOCAL_DIR first!${NC}"
    echo "Required files:"
    echo "  - hex_grid.py"
    echo "  - watershed.py"
    echo "  - plate_generator.py"
    echo "  - plate_endpoints.py"
    echo "  - __init__.py"
    exit 1
fi

# Check container
if ! docker ps | grep -q "tectonic_backend"; then
    echo -e "${RED}❌ Backend container not running${NC}"
    exit 1
fi

# Create directory in container
echo -e "${BLUE}Creating directory in container...${NC}"
docker exec tectonic_backend mkdir -p /app/tectonic_plates

# Copy each file
FILES=("__init__.py" "hex_grid.py" "watershed.py" "plate_generator.py" "plate_endpoints.py")

for file in "${FILES[@]}"; do
    if [ -f "$LOCAL_DIR/$file" ]; then
        echo -n "Copying $file: "
        docker cp "$LOCAL_DIR/$file" tectonic_backend:/app/tectonic_plates/
        echo -e "${GREEN}✅${NC}"
    else
        echo -e "${YELLOW}⚠️  $file not found in $LOCAL_DIR${NC}"
    fi
done

# Fix permissions
echo -e "\n${BLUE}Fixing permissions...${NC}"
docker exec tectonic_backend chmod -R 755 /app/tectonic_plates
docker exec tectonic_backend chmod 644 /app/tectonic_plates/*.py

# Test imports
echo -e "\n${BLUE}Testing imports...${NC}"
docker exec tectonic_backend python -c "
import sys
sys.path.append('/app')
try:
    from tectonic_plates import hex_grid
    print('✅ hex_grid imported successfully')
except Exception as e:
    print(f'❌ hex_grid import failed: {e}')

try:
    from tectonic_plates import watershed
    print('✅ watershed imported successfully')
except Exception as e:
    print(f'❌ watershed import failed: {e}')

try:
    from tectonic_plates import plate_generator
    print('✅ plate_generator imported successfully')
except Exception as e:
    print(f'❌ plate_generator import failed: {e}')

try:
    from tectonic_plates import plate_endpoints
    print('✅ plate_endpoints imported successfully')
except Exception as e:
    print(f'❌ plate_endpoints import failed: {e}')
"

echo -e "\n${GREEN}🎉 File copy complete!${NC}"
echo -e "${CYAN}Next: Restart backend and run tests${NC}"