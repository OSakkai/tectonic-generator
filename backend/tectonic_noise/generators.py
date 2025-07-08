#!/usr/bin/env python3
"""
Core noise generation API endpoints integration
Follows doc2_structure.md specifications
"""

from flask import request, jsonify
import numpy as np
import time
from .perlin import generate_perlin_noise
from .simplex import generate_simplex_noise
from .worley import generate_worley_noise
from ..utils.validation import validate_noise_parameters
from ..utils.image_processing import normalize_array, array_to_image

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

def generate_noise_endpoint():
    """General noise generation endpoint - POST /api/noise/generate"""
    try:
        start_time = time.time()
        data = request.get_json()
        
        if not data:
            return create_response(
                success=False,
                error="No JSON data provided",
                message="Request must contain JSON data with noise parameters"
            ), 400
        
        # Extract parameters
        noise_type = data.get('type', 'perlin')
        width = data.get('width', 512)
        height = data.get('height', 512)
        parameters = data.get('parameters', {})
        
        # Validate parameters
        validation_result = validate_noise_parameters(noise_type, parameters, width, height)
        if not validation_result['valid']:
            return create_response(
                success=False,
                error=validation_result['error'],
                message="Parameter validation failed"
            ), 400
        
        # Generate noise based on type
        if noise_type == 'perlin':
            noise_array = generate_perlin_noise(width, height, **parameters)
        elif noise_type == 'simplex':
            noise_array = generate_simplex_noise(width, height, **parameters)
        elif noise_type == 'worley':
            noise_array = generate_worley_noise(width, height, **parameters)
        else:
            return create_response(
                success=False,
                error=f"Unsupported noise type: {noise_type}",
                message="Supported types: perlin, simplex, worley"
            ), 400
        
        # Normalize output to [0,1] range
        normalized_array = normalize_array(noise_array)
        
        # Convert to image data for frontend
        image_data = array_to_image(normalized_array)
        
        generation_time = time.time() - start_time
        
        return create_response(
            success=True,
            data={
                "noise_type": noise_type,
                "dimensions": {"width": width, "height": height},
                "image_data": image_data,
                "statistics": {
                    "min_value": float(np.min(normalized_array)),
                    "max_value": float(np.max(normalized_array)),
                    "mean_value": float(np.mean(normalized_array)),
                    "std_value": float(np.std(normalized_array))
                }
            },
            message=f"{noise_type.capitalize()} noise generated successfully",
            generation_time=generation_time,
            parameters_used=parameters
        )
        
    except Exception as e:
        return create_response(
            success=False,
            error=str(e),
            message="Failed to generate noise"
        ), 500

def generate_perlin_endpoint():
    """Perlin noise specific endpoint - POST /api/noise/perlin"""
    try:
        start_time = time.time()
        data = request.get_json()
        
        if not data:
            return create_response(
                success=False,
                error="No JSON data provided",
                message="Request must contain JSON data with Perlin parameters"
            ), 400
        
        # Extract Perlin-specific parameters with defaults from doc2_structure.md
        width = data.get('width', 512)
        height = data.get('height', 512)
        scale = data.get('scale', 0.05)
        octaves = data.get('octaves', 4)
        persistence = data.get('persistence', 0.5)
        lacunarity = data.get('lacunarity', 2.0)
        seed = data.get('seed', None)
        
        # Validate Perlin parameters
        parameters = {
            'scale': scale,
            'octaves': octaves,
            'persistence': persistence,
            'lacunarity': lacunarity,
            'seed': seed
        }
        
        validation_result = validate_noise_parameters('perlin', parameters, width, height)
        if not validation_result['valid']:
            return create_response(
                success=False,
                error=validation_result['error'],
                message="Perlin parameter validation failed"
            ), 400
        
        # Generate Perlin noise
        noise_array = generate_perlin_noise(
            width=width,
            height=height,
            scale=scale,
            octaves=octaves,
            persistence=persistence,
            lacunarity=lacunarity,
            seed=seed
        )
        
        # Normalize output
        normalized_array = normalize_array(noise_array)
        
        # Convert to image data
        image_data = array_to_image(normalized_array)
        
        generation_time = time.time() - start_time
        
        return create_response(
            success=True,
            data={
                "noise_type": "perlin",
                "dimensions": {"width": width, "height": height},
                "image_data": image_data,
                "statistics": {
                    "min_value": float(np.min(normalized_array)),
                    "max_value": float(np.max(normalized_array)),
                    "mean_value": float(np.mean(normalized_array)),
                    "std_value": float(np.std(normalized_array))
                }
            },
            message="Perlin noise generated successfully",
            generation_time=generation_time,
            parameters_used=parameters
        )
        
    except Exception as e:
        return create_response(
            success=False,
            error=str(e),
            message="Failed to generate Perlin noise"
        ), 500

