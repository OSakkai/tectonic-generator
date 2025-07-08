#!/usr/bin/env python3
"""
Simplex noise implementation following doc2_structure.md specifications
Scale range: 0.005-0.05
Octaves range: 2-8
Persistence range: 0.2-0.7
Lacunarity range: 2.0-4.0
"""

import numpy as np
from opensimplex import OpenSimplex
import random

def generate_simplex_noise(width, height, scale=0.02, octaves=5, persistence=0.4, lacunarity=3.0, seed=None):
    """
    Generate Simplex noise array following doc2_structure.md specifications
    
    Args:
        width (int): Width of the output array
        height (int): Height of the output array
        scale (float): Detail level (0.005-0.05)
        octaves (int): Complexity layers (2-8)
        persistence (float): Amplitude falloff (0.2-0.7)
        lacunarity (float): Frequency multiplier (2.0-4.0)
        seed (int, optional): Random seed for reproducibility
    
    Returns:
        numpy.ndarray: 2D array of noise values
    """
    
    # Set seed for reproducibility
    if seed is not None:
        random.seed(seed)
        np.random.seed(seed)
    else:
        seed = random.randint(0, 999999)
    
    # Validate parameters against doc2_structure.md constraints
    scale = max(0.005, min(0.05, scale))
    octaves = max(2, min(8, int(octaves)))
    persistence = max(0.2, min(0.7, persistence))
    lacunarity = max(2.0, min(4.0, lacunarity))
    
    # Initialize OpenSimplex generator
    simplex = OpenSimplex(seed=seed)
    
    # Initialize output array
    noise_array = np.zeros((height, width))
    
    # Generate random offset for this instance
    offset_x = random.randint(0, 100000) if seed is not None else 0
    offset_y = random.randint(0, 100000) if seed is not None else 0
    
    # Generate noise with multiple octaves
    max_value = 0  # Used for normalizing result to [-1, 1]
    amplitude = 1
    frequency = scale
    
    for octave in range(octaves):
        for y in range(height):
            for x in range(width):
                noise_value = simplex.noise2d(
                    (x + offset_x) * frequency,
                    (y + offset_y) * frequency
                )
                noise_array[y][x] += noise_value * amplitude
        
        max_value += amplitude
        amplitude *= persistence
        frequency *= lacunarity
    
    # Normalize to [-1, 1] range then shift to [0, 1]
    if max_value > 0:
        noise_array = noise_array / max_value
    
    return noise_array

