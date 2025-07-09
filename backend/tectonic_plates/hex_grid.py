#!/usr/bin/env python3
"""
Hexagonal grid system for tectonic plate generation
Implements cartesian hex grid with flat-topped hexagons
"""

import numpy as np
from typing import List, Tuple, Set, Dict
from dataclasses import dataclass
import math

@dataclass
class Hexagon:
    """Single hexagon in the grid"""
    x: int
    y: int
    plate_id: int = -1
    noise_value: float = 0.0

@dataclass
class TectonicPlate:
    """Tectonic plate containing multiple hexagons"""
    id: int
    hexagons: List[Tuple[int, int]]
    size: int
    neighbors: Set[int]
    color: str
    
class HexagonalGrid:
    """Hexagonal grid system with plate assignment"""
    
    def __init__(self, width: int, height: int, wrap_edges: bool = False):
        """
        Initialize hexagonal grid
        
        Args:
            width: Grid width in hexagons
            height: Grid height in hexagons
            wrap_edges: Whether to wrap edges (spherical topology)
        """
        self.width = width
        self.height = height
        self.wrap_edges = wrap_edges
        self.grid = np.zeros((height, width), dtype=int)
        self.noise_values = np.zeros((height, width), dtype=float)
        
    def get_neighbors(self, x: int, y: int) -> List[Tuple[int, int]]:
        """
        Get all 6 neighbors of a hexagon
        
        Args:
            x: X coordinate
            y: Y coordinate
            
        Returns:
            List of neighbor coordinates
        """
        # Offset coordinates for flat-topped hexagons
        if y % 2 == 0:  # Even row
            neighbors = [
                (x - 1, y),      # Left
                (x + 1, y),      # Right
                (x, y - 1),      # Top-left
                (x + 1, y - 1),  # Top-right
                (x, y + 1),      # Bottom-left
                (x + 1, y + 1)   # Bottom-right
            ]
        else:  # Odd row
            neighbors = [
                (x - 1, y),      # Left
                (x + 1, y),      # Right
                (x - 1, y - 1),  # Top-left
                (x, y - 1),      # Top-right
                (x - 1, y + 1),  # Bottom-left
                (x, y + 1)       # Bottom-right
            ]
        
        # Filter valid neighbors
        valid_neighbors = []
        for nx, ny in neighbors:
            if self.wrap_edges:
                # Wrap coordinates
                nx = nx % self.width
                ny = ny % self.height
                valid_neighbors.append((nx, ny))
            else:
                # Check bounds
                if 0 <= nx < self.width and 0 <= ny < self.height:
                    valid_neighbors.append((nx, ny))
        
        return valid_neighbors
    
    def pixel_to_hex(self, px: float, py: float, hex_size: float) -> Tuple[int, int]:
        """
        Convert pixel coordinates to hex coordinates
        
        Args:
            px: Pixel X coordinate
            py: Pixel Y coordinate
            hex_size: Size of hexagon
            
        Returns:
            Hex grid coordinates
        """
        # Convert to hex coordinates (flat-topped)
        q = (2/3 * px) / hex_size
        r = (-1/3 * px + math.sqrt(3)/3 * py) / hex_size
        
        # Convert to offset coordinates
        x = int(round(q))
        y = int(round(r + (q - x) / 2))
        
        return (x, y)
    
    def hex_to_pixel(self, x: int, y: int, hex_size: float) -> Tuple[float, float]:
        """
        Convert hex coordinates to pixel coordinates
        
        Args:
            x: Hex X coordinate
            y: Hex Y coordinate
            hex_size: Size of hexagon
            
        Returns:
            Pixel coordinates of hex center
        """
        # Offset for odd rows
        offset = hex_size * 0.5 if y % 2 == 1 else 0
        
        px = hex_size * 1.5 * x + offset
        py = hex_size * math.sqrt(3) * y
        
        return (px, py)
    
    def get_hex_vertices(self, x: int, y: int, hex_size: float) -> List[Tuple[float, float]]:
        """
        Get vertices of a hexagon for drawing
        
        Args:
            x: Hex X coordinate
            y: Hex Y coordinate
            hex_size: Size of hexagon
            
        Returns:
            List of 6 vertex coordinates
        """
        cx, cy = self.hex_to_pixel(x, y, hex_size)
        vertices = []
        
        for i in range(6):
            angle = math.pi / 3 * i
            vx = cx + hex_size * math.cos(angle)
            vy = cy + hex_size * math.sin(angle)
            vertices.append((vx, vy))
        
        return vertices
    
    def flood_fill(self, start_x: int, start_y: int, plate_id: int, 
                   visited: Set[Tuple[int, int]], threshold: float) -> List[Tuple[int, int]]:
        """
        Flood fill algorithm to grow a plate from a seed
        
        Args:
            start_x: Starting X coordinate
            start_y: Starting Y coordinate
            plate_id: ID to assign to plate
            visited: Set of already visited hexagons
            threshold: Noise threshold for plate growth
            
        Returns:
            List of hexagons in this plate
        """
        stack = [(start_x, start_y)]
        plate_hexagons = []
        base_value = self.noise_values[start_y, start_x]
        
        while stack:
            x, y = stack.pop()
            
            if (x, y) in visited:
                continue
                
            visited.add((x, y))
            self.grid[y, x] = plate_id
            plate_hexagons.append((x, y))
            
            # Check neighbors
            for nx, ny in self.get_neighbors(x, y):
                if (nx, ny) not in visited:
                    noise_diff = abs(self.noise_values[ny, nx] - base_value)
                    if noise_diff <= threshold:
                        stack.append((nx, ny))
        
        return plate_hexagons
    
    def eliminate_exclaves(self, min_size: int = 10):
        """
        Eliminate small isolated regions (exclaves)
        
        Args:
            min_size: Minimum plate size to keep
        """
        # Find all connected components
        visited = set()
        components = []
        
        for y in range(self.height):
            for x in range(self.width):
                if (x, y) not in visited:
                    # BFS to find connected component
                    component = []
                    stack = [(x, y)]
                    plate_id = self.grid[y, x]
                    
                    while stack:
                        cx, cy = stack.pop()
                        if (cx, cy) in visited:
                            continue
                        
                        if self.grid[cy, cx] == plate_id:
                            visited.add((cx, cy))
                            component.append((cx, cy))
                            
                            for nx, ny in self.get_neighbors(cx, cy):
                                if (nx, ny) not in visited:
                                    stack.append((nx, ny))
                    
                    if component:
                        components.append((plate_id, component))
        
        # Merge small components into neighbors
        for plate_id, component in components:
            if len(component) < min_size:
                # Find most common neighbor plate
                neighbor_counts = {}
                
                for x, y in component:
                    for nx, ny in self.get_neighbors(x, y):
                        neighbor_id = self.grid[ny, nx]
                        if neighbor_id != plate_id:
                            neighbor_counts[neighbor_id] = neighbor_counts.get(neighbor_id, 0) + 1
                
                if neighbor_counts:
                    # Merge into most common neighbor
                    new_plate_id = max(neighbor_counts, key=neighbor_counts.get)
                    for x, y in component:
                        self.grid[y, x] = new_plate_id
    
    def calculate_plate_neighbors(self) -> Dict[int, Set[int]]:
        """
        Calculate which plates are neighbors
        
        Returns:
            Dictionary mapping plate ID to set of neighbor IDs
        """
        neighbors = {}
        
        for y in range(self.height):
            for x in range(self.width):
                plate_id = self.grid[y, x]
                
                if plate_id not in neighbors:
                    neighbors[plate_id] = set()
                
                # Check all neighbors
                for nx, ny in self.get_neighbors(x, y):
                    neighbor_id = self.grid[ny, nx]
                    if neighbor_id != plate_id:
                        neighbors[plate_id].add(neighbor_id)
        
        return neighbors
    
    def get_plate_sizes(self) -> Dict[int, int]:
        """
        Calculate size of each plate
        
        Returns:
            Dictionary mapping plate ID to number of hexagons
        """
        sizes = {}
        
        for y in range(self.height):
            for x in range(self.width):
                plate_id = self.grid[y, x]
                sizes[plate_id] = sizes.get(plate_id, 0) + 1
        
        return sizes
    
    def get_plate_hexagons(self) -> Dict[int, List[Tuple[int, int]]]:
        """
        Get all hexagons for each plate
        
        Returns:
            Dictionary mapping plate ID to list of hex coordinates
        """
        plate_hexagons = {}
        
        for y in range(self.height):
            for x in range(self.width):
                plate_id = self.grid[y, x]
                if plate_id not in plate_hexagons:
                    plate_hexagons[plate_id] = []
                plate_hexagons[plate_id].append((x, y))
        
        return plate_hexagons