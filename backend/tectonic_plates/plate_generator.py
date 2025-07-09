#!/usr/bin/env python3
"""
Main tectonic plate generator combining hex grid and watershed algorithm
"""

import numpy as np
from typing import Dict, List, Tuple, Optional
import base64
import io
from PIL import Image

from .hex_grid import HexagonalGrid, TectonicPlate
from .watershed import WatershedSegmentation

class PlateGenerator:
    """Generate tectonic plates from noise maps"""
    
    # Geological color palette
    PLATE_COLORS = [
        '#8B7355',  # Saddle brown
        '#6B8E5A',  # Olive green
        '#7A8B99',  # Blue gray
        '#9B7A8B',  # Dusty rose
        '#8B8B6B',  # Dark beige
        '#6B7A8B',  # Slate blue
        '#8B7A6B',  # Light brown
        '#7A8B7A',  # Sage green
        '#99887A',  # Warm gray
        '#7A7A8B',  # Cool gray
        '#8B997A',  # Khaki
        '#7A8B8B',  # Teal gray
        '#8B7A7A',  # Rosy brown
        '#7A997A',  # Moss green
        '#997A8B',  # Mauve
        '#8B8B7A',  # Sand
        '#7A8B6B',  # Olive gray
        '#8B7A99',  # Lavender gray
        '#6B7A7A',  # Dark sage
        '#997A7A',  # Dusty pink
        '#7A996B',  # Yellow green
        '#8B6B7A',  # Plum gray
        '#7A7A99',  # Periwinkle gray
        '#996B7A',  # Rose gray
        '#7A8B7A',  # Mint gray
        '#8B7A8B',  # Taupe
        '#7A7A7A',  # Medium gray
        '#8B8B8B',  # Light gray
        '#6B6B6B',  # Dark gray
        '#999999',  # Silver
    ]
    
    def __init__(self):
        """Initialize plate generator"""
        self.hex_grid = None
        self.plates = {}
        
    def decode_noise_data(self, noise_data: str) -> np.ndarray:
        """
        Decode base64 noise data from frontend
        
        Args:
            noise_data: Base64 encoded noise image
            
        Returns:
            2D numpy array of noise values
        """
        # Remove data URL prefix if present
        if ',' in noise_data:
            noise_data = noise_data.split(',')[1]
        
        # Decode base64
        img_data = base64.b64decode(noise_data)
        img = Image.open(io.BytesIO(img_data))
        
        # Convert to grayscale numpy array
        noise_array = np.array(img.convert('L')) / 255.0
        
        return noise_array
    
    def generate_plates(self, 
                       noise_data: str,
                       grid_width: int,
                       grid_height: int,
                       sensitivity: float,
                       min_plates: int,
                       max_plates: int,
                       complexity: str,
                       wrap_edges: bool,
                       seed: Optional[int] = None) -> Dict:
        """
        Generate tectonic plates from noise map
        
        Args:
            noise_data: Base64 encoded noise map
            grid_width: Hex grid width
            grid_height: Hex grid height
            sensitivity: Plate growth sensitivity (0.05-0.40)
            min_plates: Minimum number of plates
            max_plates: Maximum number of plates
            complexity: Complexity level (low, medium, high)
            wrap_edges: Whether to wrap edges
            seed: Random seed for reproducibility
            
        Returns:
            Dictionary with plate data
        """
        # Set random seed if provided
        if seed is not None:
            np.random.seed(seed)
        
        # Decode noise data
        noise_map = self.decode_noise_data(noise_data)
        
        # Resize noise map to match hex grid
        noise_map = self._resize_noise_map(noise_map, grid_width, grid_height)
        
        # Initialize hex grid
        self.hex_grid = HexagonalGrid(grid_width, grid_height, wrap_edges)
        
        # Perform watershed segmentation
        watershed = WatershedSegmentation(self.hex_grid)
        
        # Calculate target plates (middle of range)
        target_plates = (min_plates + max_plates) // 2
        
        # Initial segmentation
        plate_grid = watershed.segment(noise_map, sensitivity, target_plates, complexity)
        
        # Count plates
        unique_plates = np.unique(plate_grid[plate_grid > 0])
        current_plates = len(unique_plates)
        
        # Adjust if outside desired range
        if current_plates < min_plates:
            # Increase sensitivity to create more plates
            new_sensitivity = sensitivity * 0.7
            plate_grid = watershed.segment(noise_map, new_sensitivity, min_plates, complexity)
        elif current_plates > max_plates:
            # Decrease sensitivity to create fewer plates
            new_sensitivity = sensitivity * 1.5
            plate_grid = watershed.segment(noise_map, new_sensitivity, max_plates, complexity)
            
            # If still too many, merge smallest plates
            if len(np.unique(plate_grid[plate_grid > 0])) > max_plates:
                min_size = (grid_width * grid_height) // max_plates // 2
                watershed.merge_small_plates(min_size)
        
        # Create plate objects
        self._create_plate_objects()
        
        # Generate response data
        return self._generate_response()
    
    def _resize_noise_map(self, noise_map: np.ndarray, width: int, height: int) -> np.ndarray:
        """
        Resize noise map to match hex grid dimensions
        
        Args:
            noise_map: Original noise map
            width: Target width
            height: Target height
            
        Returns:
            Resized noise map
        """
        from scipy import ndimage
        
        # Calculate scaling factors
        scale_x = width / noise_map.shape[1]
        scale_y = height / noise_map.shape[0]
        
        # Resize using bilinear interpolation
        resized = ndimage.zoom(noise_map, (scale_y, scale_x), order=1)
        
        # Ensure exact dimensions
        if resized.shape != (height, width):
            resized = resized[:height, :width]
        
        return resized
    
    def _create_plate_objects(self):
        """Create TectonicPlate objects from grid data"""
        self.plates = {}
        
        # Get plate data
        plate_hexagons = self.hex_grid.get_plate_hexagons()
        plate_sizes = self.hex_grid.get_plate_sizes()
        plate_neighbors = self.hex_grid.calculate_plate_neighbors()
        
        # Assign colors ensuring neighbors have different colors
        plate_colors = self._assign_plate_colors(plate_neighbors)
        
        # Create plate objects
        for plate_id, hexagons in plate_hexagons.items():
            if plate_id > 0:  # Skip unassigned (-1)
                self.plates[plate_id] = TectonicPlate(
                    id=plate_id,
                    hexagons=hexagons,
                    size=plate_sizes.get(plate_id, 0),
                    neighbors=plate_neighbors.get(plate_id, set()),
                    color=plate_colors.get(plate_id, '#808080')
                )
    
    def _assign_plate_colors(self, neighbors: Dict[int, set]) -> Dict[int, str]:
        """
        Assign colors to plates ensuring neighbors have different colors
        
        Args:
            neighbors: Dictionary of plate neighbors
            
        Returns:
            Dictionary mapping plate ID to color
        """
        plate_colors = {}
        color_index = 0
        
        # Sort plates by number of neighbors (graph coloring heuristic)
        sorted_plates = sorted(neighbors.keys(), key=lambda p: len(neighbors.get(p, [])), reverse=True)
        
        for plate_id in sorted_plates:
            # Find used colors by neighbors
            used_colors = set()
            for neighbor_id in neighbors.get(plate_id, []):
                if neighbor_id in plate_colors:
                    used_colors.add(plate_colors[neighbor_id])
            
            # Find first available color
            assigned = False
            for i, color in enumerate(self.PLATE_COLORS):
                if color not in used_colors:
                    plate_colors[plate_id] = color
                    assigned = True
                    break
            
            # If all colors used by neighbors, use next in sequence
            if not assigned:
                plate_colors[plate_id] = self.PLATE_COLORS[color_index % len(self.PLATE_COLORS)]
                color_index += 1
        
        return plate_colors
    
    def _generate_response(self) -> Dict:
        """
        Generate response data for API
        
        Returns:
            Dictionary with plate data
        """
        # Metadata
        metadata = {
            "grid_size": {
                "width": self.hex_grid.width,
                "height": self.hex_grid.height
            },
            "total_hexagons": self.hex_grid.width * self.hex_grid.height,
            "plate_count": len(self.plates),
            "wrap_edges": self.hex_grid.wrap_edges
        }
        
        # Plate data
        plates_data = []
        for plate in self.plates.values():
            plates_data.append({
                "id": plate.id,
                "size": plate.size,
                "neighbors": list(plate.neighbors),
                "color": plate.color,
                "center": self._calculate_plate_center(plate.hexagons)
            })
        
        # Compact grid format (2D array of plate IDs)
        grid_data = self.hex_grid.grid.tolist()
        
        # Color mapping
        color_mapping = {str(p.id): p.color for p in self.plates.values()}
        
        return {
            "metadata": metadata,
            "plates": plates_data,
            "grid": grid_data,
            "colors": color_mapping
        }
    
    def _calculate_plate_center(self, hexagons: List[Tuple[int, int]]) -> Tuple[float, float]:
        """
        Calculate center of mass for a plate
        
        Args:
            hexagons: List of hexagon coordinates
            
        Returns:
            Center coordinates
        """
        if not hexagons:
            return (0, 0)
        
        cx = sum(x for x, y in hexagons) / len(hexagons)
        cy = sum(y for x, y in hexagons) / len(hexagons)
        
        return (round(cx, 2), round(cy, 2))