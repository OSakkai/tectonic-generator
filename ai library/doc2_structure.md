# TECTONIC GENERATOR PROJECT STRUCTURE v1.1

## PROJECT OVERVIEW
TECTONIC GENERATOR - Procedural generation system for realistic tectonic plates using advanced noise algorithms. Creates geologically accurate plate boundaries, movements, and resulting terrain for Minecraft WorldPainter integration.

Current Users: Single developer
Target Platform: Desktop Development
Production: Local Docker Environment

## TECHNOLOGY STACK

### BACKEND
Framework: Python 3.11 + Flask + NumPy
Noise Libraries: noise, opensimplex, perlin-noise
Image Processing: Pillow, matplotlib, scipy
API Format: REST with standardized responses

API Response Format (MANDATORY):
```json
{
  "success": boolean,
  "data": any,
  "message": string,
  "error"?: string,
  "generation_time"?: number,
  "parameters_used"?: object
}
```

### FRONTEND
Technology: React 18 + Modern JavaScript
Visualization: HTML5 Canvas + Custom Rendering
Styling: CSS Modules + CSS Variables
External Libraries: Axios for API communication only

Color Palette (STRICT):
```css
:root {
  --primary-blue: #3b82f6;
  --primary-red: #ef4444;
  --success-green: #10b981;
  --warning-orange: #f59e0b;
  --background-light: #f8fafc;
  --background-dark: #1e293b;
  --text-primary: #0f172a;
  --text-secondary: #64748b;
  --border-color: #e2e8f0;
  --noise-continental: #8B4513;
  --noise-oceanic: #4169E1;
  --plate-boundary: #FF0000;
}
```

### INFRASTRUCTURE
Containers: Docker Compose
Backend: Python Flask container + jq for testing
Frontend: React development container
Development: Local machine with hot reload
Production: Dockerized deployment ready

## ALGORITHM SPECIFICATIONS

### NOISE GENERATION PARAMETERS
```python
PERLIN_PARAMS = {
    "scale": (0.001, 0.1),      # Detail level
    "octaves": (1, 6),          # Complexity layers
    "persistence": (0.1, 0.8),  # Amplitude falloff
    "lacunarity": (1.5, 3.0),   # Frequency multiplier
    "seed": (0, 999999)         # Reproducibility
}

SIMPLEX_PARAMS = {
    "scale": (0.005, 0.05),
    "octaves": (2, 8),
    "persistence": (0.2, 0.7),
    "lacunarity": (2.0, 4.0)
}

WORLEY_PARAMS = {
    "frequency": (0.05, 0.5),
    "distance_function": ["euclidean", "manhattan", "chebyshev"],
    "cell_type": ["F1", "F2", "F1-F2"]
}
```

## PROJECT STRUCTURE

### BACKEND ARCHITECTURE
```
backend/
├── app.py                     # Flask application entry
├── requirements.txt           # Python dependencies
├── Dockerfile                # Container configuration
├── noise/
│   ├── __init__.py
│   ├── generators.py         # Core noise generation endpoints
│   ├── perlin.py            # Perlin noise implementation
│   ├── simplex.py           # Simplex noise implementation
│   └── worley.py            # Worley noise implementation
├── utils/
│   ├── __init__.py
│   ├── validation.py        # Parameter validation
│   └── image_processing.py  # Image manipulation
└── tests/
    └── test_complete_suite.py # Complete test suite
```

### FRONTEND ARCHITECTURE
```
frontend/
├── package.json              # Node dependencies
├── Dockerfile               # Container configuration
├── public/
│   └── index.html
├── src/
│   ├── App.js               # Main application component
│   ├── index.js             # React entry point
│   ├── components/
│   │   ├── NoiseVisualizer.js    # Canvas-based noise display
│   │   ├── ParameterPanel.js     # Control interface
│   │   └── ExportPanel.js        # Export options
│   ├── services/
│   │   └── NoiseService.js       # Backend communication
│   └── utils/
│       └── canvasHelpers.js      # Canvas utilities
```

## API ENDPOINTS

```
NOISE GENERATION:
POST /api/noise/generate
POST /api/noise/perlin
POST /api/noise/simplex
POST /api/noise/worley

UTILITIES:
GET /api/health
GET /api/noise/parameters
GET /api/noise/presets
```

## DOCKER CONFIGURATION

### docker-compose.yml Structure
```yaml
services:
  backend:
    build: ./backend
    container_name: tectonic_backend
    ports:
      - "5000:5000"
    volumes:
      - ./backend:/app
      - ./data:/app/data
    environment:
      - FLASK_ENV=development
      - FLASK_DEBUG=1
      - PYTHONPATH=/app
    restart: unless-stopped
    
  frontend:
    build: ./frontend
    container_name: tectonic_frontend
    ports:
      - "3000:3000"
    volumes:
      - ./frontend:/app
      - /app/node_modules
    environment:
      - CHOKIDAR_USEPOLLING=true
      - REACT_APP_API_URL=http://localhost:5000
    depends_on:
      - backend
    restart: unless-stopped
```

## CRITICAL CONSTRAINTS

### NOISE GENERATION LIMITS
```
MAX_RESOLUTION: 4096x4096 pixels
MAX_OCTAVES: 8 layers
MAX_GENERATION_TIME: 30 seconds
MIN_SCALE: 0.001
MAX_SCALE: 1.0
MEMORY_LIMIT: 2GB per generation
```

### PLATE DETECTION LIMITS
```
MIN_PLATES: 2
MAX_PLATES: 12
MIN_PLATE_SIZE: 5% of total area
MAX_BOUNDARY_COMPLEXITY: 1000 points
ANALYSIS_TIMEOUT: 60 seconds
```

## ENVIRONMENT CONFIGURATION

```bash
# Flask Backend
FLASK_ENV=development
FLASK_DEBUG=1
FLASK_HOST=0.0.0.0
FLASK_PORT=5000

# React Frontend
REACT_APP_API_URL=http://localhost:5000
CHOKIDAR_USEPOLLING=true
GENERATE_SOURCEMAP=false

# Generation Settings
MAX_RESOLUTION=4096
DEFAULT_SEED=12345
CACHE_GENERATIONS=true
EXPORT_DIRECTORY=/app/data/exports
```