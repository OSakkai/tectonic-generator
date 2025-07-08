#!/usr/bin/env python3
"""
Image processing utilities for noise visualization and export
"""

import numpy as np
from PIL import Image
import base64
import io

def normalize_array(array, target_range=(0, 1)):
    """
    Normalize array to target range following doc2_structure.md specifications
    
    Args:
        array (numpy.ndarray): Input array
        target_range (tuple): Target range (min, max)
    
    Returns:
        numpy.ndarray: Normalized array
    """
    
    min_val = np.min(array)
    max_val = np.max(array)
    
    if max_val - min_val == 0:
        # Handle constant arrays
        return np.full_like(array, target_range[0])
    
    # Normalize to [0, 1]
    normalized = (array - min_val) / (max_val - min_val)
    
    # Scale to target range
    target_min, target_max = target_range
    scaled = normalized * (target_max - target_min) + target_min
    
    return scaled

def array_to_image(array, colormap='grayscale'):
    """
    Convert numpy array to base64 encoded image for frontend display
    
    Args:
        array (numpy.ndarray): Input array
        colormap (str): Color mapping ('grayscale', 'terrain', 'oceanic', 'continental')
    
    Returns:
        str: Base64 encoded image data URL
    """
    
    # Normalize array to [0, 255]
    normalized = normalize_array(array, (0, 255)).astype(np.uint8)
    
    # Apply color mapping
    if colormap == 'grayscale':
        # Simple grayscale
        image_array = normalized
        
    elif colormap == 'terrain':
        # Terrain colormap: blue (low) -> green -> brown -> white (high)
        image_array = apply_terrain_colormap(normalized)
        
    elif colormap == 'oceanic':
        # Oceanic colormap: deep blue -> light blue
        image_array = apply_oceanic_colormap(normalized)
        
    elif colormap == 'continental':
        # Continental colormap: green -> brown -> white
        image_array = apply_continental_colormap(normalized)
        
    else:
        # Default to grayscale
        image_array = normalized
    
    # Convert to PIL Image
    if len(image_array.shape) == 2:
        # Grayscale
        pil_image = Image.fromarray(image_array, mode='L')
    else:
        # RGB
        pil_image = Image.fromarray(image_array, mode='RGB')
    
    # Convert to base64
    buffer = io.BytesIO()
    pil_image.save(buffer, format='PNG')
    img_str = base64.b64encode(buffer.getvalue()).decode()
    
    return f"data:image/png;base64,{img_str}"

def apply_terrain_colormap(normalized_array):
    """
    Apply terrain colormap following doc2_structure.md color specifications
    
    Args:
        normalized_array (numpy.ndarray): Array normalized to [0, 255]
    
    Returns:
        numpy.ndarray: RGB image array
    """
    
    height, width = normalized_array.shape
    rgb_array = np.zeros((height, width, 3), dtype=np.uint8)
    
    # Define elevation thresholds and colors
    # Colors from doc2_structure.md CSS variables
    deep_ocean = np.array([25, 25, 112])      # #191970 (deep_ocean)
    shallow_water = np.array([135, 206, 235]) # #87CEEB (shallow_water)
    continental = np.array([139, 69, 19])     # #8B4513 (noise_continental)
    mountain = np.array([139, 115, 85])       # #8B7355 (noise_mountain)
    snow = np.array([255, 250, 250])          # #FFFAFA (noise_snow)
    
    # Apply colors based on elevation
    for y in range(height):
        for x in range(width):
            value = normalized_array[y, x]
            
            if value < 85:  # Deep ocean
                rgb_array[y, x] = deep_ocean
            elif value < 115:  # Shallow water
                t = (value - 85) / 30.0
                rgb_array[y, x] = interpolate_color(deep_ocean, shallow_water, t)
            elif value < 170:  # Continental
                t = (value - 115) / 55.0
                rgb_array[y, x] = interpolate_color(shallow_water, continental, t)
            elif value < 220:  # Mountain
                t = (value - 170) / 50.0
                rgb_array[y, x] = interpolate_color(continental, mountain, t)
            else:  # Snow peaks
                t = (value - 220) / 35.0
                rgb_array[y, x] = interpolate_color(mountain, snow, t)
    
    return rgb_array

