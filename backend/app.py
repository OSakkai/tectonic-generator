#!/usr/bin/env python3
from flask import Flask, jsonify, request
from flask_cors import CORS
import os
import time

# Import noise generation endpoints (FIXED - renamed module)
from tectonic_noise import generators

# Initialize Flask app
app = Flask(__name__)
CORS(app)

# Configuration
app.config['DEBUG'] = os.getenv('FLASK_DEBUG', '1') == '1'
app.config['ENV'] = os.getenv('FLASK_ENV', 'development')

# Standard API response format
def create_response(success=True, data=None, message="", error=None, generation_time=None, parameters_used=None):
    """Create standardized API response"""
    response = {
        "success": success,
        "data": data,
        "message": message
    }
    
    if error:
        response["error"] = error
    if generation_time is not None:
        response["generation_time"] = generation_time
    if parameters_used:
        response["parameters_used"] = parameters_used
        
    return jsonify(response)

# Health check endpoint
@app.route('/api/health', methods=['GET'])
def health_check():
    """Health check endpoint"""
    return create_response(
        success=True,
        data={
            "status": "healthy", 
            "version": "1.0.0",
            "algorithms": ["perlin", "simplex", "worley"],
            "max_resolution": 4096,
            "endpoints": [
                "/api/noise/generate",
                "/api/noise/perlin", 
                "/api/noise/simplex",
                "/api/noise/worley"
            ]
        },
        message="Tectonic Generator Backend is running"
    )

# Test endpoint for initial setup
@app.route('/api/test', methods=['GET'])
def test_endpoint():
    """Test endpoint for initial setup validation"""
    return create_response(
        success=True,
        data={
            "backend_status": "operational",
            "environment": app.config['ENV'],
            "debug": app.config['DEBUG'],
            "timestamp": time.time(),
            "noise_algorithms": {
                "perlin": "Ready",
                "simplex": "Ready", 
                "worley": "Ready"
            }
        },
        message="Backend test successful - All noise algorithms loaded"
    )

# Root endpoint
@app.route('/', methods=['GET'])
def root():
    """Root endpoint"""
    return create_response(
        success=True,
        data={"service": "Tectonic Generator API", "version": "1.0.0"},
        message="Welcome to Tectonic Generator Backend"
    )

# ============ NOISE GENERATION ENDPOINTS ============

# General noise generation endpoint
@app.route('/api/noise/generate', methods=['POST'])
def noise_generate():
    """General noise generation endpoint"""
    return generators.generate_noise_endpoint()

# Perlin noise endpoint
@app.route('/api/noise/perlin', methods=['POST'])
def noise_perlin():
    """Perlin noise specific endpoint"""
    return generators.generate_perlin_endpoint()

# Simplex noise endpoint
@app.route('/api/noise/simplex', methods=['POST'])
def noise_simplex():
    """Simplex noise specific endpoint"""
    return generators.generate_simplex_endpoint()

# Worley noise endpoint
@app.route('/api/noise/worley', methods=['POST'])
def noise_worley():
    """Worley noise specific endpoint"""
    return generators.generate_worley_endpoint()

# ============ UTILITY ENDPOINTS ============

@app.route('/api/noise/parameters', methods=['GET'])
def noise_parameters():
    """Get valid parameter ranges for all noise types"""
    return create_response(
        success=True,
        data={
            "perlin": {
                "scale": {"min": 0.001, "max": 0.1, "default": 0.05},
                "octaves": {"min": 1, "max": 6, "default": 4},
                "persistence": {"min": 0.1, "max": 0.8, "default": 0.5},
                "lacunarity": {"min": 1.5, "max": 3.0, "default": 2.0},
                "seed": {"min": 0, "max": 999999, "default": None}
            },
            "simplex": {
                "scale": {"min": 0.005, "max": 0.05, "default": 0.02},
                "octaves": {"min": 2, "max": 8, "default": 5},
                "persistence": {"min": 0.2, "max": 0.7, "default": 0.4},
                "lacunarity": {"min": 2.0, "max": 4.0, "default": 3.0},
                "seed": {"min": 0, "max": 999999, "default": None}
            },
            "worley": {
                "frequency": {"min": 0.05, "max": 0.5, "default": 0.1},
                "distance_function": {"options": ["euclidean", "manhattan", "chebyshev"], "default": "euclidean"},
                "cell_type": {"options": ["F1", "F2", "F1-F2"], "default": "F1"},
                "seed": {"min": 0, "max": 999999, "default": None}
            },
            "general": {
                "max_resolution": 4096,
                "max_generation_time": 30
            }
        },
        message="Parameter specifications for all noise algorithms"
    )

