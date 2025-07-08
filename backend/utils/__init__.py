#!/usr/bin/env python3
"""
Utility functions module for Tectonic Generator
"""

from .validation import (
    validate_noise_parameters,
    validate_perlin_parameters,
    validate_simplex_parameters,
    validate_worley_parameters,
    validate_generation_limits,
    sanitize_parameters
)

from .image_processing import (
    normalize_array,
    array_to_image,
    apply_terrain_colormap,
    apply_oceanic_colormap,
    apply_continental_colormap,
    apply_plate_boundary_visualization,
    export_array_as_image,
    calculate_image_statistics,
    create_elevation_histogram
)

__all__ = [
    # Validation utilities
    'validate_noise_parameters',
    'validate_perlin_parameters', 
    'validate_simplex_parameters',
    'validate_worley_parameters',
    'validate_generation_limits',
    'sanitize_parameters',
    
    # Image processing utilities
    'normalize_array',
    'array_to_image',
    'apply_terrain_colormap',
    'apply_oceanic_colormap',
    'apply_continental_colormap',
    'apply_plate_boundary_visualization',
    'export_array_as_image',
    'calculate_image_statistics',
    'create_elevation_histogram'
]