#!/usr/bin/env python3
"""
Parameter validation utilities following doc2_structure.md specifications
"""

def validate_noise_parameters(noise_type, parameters, width, height):
    """
    Validate noise generation parameters against doc2_structure.md constraints
    
    Args:
        noise_type (str): Type of noise ('perlin', 'simplex', 'worley')
        parameters (dict): Parameters for the specific noise type
        width (int): Output width
        height (int): Output height
    
    Returns:
        dict: Validation result with 'valid' boolean and 'error' string
    """
    
    errors = []
    
    # Validate dimensions against doc2_structure.md constraints
    MAX_RESOLUTION = 4096
    if width > MAX_RESOLUTION or height > MAX_RESOLUTION:
        errors.append(f"Resolution {width}x{height} exceeds maximum {MAX_RESOLUTION}x{MAX_RESOLUTION}")
    
    if width <= 0 or height <= 0:
        errors.append(f"Invalid dimensions: {width}x{height}")
    
    # Validate noise-specific parameters
    if noise_type == 'perlin':
        result = validate_perlin_parameters(parameters)
        if not result['valid']:
            errors.extend(result['errors'])
    
    elif noise_type == 'simplex':
        result = validate_simplex_parameters(parameters)
        if not result['valid']:
            errors.extend(result['errors'])
    
    elif noise_type == 'worley':
        result = validate_worley_parameters(parameters)
        if not result['valid']:
            errors.extend(result['errors'])
    
    else:
        errors.append(f"Unsupported noise type: {noise_type}")
    
    return {
        'valid': len(errors) == 0,
        'error': '; '.join(errors) if errors else None,
        'errors': errors
    }

def validate_perlin_parameters(parameters):
    """
    Validate Perlin noise parameters against doc2_structure.md specifications
    
    Args:
        parameters (dict): Perlin parameters
    
    Returns:
        dict: Validation result
    """
    
    errors = []
    
    # Extract parameters with defaults
    scale = parameters.get('scale', 0.05)
    octaves = parameters.get('octaves', 4)
    persistence = parameters.get('persistence', 0.5)
    lacunarity = parameters.get('lacunarity', 2.0)
    seed = parameters.get('seed', None)
    
    # Validate scale (0.001-0.1)
    if not isinstance(scale, (int, float)) or not (0.001 <= scale <= 0.1):
        errors.append(f"Perlin scale {scale} must be between 0.001 and 0.1")
    
    # Validate octaves (1-6)
    if not isinstance(octaves, int) or not (1 <= octaves <= 6):
        errors.append(f"Perlin octaves {octaves} must be integer between 1 and 6")
    
    # Validate persistence (0.1-0.8)
    if not isinstance(persistence, (int, float)) or not (0.1 <= persistence <= 0.8):
        errors.append(f"Perlin persistence {persistence} must be between 0.1 and 0.8")
    
    # Validate lacunarity (1.5-3.0)
    if not isinstance(lacunarity, (int, float)) or not (1.5 <= lacunarity <= 3.0):
        errors.append(f"Perlin lacunarity {lacunarity} must be between 1.5 and 3.0")
    
    # Validate seed (optional)
    if seed is not None and (not isinstance(seed, int) or not (0 <= seed <= 999999)):
        errors.append(f"Perlin seed {seed} must be integer between 0 and 999999 or None")
    
    return {
        'valid': len(errors) == 0,
        'errors': errors
    }

def validate_simplex_parameters(parameters):
    """
    Validate Simplex noise parameters against doc2_structure.md specifications
    
    Args:
        parameters (dict): Simplex parameters
    
    Returns:
        dict: Validation result
    """
    
    errors = []
    
    # Extract parameters with defaults
    scale = parameters.get('scale', 0.02)
    octaves = parameters.get('octaves', 5)
    persistence = parameters.get('persistence', 0.4)
    lacunarity = parameters.get('lacunarity', 3.0)
    seed = parameters.get('seed', None)
    
    # Validate scale (0.005-0.05)
    if not isinstance(scale, (int, float)) or not (0.005 <= scale <= 0.05):
        errors.append(f"Simplex scale {scale} must be between 0.005 and 0.05")
    
    # Validate octaves (2-8)
    if not isinstance(octaves, int) or not (2 <= octaves <= 8):
        errors.append(f"Simplex octaves {octaves} must be integer between 2 and 8")
    
    # Validate persistence (0.2-0.7)
    if not isinstance(persistence, (int, float)) or not (0.2 <= persistence <= 0.7):
        errors.append(f"Simplex persistence {persistence} must be between 0.2 and 0.7")
    
    # Validate lacunarity (2.0-4.0)
    if not isinstance(lacunarity, (int, float)) or not (2.0 <= lacunarity <= 4.0):
        errors.append(f"Simplex lacunarity {lacunarity} must be between 2.0 and 4.0")
    
    # Validate seed (optional)
    if seed is not None and (not isinstance(seed, int) or not (0 <= seed <= 999999)):
        errors.append(f"Simplex seed {seed} must be integer between 0 and 999999 or None")
    
    return {
        'valid': len(errors) == 0,
        'errors': errors
    }

