#!/bin/bash

# Fixed version of noise data extraction for test_plates.sh
# This version handles the data extraction correctly

set -e

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

BACKEND_URL="http://localhost:5000"

echo -e "${BLUE}🔧 Testing Noise Data Extraction Fix${NC}"
echo "====================================="

# Generate test noise
echo -e "\n${BLUE}Generating Worley noise...${NC}"
worley_response=$(curl -s --max-time 30 \
    -H "Content-Type: application/json" \
    -d '{"width":64,"height":64,"frequency":0.08,"distance_function":"euclidean","cell_type":"F1","seed":12345}' \
    "$BACKEND_URL/api/noise/worley")

# Save response for debugging
echo "$worley_response" > debug_worley_response.json

# Method 1: Using jq (if available)
if command -v jq &> /dev/null; then
    echo -e "\n${BLUE}Method 1: Extracting with jq${NC}"
    NOISE_DATA=$(echo "$worley_response" | jq -r '.data.image_data')
    if [ -n "$NOISE_DATA" ] && [ "$NOISE_DATA" != "null" ]; then
        echo -e "${GREEN}✅ Successfully extracted noise data with jq${NC}"
        echo "Data length: ${#NOISE_DATA}"
        echo "First 100 chars: ${NOISE_DATA:0:100}..."
    else
        echo -e "${RED}❌ Failed to extract with jq${NC}"
    fi
fi

# Method 2: Using Python (more reliable)
echo -e "\n${BLUE}Method 2: Extracting with Python${NC}"
NOISE_DATA_PYTHON=$(python3 -c "
import json
import sys

try:
    data = json.loads('''$worley_response''')
    if 'data' in data and 'image_data' in data['data']:
        print(data['data']['image_data'])
    else:
        print('ERROR: No image_data found', file=sys.stderr)
except Exception as e:
    print(f'ERROR: {e}', file=sys.stderr)
" 2>&1)

if [[ ! "$NOISE_DATA_PYTHON" =~ ^ERROR ]] && [ -n "$NOISE_DATA_PYTHON" ]; then
    echo -e "${GREEN}✅ Successfully extracted noise data with Python${NC}"
    NOISE_DATA="$NOISE_DATA_PYTHON"
    echo "Data length: ${#NOISE_DATA}"
    echo "First 100 chars: ${NOISE_DATA:0:100}..."
else
    echo -e "${RED}❌ Failed to extract with Python: $NOISE_DATA_PYTHON${NC}"
fi

# Method 3: Using grep and sed (fallback)
echo -e "\n${BLUE}Method 3: Extracting with grep/sed${NC}"
NOISE_DATA_SED=$(echo "$worley_response" | grep -o '"image_data"[[:space:]]*:[[:space:]]*"[^"]*"' | sed 's/.*"image_data"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/')

if [ -n "$NOISE_DATA_SED" ]; then
    echo -e "${GREEN}✅ Successfully extracted noise data with sed${NC}"
    echo "Data length: ${#NOISE_DATA_SED}"
    echo "First 100 chars: ${NOISE_DATA_SED:0:100}..."
else
    echo -e "${RED}❌ Failed to extract with sed${NC}"
fi

# Test plate generation with extracted data
if [ -n "$NOISE_DATA" ] && [ "$NOISE_DATA" != "null" ]; then
    echo -e "\n${BLUE}Testing plate generation with extracted data...${NC}"
    
    plate_payload=$(cat <<EOF
{
    "noise_data": "$NOISE_DATA",
    "grid_size": {"width": 30, "height": 30},
    "plate_sensitivity": 0.15,
    "min_plates": 4,
    "max_plates": 10,
    "complexity": "medium",
    "wrap_edges": false
}
EOF
)
    
    echo "Payload size: ${#plate_payload} bytes"
    
    plate_response=$(curl -s --max-time 30 \
        -H "Content-Type: application/json" \
        -d "$plate_payload" \
        "$BACKEND_URL/api/plates/generate" 2>&1)
    
    echo -e "\n${BLUE}Plate generation response:${NC}"
    echo "$plate_response" | head -200
    
    # Check if successful
    if echo "$plate_response" | grep -q '"success"[[:space:]]*:[[:space:]]*true'; then
        echo -e "\n${GREEN}✅ Plate generation successful!${NC}"
    else
        echo -e "\n${RED}❌ Plate generation failed${NC}"
    fi
else
    echo -e "\n${RED}❌ No valid noise data to test plate generation${NC}"
fi

echo -e "\n${BLUE}Debug files created:${NC}"
echo "- debug_worley_response.json"
echo -e "\n${GREEN}Test complete!${NC}"