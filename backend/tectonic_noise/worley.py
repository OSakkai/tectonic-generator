#!/usr/bin/env python3
"""
Worley noise implementation following doc2_structure.md specifications
Frequency range: 0.05-0.5
Distance functions: euclidean, manhattan, chebyshev
Cell types: F1, F2, F1-F2
"""

import numpy as np
import random
from scipy.spatial.distance import cdist

def generate_worley_noise(width, height, frequency=0.1, distance_function='euclidean', cell_type='F1', seed=None):
    """
    Generate Worley (Cellular) noise array following doc2_structure.md specifications
    
    Args:
        width (int): Width of the output array
        height (int): Height of the output array
        frequency (float): Cell frequency (0.05-0.5)
        distance_function (str): Distance metric ('euclidean', 'manhattan', 'chebyshev')
        cell_type (str): Cell value type ('F1', 'F2', 'F1-F2')
        seed (int, optional): Random seed for reproducibility
    
    Returns:
        numpy.ndarray: 2D array of noise values
    """
    
    # Set seed for reproducibility
    if seed is not None:
        random.seed(seed)
        np.random.seed(seed)
    
    # Validate parameters against doc2_structure.md constraints
    frequency = max(0.05, min(0.5, frequency))
    
    if distance_function not in ['euclidean', 'manhattan', 'chebyshev']:
        distance_function = 'euclidean'
    
    if cell_type not in ['F1', 'F2', 'F1-F2']:
        cell_type = 'F1'
    
    # Calculate cell size based on frequency
    cell_size = int(1.0 / frequency)
    
    # Generate grid of cells with random points
    grid_width = (width // cell_size) + 2
    grid_height = (height // cell_size) + 2
    
    # Generate random points in each cell
    points = []
    for gy in range(grid_height):
        for gx in range(grid_width):
            # Add random point within this cell
            px = gx * cell_size + random.uniform(0, cell_size)
            py = gy * cell_size + random.uniform(0, cell_size)
            points.append([px, py])
    
    points = np.array(points)
    
    # Initialize output array
    noise_array = np.zeros((height, width))
    
    # Calculate distances for each pixel
    for y in range(height):
        for x in range(width):
            pixel_point = np.array([[x, y]])
            
            # Calculate distances to all points
            if distance_function == 'euclidean':
                distances = cdist(pixel_point, points, metric='euclidean')[0]
            elif distance_function == 'manhattan':
                distances = cdist(pixel_point, points, metric='cityblock')[0]
            elif distance_function == 'chebyshev':
                distances = cdist(pixel_point, points, metric='chebyshev')[0]
            
            # Sort distances to get F1, F2, etc.
            sorted_distances = np.sort(distances)
            
            # Assign value based on cell_type
            if cell_type == 'F1':
                noise_array[y][x] = sorted_distances[0]
            elif cell_type == 'F2':
                if len(sorted_distances) > 1:
                    noise_array[y][x] = sorted_distances[1]
                else:
                    noise_array[y][x] = sorted_distances[0]
            elif cell_type == 'F1-F2':
                if len(sorted_distances) > 1:
                    noise_array[y][x] = sorted_distances[1] - sorted_distances[0]
                else:
                    noise_array[y][x] = 0
    
    return noise_array

def generate_worley_heightmap(width, height, frequency=0.1, distance_function='euclidean', 
                             cell_type='F1', seed=None, normalize=True):
    """
    Generate Worley noise heightmap optimized for terrain generation
    
    Args:
        width (int): Width of the heightmap
        height (int): Height of the heightmap
        frequency (float): Cell frequency
        distance_function (str): Distance metric
        cell_type (str): Cell value type
        seed (int, optional): Random seed
        normalize (bool): Whether to normalize output to [0,1]
    
    Returns:
        numpy.ndarray: 2D heightmap array
    """
    
    heightmap = generate_worley_noise(width, height, frequency, distance_function, cell_type, seed)
    
    if normalize:
        # Normalize to [0, 1] range
        min_val = np.min(heightmap)
        max_val = np.max(heightmap)
        if max_val - min_val > 0:
            heightmap = (heightmap - min_val) / (max_val - min_val)
        else:
            heightmap = np.zeros_like(heightmap)
    
    return heightmap

def generate_worley_plates(width, height, frequency=0.08, distance_function='euclidean', seed=None):
    """
    Generate Worley noise optimized for tectonic plate boundaries
    Uses F1 distance to create distinct plate regions
    
    Args:
        width (int): Width of the output
        height (int): Height of the output
        frequency (float): Plate frequency (lower = larger plates)
        distance_function (str): Distance metric
        seed (int, optional): Random seed
    
    Returns:
        numpy.ndarray: Plate boundary pattern
    """
    
    # Use F1 for distinct plate regions
    return generate_worley_heightmap(
        width=width,
        height=height,
        frequency=frequency,
        distance_function=distance_function,
        cell_type='F1',
        seed=seed,
        normalize=True
    )

def generate_worley_plate_boundaries(width, height, frequency=0.1, distance_function='euclidean', seed=None):
    """
    Generate Worley noise optimized for plate boundary detection
    Uses F1-F2 difference to highlight boundaries between plates
    
    Args:
        width (int): Width of the output
        height (int): Height of the output
        frequency (float): Boundary detail frequency
        distance_function (str): Distance metric
        seed (int, optional): Random seed
    
    Returns:
        numpy.ndarray: Plate boundary highlighting pattern
    """
    
    # Use F1-F2 for boundary detection
    boundaries = generate_worley_heightmap(
        width=width,
        height=height,
        frequency=frequency,
        distance_function=distance_function,
        cell_type='F1-F2',
        seed=seed,
        normalize=True
    )
    
    # Invert so boundaries are high values
    return 1.0 - boundaries

def generate_worley_volcanic(width, height, frequency=0.2, distance_function='manhattan', seed=None):
    """
    Generate Worley noise optimized for volcanic activity patterns
    Uses higher frequency and Manhattan distance for angular features
    
    Args:
        width (int): Width of the output
        height (int): Height of the output
        frequency (float): Volcanic feature frequency
        distance_function (str): Distance metric (manhattan recommended)
        seed (int, optional): Random seed
    
    Returns:
        numpy.ndarray: Volcanic activity pattern
    """
    
    # Use F2 for secondary volcanic features
    volcanic = generate_worley_heightmap(
        width=width,
        height=height,
        frequency=frequency,
        distance_function=distance_function,
        cell_type='F2',
        seed=seed,
        normalize=True
    )
    
    # Apply power function to sharpen volcanic peaks
    return volcanic ** 2

def generate_worley_fracture_zones(width, height, frequency=0.15, distance_function='chebyshev', seed=None):
    """
    Generate Worley noise optimized for fracture zone patterns
    Uses Chebyshev distance for angular, crystalline-like patterns
    
    Args:
        width (int): Width of the output
        height (int): Height of the output
        frequency (float): Fracture detail frequency
        distance_function (str): Distance metric (chebyshev recommended)
        seed (int, optional): Random seed
    
    Returns:
        numpy.ndarray: Fracture zone pattern
    """
    
    return generate_worley_heightmap(
        width=width,
        height=height,
        frequency=frequency,
        distance_function=distance_function,
        cell_type='F1-F2',
        seed=seed,
        normalize=True
    )

def validate_worley_parameters(frequency, distance_function, cell_type):
    """
    Validate Worley parameters against doc2_structure.md specifications
    
    Args:
        frequency (float): Cell frequency
        distance_function (str): Distance metric
        cell_type (str): Cell value type
    
    Returns:
        dict: Validation result with 'valid' boolean and 'errors' list
    """
    
    errors = []
    
    # Validate frequency (0.05-0.5)
    if not (0.05 <= frequency <= 0.5):
        errors.append(f"Frequency {frequency} outside valid range [0.05, 0.5]")
    
    # Validate distance function
    valid_distances = ['euclidean', 'manhattan', 'chebyshev']
    if distance_function not in valid_distances:
        errors.append(f"Distance function '{distance_function}' not in {valid_distances}")
    
    # Validate cell type
    valid_cell_types = ['F1', 'F2', 'F1-F2']
    if cell_type not in valid_cell_types:
        errors.append(f"Cell type '{cell_type}' not in {valid_cell_types}")
    
    return {
        'valid': len(errors) == 0,
        'errors': errors
    }

# Test function for development
def test_worley_generation():
    """Test function to verify Worley noise generation"""
    
    print("Testing Worley noise generation...")
    
    # Test basic generation
    noise = generate_worley_noise(256, 256, frequency=0.1, seed=12345)
    print(f"Basic noise - Shape: {noise.shape}, Min: {np.min(noise):.3f}, Max: {np.max(noise):.3f}")
    
    # Test plate generation
    plates = generate_worley_plates(256, 256, seed=12345)
    print(f"Plates - Shape: {plates.shape}, Min: {np.min(plates):.3f}, Max: {np.max(plates):.3f}")
    
    # Test boundary generation
    boundaries = generate_worley_plate_boundaries(256, 256, seed=12345)
    print(f"Boundaries - Shape: {boundaries.shape}, Min: {np.min(boundaries):.3f}, Max: {np.max(boundaries):.3f}")
    
    # Test volcanic generation
    volcanic = generate_worley_volcanic(256, 256, seed=12345)
    print(f"Volcanic - Shape: {volcanic.shape}, Min: {np.min(volcanic):.3f}, Max: {np.max(volcanic):.3f}")
    
    # Test fracture zones
    fractures = generate_worley_fracture_zones(256, 256, seed=12345)
    print(f"Fractures - Shape: {fractures.shape}, Min: {np.min(fractures):.3f}, Max: {np.max(fractures):.3f}")
    
    # Test parameter validation
    validation = validate_worley_parameters(0.1, 'euclidean', 'F1')
    print(f"Parameter validation: {validation}")
    
    print("Worley noise tests completed successfully!")

if __name__ == "__main__":
    test_worley_generation()