def validate_worley_parameters(parameters):
    """
    Validate Worley noise parameters against doc2_structure.md specifications
    
    Args:
        parameters (dict): Worley parameters
    
    Returns:
        dict: Validation result
    """
    
    errors = []
    
    # Extract parameters with defaults
    frequency = parameters.get('frequency', 0.1)
    distance_function = parameters.get('distance_function', 'euclidean')
    cell_type = parameters.get('cell_type', 'F1')
    seed = parameters.get('seed', None)
    
    # Validate frequency (0.05-0.5)
    if not isinstance(frequency, (int, float)) or not (0.05 <= frequency <= 0.5):
        errors.append(f"Worley frequency {frequency} must be between 0.05 and 0.5")
    
    # Validate distance function
    valid_distances = ['euclidean', 'manhattan', 'chebyshev']
    if not isinstance(distance_function, str) or distance_function not in valid_distances:
        errors.append(f"Worley distance_function '{distance_function}' must be one of {valid_distances}")
    
    # Validate cell type
    valid_cell_types = ['F1', 'F2', 'F1-F2']
    if not isinstance(cell_type, str) or cell_type not in valid_cell_types:
        errors.append(f"Worley cell_type '{cell_type}' must be one of {valid_cell_types}")
    
    # Validate seed (optional)
    if seed is not None and (not isinstance(seed, int) or not (0 <= seed <= 999999)):
        errors.append(f"Worley seed {seed} must be integer between 0 and 999999 or None")
    
    return {
        'valid': len(errors) == 0,
        'errors': errors
    }

def validate_generation_limits(width, height, generation_time=None):
    """
    Validate generation limits against doc2_structure.md constraints
    
    Args:
        width (int): Output width
        height (int): Output height
        generation_time (float, optional): Time taken for generation
    
    Returns:
        dict: Validation result
    """
    
    errors = []
    warnings = []
    
    # Check maximum resolution
    MAX_RESOLUTION = 4096
    if width > MAX_RESOLUTION or height > MAX_RESOLUTION:
        errors.append(f"Resolution {width}x{height} exceeds maximum {MAX_RESOLUTION}x{MAX_RESOLUTION}")
    
    # Check generation time limit
    MAX_GENERATION_TIME = 30  # seconds
    if generation_time is not None and generation_time > MAX_GENERATION_TIME:
        errors.append(f"Generation time {generation_time:.2f}s exceeds maximum {MAX_GENERATION_TIME}s")
    
    # Performance warnings
    PERFORMANCE_WARNING_RESOLUTION = 2048
    if width > PERFORMANCE_WARNING_RESOLUTION or height > PERFORMANCE_WARNING_RESOLUTION:
        warnings.append(f"Large resolution {width}x{height} may impact performance")
    
    PERFORMANCE_WARNING_TIME = 10  # seconds
    if generation_time is not None and generation_time > PERFORMANCE_WARNING_TIME:
        warnings.append(f"Generation time {generation_time:.2f}s is approaching limits")
    
    return {
        'valid': len(errors) == 0,
        'errors': errors,
        'warnings': warnings
    }

def sanitize_parameters(noise_type, parameters):
    """
    Sanitize and clamp parameters to valid ranges
    
    Args:
        noise_type (str): Type of noise
        parameters (dict): Input parameters
    
    Returns:
        dict: Sanitized parameters
    """
    
    sanitized = parameters.copy()
    
    if noise_type == 'perlin':
        sanitized['scale'] = max(0.001, min(0.1, float(sanitized.get('scale', 0.05))))
        sanitized['octaves'] = max(1, min(6, int(sanitized.get('octaves', 4))))
        sanitized['persistence'] = max(0.1, min(0.8, float(sanitized.get('persistence', 0.5))))
        sanitized['lacunarity'] = max(1.5, min(3.0, float(sanitized.get('lacunarity', 2.0))))
        
    elif noise_type == 'simplex':
        sanitized['scale'] = max(0.005, min(0.05, float(sanitized.get('scale', 0.02))))
        sanitized['octaves'] = max(2, min(8, int(sanitized.get('octaves', 5))))
        sanitized['persistence'] = max(0.2, min(0.7, float(sanitized.get('persistence', 0.4))))
        sanitized['lacunarity'] = max(2.0, min(4.0, float(sanitized.get('lacunarity', 3.0))))
        
    elif noise_type == 'worley':
        sanitized['frequency'] = max(0.05, min(0.5, float(sanitized.get('frequency', 0.1))))
        
        distance_func = sanitized.get('distance_function', 'euclidean')
        if distance_func not in ['euclidean', 'manhattan', 'chebyshev']:
            sanitized['distance_function'] = 'euclidean'
        
        cell_type = sanitized.get('cell_type', 'F1')
        if cell_type not in ['F1', 'F2', 'F1-F2']:
            sanitized['cell_type'] = 'F1'
    
    # Handle seed
    seed = sanitized.get('seed', None)
    if seed is not None:
        try:
            sanitized['seed'] = max(0, min(999999, int(seed)))
        except (ValueError, TypeError):
            sanitized['seed'] = None
    
    return sanitized