#!/usr/bin/env python3
"""
Perlin noise implementation following doc2_structure.md specifications
Scale range: 0.001-0.1
Octaves range: 1-6
Persistence range: 0.1-0.8
Lacunarity range: 1.5-3.0
"""

import numpy as np
from noise import pnoise2
import random

def generate_perlin_noise(width, height, scale=0.05, octaves=4, persistence=0.5, lacunarity=2.0, seed=None):
    """
    Generate Perlin noise array following doc2_structure.md specifications
    
    Args:
        width (int): Width of the output array
        height (int): Height of the output array
        scale (float): Detail level (0.001-0.1)
        octaves (int): Complexity layers (1-6)
        persistence (float): Amplitude falloff (0.1-0.8)
        lacunarity (float): Frequency multiplier (1.5-3.0)
        seed (int, optional): Random seed for reproducibility
    
    Returns:
        numpy.ndarray: 2D array of noise values
    """
    
    # Set seed for reproducibility
    if seed is not None:
        random.seed(seed)
        np.random.seed(seed)
    
    # Validate parameters against doc2_structure.md constraints
    scale = max(0.001, min(0.1, scale))
    octaves = max(1, min(6, int(octaves)))
    persistence = max(0.1, min(0.8, persistence))
    lacunarity = max(1.5, min(3.0, lacunarity))
    
    # Initialize output array
    noise_array = np.zeros((height, width))
    
    # Generate random offset for this instance
    offset_x = random.randint(0, 100000) if seed is not None else 0
    offset_y = random.randint(0, 100000) if seed is not None else 0
    
    # Generate Perlin noise
    for y in range(height):
        for x in range(width):
            # Calculate noise value at this coordinate
            noise_value = pnoise2(
                (x + offset_x) * scale,
                (y + offset_y) * scale,
                octaves=octaves,
                persistence=persistence,
                lacunarity=lacunarity,
                repeatx=width,
                repeaty=height,
                base=seed if seed is not None else 0
            )
            
            noise_array[y][x] = noise_value
    
    return noise_array

def generate_perlin_heightmap(width, height, scale=0.05, octaves=4, persistence=0.5, lacunarity=2.0, seed=None, normalize=True):
    """
    Generate Perlin noise heightmap optimized for terrain generation
    
    Args:
        width (int): Width of the heightmap
        height (int): Height of the heightmap
        scale (float): Detail level
        octaves (int): Number of noise layers
        persistence (float): Amplitude falloff
        lacunarity (float): Frequency multiplier
        seed (int, optional): Random seed
        normalize (bool): Whether to normalize output to [0,1]
    
    Returns:
        numpy.ndarray: 2D heightmap array
    """
    
    heightmap = generate_perlin_noise(width, height, scale, octaves, persistence, lacunarity, seed)
    
    if normalize:
        # Normalize to [0, 1] range
        min_val = np.min(heightmap)
        max_val = np.max(heightmap)
        if max_val - min_val > 0:
            heightmap = (heightmap - min_val) / (max_val - min_val)
        else:
            heightmap = np.zeros_like(heightmap)
    
    return heightmap

def generate_perlin_continental(width, height, scale=0.02, octaves=5, persistence=0.6, lacunarity=2.5, seed=None):
    """
    Generate Perlin noise optimized for continental landmass patterns
    Uses parameters optimized for large-scale geological features
    
    Args:
        width (int): Width of the output
        height (int): Height of the output
        scale (float): Continental scale (lower = larger features)
        octaves (int): Detail layers
        persistence (float): Feature persistence
        lacunarity (float): Detail frequency
        seed (int, optional): Random seed
    
    Returns:
        numpy.ndarray: Continental noise pattern
    """
    
    # Use parameters optimized for continental patterns
    continental_scale = max(0.001, min(0.05, scale))  # Larger features
    continental_octaves = max(2, min(6, octaves))
    continental_persistence = max(0.3, min(0.8, persistence))
    
    return generate_perlin_heightmap(
        width=width,
        height=height,
        scale=continental_scale,
        octaves=continental_octaves,
        persistence=continental_persistence,
        lacunarity=lacunarity,
        seed=seed,
        normalize=True
    )