def generate_simplex_endpoint():
    """Simplex noise specific endpoint - POST /api/noise/simplex"""
    try:
        start_time = time.time()
        data = request.get_json()
        
        if not data:
            return create_response(
                success=False,
                error="No JSON data provided",
                message="Request must contain JSON data with Simplex parameters"
            ), 400
        
        # Extract Simplex-specific parameters with defaults from doc2_structure.md
        width = data.get('width', 512)
        height = data.get('height', 512)
        scale = data.get('scale', 0.02)
        octaves = data.get('octaves', 5)
        persistence = data.get('persistence', 0.4)
        lacunarity = data.get('lacunarity', 3.0)
        seed = data.get('seed', None)
        
        parameters = {
            'scale': scale,
            'octaves': octaves,
            'persistence': persistence,
            'lacunarity': lacunarity,
            'seed': seed
        }
        
        validation_result = validate_noise_parameters('simplex', parameters, width, height)
        if not validation_result['valid']:
            return create_response(
                success=False,
                error=validation_result['error'],
                message="Simplex parameter validation failed"
            ), 400
        
        # Generate Simplex noise
        noise_array = generate_simplex_noise(
            width=width,
            height=height,
            scale=scale,
            octaves=octaves,
            persistence=persistence,
            lacunarity=lacunarity,
            seed=seed
        )
        
        # Normalize output
        normalized_array = normalize_array(noise_array)
        
        # Convert to image data
        image_data = array_to_image(normalized_array)
        
        generation_time = time.time() - start_time
        
        return create_response(
            success=True,
            data={
                "noise_type": "simplex",
                "dimensions": {"width": width, "height": height},
                "image_data": image_data,
                "statistics": {
                    "min_value": float(np.min(normalized_array)),
                    "max_value": float(np.max(normalized_array)),
                    "mean_value": float(np.mean(normalized_array)),
                    "std_value": float(np.std(normalized_array))
                }
            },
            message="Simplex noise generated successfully",
            generation_time=generation_time,
            parameters_used=parameters
        )
        
    except Exception as e:
        return create_response(
            success=False,
            error=str(e),
            message="Failed to generate Simplex noise"
        ), 500

def generate_worley_endpoint():
    """Worley noise specific endpoint - POST /api/noise/worley"""
    try:
        start_time = time.time()
        data = request.get_json()
        
        if not data:
            return create_response(
                success=False,
                error="No JSON data provided",
                message="Request must contain JSON data with Worley parameters"
            ), 400
        
        # Extract Worley-specific parameters with defaults from doc2_structure.md
        width = data.get('width', 512)
        height = data.get('height', 512)
        frequency = data.get('frequency', 0.1)
        distance_function = data.get('distance_function', 'euclidean')
        cell_type = data.get('cell_type', 'F1')
        seed = data.get('seed', None)
        
        parameters = {
            'frequency': frequency,
            'distance_function': distance_function,
            'cell_type': cell_type,
            'seed': seed
        }
        
        validation_result = validate_noise_parameters('worley', parameters, width, height)
        if not validation_result['valid']:
            return create_response(
                success=False,
                error=validation_result['error'],
                message="Worley parameter validation failed"
            ), 400
        
        # Generate Worley noise
        noise_array = generate_worley_noise(
            width=width,
            height=height,
            frequency=frequency,
            distance_function=distance_function,
            cell_type=cell_type,
            seed=seed
        )
        
        # Normalize output
        normalized_array = normalize_array(noise_array)
        
        # Convert to image data
        image_data = array_to_image(normalized_array)
        
        generation_time = time.time() - start_time
        
        return create_response(
            success=True,
            data={
                "noise_type": "worley",
                "dimensions": {"width": width, "height": height},
                "image_data": image_data,
                "statistics": {
                    "min_value": float(np.min(normalized_array)),
                    "max_value": float(np.max(normalized_array)),
                    "mean_value": float(np.mean(normalized_array)),
                    "std_value": float(np.std(normalized_array))
                }
            },
            message="Worley noise generated successfully",
            generation_time=generation_time,
            parameters_used=parameters
        )
        
    except Exception as e:
        return create_response(
            success=False,
            error=str(e),
            message="Failed to generate Worley noise"
        ), 500