def apply_oceanic_colormap(normalized_array):
    """
    Apply oceanic colormap using doc2_structure.md oceanic color
    
    Args:
        normalized_array (numpy.ndarray): Array normalized to [0, 255]
    
    Returns:
        numpy.ndarray: RGB image array
    """
    
    height, width = normalized_array.shape
    rgb_array = np.zeros((height, width, 3), dtype=np.uint8)
    
    # Oceanic colors from doc2_structure.md
    deep_oceanic = np.array([25, 25, 112])    # Dark blue for deep
    noise_oceanic = np.array([65, 105, 225])  # #4169E1 (noise_oceanic)
    shallow_water = np.array([135, 206, 235]) # Light blue for shallow
    
    for y in range(height):
        for x in range(width):
            value = normalized_array[y, x]
            
            if value < 128:
                # Deep to medium ocean
                t = value / 128.0
                rgb_array[y, x] = interpolate_color(deep_oceanic, noise_oceanic, t)
            else:
                # Medium to shallow ocean
                t = (value - 128) / 127.0
                rgb_array[y, x] = interpolate_color(noise_oceanic, shallow_water, t)
    
    return rgb_array

def apply_continental_colormap(normalized_array):
    """
    Apply continental colormap using doc2_structure.md continental color
    
    Args:
        normalized_array (numpy.ndarray): Array normalized to [0, 255]
    
    Returns:
        numpy.ndarray: RGB image array
    """
    
    height, width = normalized_array.shape
    rgb_array = np.zeros((height, width, 3), dtype=np.uint8)
    
    # Continental colors from doc2_structure.md
    forest = np.array([34, 139, 34])          # #228B22 (noise_forest)
    continental = np.array([139, 69, 19])     # #8B4513 (noise_continental)
    desert = np.array([244, 164, 96])         # #F4A460 (noise_desert)
    snow = np.array([255, 250, 250])          # #FFFAFA (noise_snow)
    
    for y in range(height):
        for x in range(width):
            value = normalized_array[y, x]
            
            if value < 85:  # Forest/lowlands
                rgb_array[y, x] = forest
            elif value < 170:  # Continental/hills
                t = (value - 85) / 85.0
                rgb_array[y, x] = interpolate_color(forest, continental, t)
            elif value < 220:  # Desert/high elevations
                t = (value - 170) / 50.0
                rgb_array[y, x] = interpolate_color(continental, desert, t)
            else:  # Snow peaks
                t = (value - 220) / 35.0
                rgb_array[y, x] = interpolate_color(desert, snow, t)
    
    return rgb_array

def interpolate_color(color1, color2, t):
    """
    Linear interpolation between two RGB colors
    
    Args:
        color1 (numpy.ndarray): First color [R, G, B]
        color2 (numpy.ndarray): Second color [R, G, B]
        t (float): Interpolation factor [0, 1]
    
    Returns:
        numpy.ndarray: Interpolated color [R, G, B]
    """
    
    t = max(0, min(1, t))  # Clamp t to [0, 1]
    return ((1 - t) * color1 + t * color2).astype(np.uint8)