def generate_perlin_oceanic(width, height, scale=0.08, octaves=3, persistence=0.3, lacunarity=2.0, seed=None):
    """
    Generate Perlin noise optimized for oceanic floor patterns
    Uses parameters optimized for underwater terrain
    
    Args:
        width (int): Width of the output
        height (int): Height of the output
        scale (float): Oceanic scale (higher = more detail)
        octaves (int): Detail layers (fewer for smoother ocean floor)
        persistence (float): Feature persistence (lower for smoother)
        lacunarity (float): Detail frequency
        seed (int, optional): Random seed
    
    Returns:
        numpy.ndarray: Oceanic noise pattern
    """
    
    # Use parameters optimized for oceanic patterns
    oceanic_scale = max(0.02, min(0.1, scale))  # More detailed features
    oceanic_octaves = max(1, min(4, octaves))   # Fewer octaves for smoother ocean
    oceanic_persistence = max(0.1, min(0.5, persistence))  # Lower persistence
    
    return generate_perlin_heightmap(
        width=width,
        height=height,
        scale=oceanic_scale,
        octaves=oceanic_octaves,
        persistence=oceanic_persistence,
        lacunarity=lacunarity,
        seed=seed,
        normalize=True
    )

def validate_perlin_parameters(scale, octaves, persistence, lacunarity):
    """
    Validate Perlin parameters against doc2_structure.md specifications
    
    Args:
        scale (float): Detail level
        octaves (int): Complexity layers
        persistence (float): Amplitude falloff
        lacunarity (float): Frequency multiplier
    
    Returns:
        dict: Validation result with 'valid' boolean and 'errors' list
    """
    
    errors = []
    
    # Validate scale (0.001-0.1)
    if not (0.001 <= scale <= 0.1):
        errors.append(f"Scale {scale} outside valid range [0.001, 0.1]")
    
    # Validate octaves (1-6)
    if not (1 <= octaves <= 6):
        errors.append(f"Octaves {octaves} outside valid range [1, 6]")
    
    # Validate persistence (0.1-0.8)
    if not (0.1 <= persistence <= 0.8):
        errors.append(f"Persistence {persistence} outside valid range [0.1, 0.8]")
    
    # Validate lacunarity (1.5-3.0)
    if not (1.5 <= lacunarity <= 3.0):
        errors.append(f"Lacunarity {lacunarity} outside valid range [1.5, 3.0]")
    
    return {
        'valid': len(errors) == 0,
        'errors': errors
    }

# Test function for development
def test_perlin_generation():
    """Test function to verify Perlin noise generation"""
    
    print("Testing Perlin noise generation...")
    
    # Test basic generation
    noise = generate_perlin_noise(256, 256, scale=0.05, octaves=4, seed=12345)
    print(f"Basic noise - Shape: {noise.shape}, Min: {np.min(noise):.3f}, Max: {np.max(noise):.3f}")
    
    # Test continental generation
    continental = generate_perlin_continental(256, 256, seed=12345)
    print(f"Continental - Shape: {continental.shape}, Min: {np.min(continental):.3f}, Max: {np.max(continental):.3f}")
    
    # Test oceanic generation
    oceanic = generate_perlin_oceanic(256, 256, seed=12345)
    print(f"Oceanic - Shape: {oceanic.shape}, Min: {np.min(oceanic):.3f}, Max: {np.max(oceanic):.3f}")
    
    # Test parameter validation
    validation = validate_perlin_parameters(0.05, 4, 0.5, 2.0)
    print(f"Parameter validation: {validation}")
    
    print("Perlin noise tests completed successfully!")

if __name__ == "__main__":
    test_perlin_generation()