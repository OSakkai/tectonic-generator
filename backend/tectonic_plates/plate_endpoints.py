#!/usr/bin/env python3
"""
API endpoints for tectonic plate generation
"""

from flask import request, jsonify
import time
import traceback
from .plate_generator import PlateGenerator

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

def generate_plates_endpoint():
    """Generate tectonic plates - POST /api/plates/generate"""
    try:
        start_time = time.time()
        data = request.get_json()
        
        if not data:
            return create_response(
                success=False,
                error="No JSON data provided",
                message="Request must contain JSON data with plate parameters"
            ), 400
        
        # Extract and validate parameters
        required_params = ['noise_data', 'grid_size']
        for param in required_params:
            if param not in data:
                return create_response(
                    success=False,
                    error=f"Missing required parameter: {param}",
                    message="Check API documentation for required parameters"
                ), 400
        
        # Extract parameters with defaults
        noise_data = data.get('noise_data')
        grid_size = data.get('grid_size', {})
        grid_width = grid_size.get('width', 100)
        grid_height = grid_size.get('height', 100)
        sensitivity = data.get('plate_sensitivity', 0.15)
        min_plates = data.get('min_plates', 4)
        max_plates = data.get('max_plates', 20)
        complexity = data.get('complexity', 'medium')
        wrap_edges = data.get('wrap_edges', False)
        seed = data.get('seed', None)
        
        # Validate parameters
        validation_errors = []
        
        # Grid size validation
        if grid_width < 20 or grid_width > 500:
            validation_errors.append(f"Grid width {grid_width} outside valid range [20, 500]")
        if grid_height < 20 or grid_height > 500:
            validation_errors.append(f"Grid height {grid_height} outside valid range [20, 500]")
        
        # Ensure minimum grid size for requested plates
        min_grid_size = int((min_plates * 100) ** 0.5)
        if grid_width < min_grid_size or grid_height < min_grid_size:
            validation_errors.append(f"Grid too small for {min_plates} plates. Minimum size: {min_grid_size}x{min_grid_size}")
        
        # Sensitivity validation
        if sensitivity < 0.05 or sensitivity > 0.40:
            validation_errors.append(f"Sensitivity {sensitivity} outside valid range [0.05, 0.40]")
        
        # Plate count validation
        if min_plates < 2:
            validation_errors.append("Minimum plates must be at least 2")
        if max_plates > 30:
            validation_errors.append("Maximum plates cannot exceed 30")
        if min_plates > max_plates:
            validation_errors.append("Minimum plates cannot exceed maximum plates")
        
        # Complexity validation
        if complexity not in ['low', 'medium', 'high']:
            validation_errors.append(f"Invalid complexity '{complexity}'. Must be: low, medium, or high")
        
        if validation_errors:
            return create_response(
                success=False,
                error="; ".join(validation_errors),
                message="Parameter validation failed"
            ), 400
        
        # Generate plates
        generator = PlateGenerator()
        result = generator.generate_plates(
            noise_data=noise_data,
            grid_width=grid_width,
            grid_height=grid_height,
            sensitivity=sensitivity,
            min_plates=min_plates,
            max_plates=max_plates,
            complexity=complexity,
            wrap_edges=wrap_edges,
            seed=seed
        )
        
        generation_time = time.time() - start_time
        
        # Add generation parameters to result
        parameters_used = {
            "grid_size": {"width": grid_width, "height": grid_height},
            "sensitivity": sensitivity,
            "plate_range": {"min": min_plates, "max": max_plates},
            "complexity": complexity,
            "wrap_edges": wrap_edges,
            "seed": seed
        }
        
        return create_response(
            success=True,
            data=result,
            message=f"Generated {result['metadata']['plate_count']} tectonic plates successfully",
            generation_time=generation_time,
            parameters_used=parameters_used
        )
        
    except Exception as e:
        traceback.print_exc()
        return create_response(
            success=False,
            error=str(e),
            message="Failed to generate tectonic plates"
        ), 500

def get_plate_parameters():
    """Get valid parameter ranges - GET /api/plates/parameters"""
    return create_response(
        success=True,
        data={
            "grid_size": {
                "width": {"min": 20, "max": 500, "default": 100},
                "height": {"min": 20, "max": 500, "default": 100}
            },
            "plate_sensitivity": {
                "min": 0.05,
                "max": 0.40,
                "default": 0.15,
                "description": "Controls plate size. Lower = more plates, Higher = fewer plates"
            },
            "plate_count": {
                "min_plates": {"min": 2, "max": 30, "default": 4},
                "max_plates": {"min": 2, "max": 30, "default": 20},
                "earth_average": 12
            },
            "complexity": {
                "options": ["low", "medium", "high"],
                "default": "medium",
                "descriptions": {
                    "low": "Geometric shapes with smooth borders",
                    "medium": "Natural shapes with moderate irregularity",
                    "high": "Highly irregular shapes with fractal borders"
                }
            },
            "wrap_edges": {
                "type": "boolean",
                "default": False,
                "description": "Connect opposite edges for spherical topology"
            },
            "performance": {
                "draft_mode_threshold": 300,
                "max_hexagons_normal": 90000,
                "max_hexagons_draft": 250000
            }
        },
        message="Tectonic plate generation parameter specifications"
    )

def get_plate_presets():
    """Get preset configurations - GET /api/plates/presets"""
    return create_response(
        success=True,
        data={
            "earth_like": {
                "grid_size": {"width": 150, "height": 150},
                "plate_sensitivity": 0.15,
                "min_plates": 10,
                "max_plates": 15,
                "complexity": "medium",
                "wrap_edges": True,
                "description": "Earth-like plate distribution"
            },
            "pangaea": {
                "grid_size": {"width": 200, "height": 200},
                "plate_sensitivity": 0.30,
                "min_plates": 4,
                "max_plates": 8,
                "complexity": "low",
                "wrap_edges": True,
                "description": "Supercontinent configuration"
            },
            "archipelago": {
                "grid_size": {"width": 250, "height": 250},
                "plate_sensitivity": 0.08,
                "min_plates": 20,
                "max_plates": 30,
                "complexity": "high",
                "wrap_edges": False,
                "description": "Many small plates"
            },
            "simple": {
                "grid_size": {"width": 100, "height": 100},
                "plate_sensitivity": 0.25,
                "min_plates": 5,
                "max_plates": 10,
                "complexity": "low",
                "wrap_edges": False,
                "description": "Simple plate layout for testing"
            }
        },
        message="Preset configurations for common plate patterns"
    )