def generate_simplex_heightmap(width, height, scale=0.02, octaves=5, persistence=0.4, lacunarity=3.0, seed=None, normalize=True):
    """
    Generate Simplex noise heightmap optimized for terrain generation
    
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
    
    heightmap = generate_simplex_noise(width, height, scale, octaves, persistence, lacunarity, seed)
    
    if normalize:
        # Normalize to [0, 1] range
        min_val = np.min(heightmap)
        max_val = np.max(heightmap)
        if max_val - min_val > 0:
            heightmap = (heightmap - min_val) / (max_val - min_val)
        else:
            heightmap = np.zeros_like(heightmap)
    
    return heightmap

def generate_simplex_ridged(width, height, scale=0.03, octaves=6, persistence=0.5, lacunarity=2.5, seed=None):
    """
    Generate ridged Simplex noise for mountain ridges and valleys
    Creates sharp peaks and defined valleys characteristic of tectonic activity
    
    Args:
        width (int): Width of the output
        height (int): Height of the output
        scale (float): Ridge scale
        octaves (int): Detail layers
        persistence (float): Feature persistence
        lacunarity (float): Detail frequency
        seed (int, optional): Random seed
    
    Returns:
        numpy.ndarray: Ridged noise pattern
    """
    
    # Generate base simplex noise
    noise = generate_simplex_noise(width, height, scale, octaves, persistence, lacunarity, seed)
    
    # Apply ridging transformation
    # Take absolute value and invert to create ridges
    ridged = 1.0 - np.abs(noise)
    
    # Square the result to sharpen ridges
    ridged = ridged ** 2
    
    return ridged

def generate_simplex_turbulence(width, height, scale=0.025, octaves=7, persistence=0.6, lacunarity=3.5, seed=None):
    """
    Generate turbulent Simplex noise for chaotic geological patterns
    Useful for volcanic regions and fault lines
    
    Args:
        width (int): Width of the output
        height (int): Height of the output
        scale (float): Turbulence scale
        octaves (int): Detail layers (more = more chaotic)
        persistence (float): Chaos persistence
        lacunarity (float): Detail frequency
        seed (int, optional): Random seed
    
    Returns:
        numpy.ndarray: Turbulent noise pattern
    """
    
    # Generate two perpendicular noise patterns
    noise_x = generate_simplex_noise(width, height, scale, octaves, persistence, lacunarity, seed)
    noise_y = generate_simplex_noise(width, height, scale, octaves, persistence, lacunarity, 
                                   seed + 1000 if seed is not None else None)
    
    # Create turbulence by using one noise to distort the other
    turbulent = np.zeros((height, width))
    
    for y in range(height):
        for x in range(width):
            # Use noise_x and noise_y to create displacement
            displacement_x = int(noise_x[y][x] * 10)  # Scale displacement
            displacement_y = int(noise_y[y][x] * 10)
            
            # Sample from displaced coordinates
            sample_x = max(0, min(width - 1, x + displacement_x))
            sample_y = max(0, min(height - 1, y + displacement_y))
            
            turbulent[y][x] = noise_x[sample_y][sample_x]
    
    return turbulent

def generate_simplex_continental_shelf(width, height, scale=0.01, octaves=4, persistence=0.3, lacunarity=2.2, seed=None):
    """
    Generate Simplex noise optimized for continental shelf patterns
    Creates smooth transitions between continental and oceanic crust
    
    Args:
        width (int): Width of the output
        height (int): Height of the output
        scale (float): Continental scale (lower = broader features)
        octaves (int): Detail layers (fewer = smoother transitions)
        persistence (float): Feature persistence (lower = smoother)
        lacunarity (float): Detail frequency
        seed (int, optional): Random seed
    
    Returns:
        numpy.ndarray: Continental shelf pattern
    """
    
    # Use parameters optimized for broad, smooth continental features
    shelf_scale = max(0.005, min(0.03, scale))
    shelf_octaves = max(2, min(5, octaves))
    shelf_persistence = max(0.2, min(0.5, persistence))
    
    return generate_simplex_heightmap(
        width=width,
        height=height,
        scale=shelf_scale,
        octaves=shelf_octaves,
        persistence=shelf_persistence,
        lacunarity=lacunarity,
        seed=seed,
        normalize=True
    )

def validate_simplex_parameters(scale, octaves, persistence, lacunarity):
    """
    Validate Simplex parameters against doc2_structure.md specifications
    
    Args:
        scale (float): Detail level
        octaves (int): Complexity layers
        persistence (float): Amplitude falloff
        lacunarity (float): Frequency multiplier
    
    Returns:
        dict: Validation result with 'valid' boolean and 'errors' list
    """
    
    errors = []
    
    # Validate scale (0.005-0.05)
    if not (0.005 <= scale <= 0.05):
        errors.append(f"Scale {scale} outside valid range [0.005, 0.05]")
    
    # Validate octaves (2-8)
    if not (2 <= octaves <= 8):
        errors.append(f"Octaves {octaves} outside valid range [2, 8]")
    
    # Validate persistence (0.2-0.7)
    if not (0.2 <= persistence <= 0.7):
        errors.append(f"Persistence {persistence} outside valid range [0.2, 0.7]")
    
    # Validate lacunarity (2.0-4.0)
    if not (2.0 <= lacunarity <= 4.0):
        errors.append(f"Lacunarity {lacunarity} outside valid range [2.0, 4.0]")
    
    return {
        'valid': len(errors) == 0,
        'errors': errors
    }

# Test function for development
def test_simplex_generation():
    """Test function to verify Simplex noise generation"""
    
    print("Testing Simplex noise generation...")
    
    # Test basic generation
    noise = generate_simplex_noise(256, 256, scale=0.02, octaves=5, seed=12345)
    print(f"Basic noise - Shape: {noise.shape}, Min: {np.min(noise):.3f}, Max: {np.max(noise):.3f}")
    
    # Test ridged generation
    ridged = generate_simplex_ridged(256, 256, seed=12345)
    print(f"Ridged - Shape: {ridged.shape}, Min: {np.min(ridged):.3f}, Max: {np.max(ridged):.3f}")
    
    # Test turbulence generation
    turbulent = generate_simplex_turbulence(256, 256, seed=12345)
    print(f"Turbulent - Shape: {turbulent.shape}, Min: {np.min(turbulent):.3f}, Max: {np.max(turbulent):.3f}")
    
    # Test continental shelf generation
    shelf = generate_simplex_continental_shelf(256, 256, seed=12345)
    print(f"Continental shelf - Shape: {shelf.shape}, Min: {np.min(shelf):.3f}, Max: {np.max(shelf):.3f}")
    
    # Test parameter validation
    validation = validate_simplex_parameters(0.02, 5, 0.4, 3.0)
    print(f"Parameter validation: {validation}")
    
    print("Simplex noise tests completed successfully!")

if __name__ == "__main__":
    test_simplex_generation()