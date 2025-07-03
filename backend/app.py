#!/usr/bin/env python3
from flask import Flask, jsonify, request
from flask_cors import CORS
import os
import time

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
        data={"status": "healthy", "version": "1.0.0"},
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
            "timestamp": time.time()
        },
        message="Backend test successful"
    )

# Root endpoint
@app.route('/', methods=['GET'])
def root():
    """Root endpoint"""
    return create_response(
        success=True,
        data={"service": "Tectonic Generator API"},
        message="Welcome to Tectonic Generator Backend"
    )

# Error handlers
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

if __name__ == '__main__':
    # Ensure data directory exists
    os.makedirs('/app/data/exports', exist_ok=True)
    
    print("Starting Tectonic Generator Backend...")
    print(f"Environment: {app.config['ENV']}")
    print(f"Debug mode: {app.config['DEBUG']}")
    
    app.run(
        host='0.0.0.0',
        port=5000,
        debug=app.config['DEBUG']
    )