def apply_plate_boundary_visualization(noise_array, boundaries_array, boundary_color='red'):
    """
    Overlay plate boundaries on noise visualization
    
    Args:
        noise_array (numpy.ndarray): Base noise array
        boundaries_array (numpy.ndarray): Plate boundaries array
        boundary_color (str): Color for boundaries ('red', 'white', 'black')
    
    Returns:
        numpy.ndarray: RGB array with boundaries overlaid
    """
    
    # Convert noise to terrain colormap
    base_image = apply_terrain_colormap(normalize_array(noise_array, (0, 255)).astype(np.uint8))
    
    # Define boundary colors from doc2_structure.md
    if boundary_color == 'red':
        boundary_rgb = np.array([255, 0, 0])    # #FF0000 (plate_boundary)
    elif boundary_color == 'white':
        boundary_rgb = np.array([255, 255, 255])
    elif boundary_color == 'black':
        boundary_rgb = np.array([0, 0, 0])
    else:
        boundary_rgb = np.array([255, 0, 0])    # Default to red
    
    # Normalize boundaries to [0, 1]
    boundaries_normalized = normalize_array(boundaries_array, (0, 1))
    
    # Apply boundaries where they are strong (> 0.7)
    height, width = noise_array.shape
    for y in range(height):
        for x in range(width):
            if boundaries_normalized[y, x] > 0.7:
                # Strong boundary - use pure boundary color
                base_image[y, x] = boundary_rgb
            elif boundaries_normalized[y, x] > 0.3:
                # Moderate boundary - blend with base
                t = (boundaries_normalized[y, x] - 0.3) / 0.4
                base_image[y, x] = interpolate_color(base_image[y, x], boundary_rgb, t)
    
    return base_image

def export_array_as_image(array, filepath, format='PNG', colormap='grayscale'):
    """
    Export numpy array as image file
    
    Args:
        array (numpy.ndarray): Input array
        filepath (str): Output file path
        format (str): Image format ('PNG', 'JPG', 'TIFF')
        colormap (str): Color mapping to apply
    
    Returns:
        bool: Success status
    """
    
    try:
        # Apply colormap
        if colormap == 'grayscale':
            normalized = normalize_array(array, (0, 255)).astype(np.uint8)
            pil_image = Image.fromarray(normalized, mode='L')
        else:
            # Apply color mapping
            if colormap == 'terrain':
                rgb_array = apply_terrain_colormap(normalize_array(array, (0, 255)).astype(np.uint8))
            elif colormap == 'oceanic':
                rgb_array = apply_oceanic_colormap(normalize_array(array, (0, 255)).astype(np.uint8))
            elif colormap == 'continental':
                rgb_array = apply_continental_colormap(normalize_array(array, (0, 255)).astype(np.uint8))
            else:
                rgb_array = apply_terrain_colormap(normalize_array(array, (0, 255)).astype(np.uint8))
            
            pil_image = Image.fromarray(rgb_array, mode='RGB')
        
        # Save image
        if format.upper() == 'JPG' or format.upper() == 'JPEG':
            # Convert to RGB for JPEG if grayscale
            if pil_image.mode == 'L':
                pil_image = pil_image.convert('RGB')
            pil_image.save(filepath, format='JPEG', quality=95)
        else:
            pil_image.save(filepath, format=format.upper())
        
        return True
        
    except Exception as e:
        print(f"Error exporting image: {e}")
        return False

def calculate_image_statistics(array):
    """
    Calculate statistical information about the array
    
    Args:
        array (numpy.ndarray): Input array
    
    Returns:
        dict: Statistical information
    """
    
    return {
        'min_value': float(np.min(array)),
        'max_value': float(np.max(array)),
        'mean_value': float(np.mean(array)),
        'median_value': float(np.median(array)),
        'std_value': float(np.std(array)),
        'range_value': float(np.max(array) - np.min(array)),
        'shape': array.shape,
        'dtype': str(array.dtype)
    }

def create_elevation_histogram(array, bins=50):
    """
    Create histogram data for elevation distribution
    
    Args:
        array (numpy.ndarray): Input array
        bins (int): Number of histogram bins
    
    Returns:
        dict: Histogram data for frontend visualization
    """
    
    hist, bin_edges = np.histogram(array.flatten(), bins=bins)
    
    return {
        'counts': hist.tolist(),
        'bin_edges': bin_edges.tolist(),
        'bins': bins
    }