@app.route('/api/noise/presets', methods=['GET'])
def noise_presets():
    """Get preset parameter configurations"""
    return create_response(
        success=True,
        data={
            "perlin": {
                "continental": {"scale": 0.02, "octaves": 5, "persistence": 0.6, "lacunarity": 2.5},
                "oceanic": {"scale": 0.08, "octaves": 3, "persistence": 0.3, "lacunarity": 2.0},
                "detailed": {"scale": 0.1, "octaves": 6, "persistence": 0.7, "lacunarity": 2.8},
                "smooth": {"scale": 0.001, "octaves": 2, "persistence": 0.2, "lacunarity": 1.8}
            },
            "simplex": {
                "ridged": {"scale": 0.03, "octaves": 6, "persistence": 0.5, "lacunarity": 2.5},
                "turbulent": {"scale": 0.025, "octaves": 7, "persistence": 0.6, "lacunarity": 3.5},
                "continental_shelf": {"scale": 0.01, "octaves": 4, "persistence": 0.3, "lacunarity": 2.2},
                "standard": {"scale": 0.02, "octaves": 5, "persistence": 0.4, "lacunarity": 3.0}
            },
            "worley": {
                "plates": {"frequency": 0.08, "distance_function": "euclidean", "cell_type": "F1"},
                "boundaries": {"frequency": 0.1, "distance_function": "euclidean", "cell_type": "F1-F2"},
                "volcanic": {"frequency": 0.2, "distance_function": "manhattan", "cell_type": "F2"},
                "fractures": {"frequency": 0.15, "distance_function": "chebyshev", "cell_type": "F1-F2"}
            }
        },
        message="Preset configurations for common geological patterns"
    )

# ============ ERROR HANDLERS ============

@app.errorhandler(404)
def not_found(error):
    return create_response(
        success=False,
        error="Endpoint not found",
        message="The requested endpoint does not exist"
    ), 404

@app.errorhandler(500)
def internal_error(error):
    return create_response(
        success=False,
        error="Internal server error",
        message="An unexpected error occurred"
    ), 500

@app.errorhandler(413)
def payload_too_large(error):
    return create_response(
        success=False,
        error="Payload too large",
        message="Request payload exceeds maximum size"
    ), 413

@app.errorhandler(400)
def bad_request(error):
    return create_response(
        success=False,
        error="Bad request",
        message="Invalid request format or parameters"
    ), 400

if __name__ == '__main__':
    # Ensure data directory exists
    os.makedirs('/app/data/exports', exist_ok=True)
    
    print("Starting Tectonic Generator Backend...")
    print(f"Environment: {app.config['ENV']}")
    print(f"Debug mode: {app.config['DEBUG']}")
    print("Available endpoints:")
    print("  - /api/health (GET)")
    print("  - /api/test (GET)")
    print("  - /api/noise/generate (POST)")
    print("  - /api/noise/perlin (POST)")
    print("  - /api/noise/simplex (POST)")
    print("  - /api/noise/worley (POST)")
    print("  - /api/noise/parameters (GET)")
    print("  - /api/noise/presets (GET)")
    
    app.run(
        host='0.0.0.0',
        port=5000,
        debug=app.config['DEBUG']
    )