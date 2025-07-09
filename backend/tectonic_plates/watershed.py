#!/usr/bin/env python3
"""
Watershed segmentation algorithm for tectonic plate generation
Adapts image segmentation techniques for hexagonal grid
"""

import numpy as np
from typing import List, Tuple, Dict, Set
import heapq
from scipy import ndimage
from dataclasses import dataclass

@dataclass
class WatershedMarker:
    """Marker for watershed algorithm"""
    x: int
    y: int
    plate_id: int
    priority: float

class WatershedSegmentation:
    """Watershed algorithm for plate generation"""
    
    def __init__(self, hex_grid):
        """
        Initialize watershed segmentation
        
        Args:
            hex_grid: HexagonalGrid instance
        """
        self.hex_grid = hex_grid
        self.width = hex_grid.width
        self.height = hex_grid.height
        
    def find_local_minima(self, noise_map: np.ndarray, target_plates: int) -> List[Tuple[int, int]]:
        """
        Find local minima in noise map to use as plate seeds
        
        Args:
            noise_map: 2D noise array
            target_plates: Target number of plates
            
        Returns:
            List of seed coordinates
        """
        # Apply smoothing to reduce noise
        smoothed = ndimage.gaussian_filter(noise_map, sigma=2.0)
        
        # Find local minima
        minima = []
        min_distance = max(self.width, self.height) / (target_plates ** 0.5) / 2
        
        for y in range(self.height):
            for x in range(self.width):
                if self._is_local_minimum(smoothed, x, y, radius=int(min_distance)):
                    minima.append((x, y, smoothed[y, x]))
        
        # Sort by value and select best minima
        minima.sort(key=lambda m: m[2])
        
        # Ensure minimum distance between seeds
        selected_seeds = []
        for x, y, _ in minima:
            too_close = False
            for sx, sy in selected_seeds:
                dist = ((x - sx) ** 2 + (y - sy) ** 2) ** 0.5
                if dist < min_distance:
                    too_close = True
                    break
            
            if not too_close:
                selected_seeds.append((x, y))
                if len(selected_seeds) >= target_plates:
                    break
        
        # If not enough minima, add random seeds
        while len(selected_seeds) < min(target_plates, 3):
            x = np.random.randint(0, self.width)
            y = np.random.randint(0, self.height)
            selected_seeds.append((x, y))
        
        return selected_seeds
    
    def _is_local_minimum(self, array: np.ndarray, x: int, y: int, radius: int) -> bool:
        """
        Check if position is a local minimum within radius
        
        Args:
            array: 2D array to check
            x, y: Position to check
            radius: Search radius
            
        Returns:
            True if local minimum
        """
        center_value = array[y, x]
        
        for dy in range(-radius, radius + 1):
            for dx in range(-radius, radius + 1):
                if dx == 0 and dy == 0:
                    continue
                
                nx, ny = x + dx, y + dy
                if 0 <= nx < self.width and 0 <= ny < self.height:
                    if array[ny, nx] < center_value:
                        return False
        
        return True
    
    def segment(self, noise_map: np.ndarray, sensitivity: float, 
                target_plates: int, complexity: str = "medium") -> np.ndarray:
        """
        Perform watershed segmentation on noise map
        
        Args:
            noise_map: 2D noise array normalized to [0, 1]
            sensitivity: Plate growth sensitivity (0.05-0.40)
            target_plates: Target number of plates
            complexity: Complexity level (low, medium, high)
            
        Returns:
            2D array with plate IDs
        """
        # Store noise values in grid
        self.hex_grid.noise_values = noise_map.copy()
        
        # Find seed points
        seeds = self.find_local_minima(noise_map, target_plates)
        
        # Initialize plates with seeds
        plate_grid = np.full((self.height, self.width), -1, dtype=int)
        priority_queue = []
        
        # Add seeds to priority queue
        for i, (x, y) in enumerate(seeds):
            plate_id = i + 1
            plate_grid[y, x] = plate_id
            
            # Add neighbors to queue
            for nx, ny in self.hex_grid.get_neighbors(x, y):
                if plate_grid[ny, nx] == -1:
                    priority = self._calculate_priority(noise_map, x, y, nx, ny, sensitivity, complexity)
                    heapq.heappush(priority_queue, (priority, nx, ny, plate_id))
        
        # Grow plates using priority queue
        visited = set()
        
        while priority_queue:
            priority, x, y, plate_id = heapq.heappop(priority_queue)
            
            if (x, y) in visited or plate_grid[y, x] != -1:
                continue
            
            visited.add((x, y))
            plate_grid[y, x] = plate_id
            
            # Add unassigned neighbors
            for nx, ny in self.hex_grid.get_neighbors(x, y):
                if (nx, ny) not in visited and plate_grid[ny, nx] == -1:
                    new_priority = self._calculate_priority(noise_map, x, y, nx, ny, sensitivity, complexity)
                    heapq.heappush(priority_queue, (new_priority, nx, ny, plate_id))
        
        # Update hex grid
        self.hex_grid.grid = plate_grid
        
        # Post-processing
        self._smooth_boundaries(complexity)
        self.hex_grid.eliminate_exclaves(min_size=max(10, (self.width * self.height) // 100))
        
        return plate_grid
    
    def _calculate_priority(self, noise_map: np.ndarray, 
                           from_x: int, from_y: int, 
                           to_x: int, to_y: int,
                           sensitivity: float, complexity: str) -> float:
        """
        Calculate priority for plate growth
        
        Args:
            noise_map: Noise values
            from_x, from_y: Source hexagon
            to_x, to_y: Target hexagon
            sensitivity: Growth sensitivity
            complexity: Complexity level
            
        Returns:
            Priority value (lower = higher priority)
        """
        # Base priority on noise difference
        noise_diff = abs(noise_map[to_y, to_x] - noise_map[from_y, from_x])
        
        # Adjust for complexity
        if complexity == "low":
            # Prefer smooth growth
            priority = noise_diff / sensitivity
        elif complexity == "high":
            # Add randomness for irregular shapes
            priority = (noise_diff + np.random.random() * 0.3) / sensitivity
        else:  # medium
            # Balanced approach
            priority = (noise_diff + np.random.random() * 0.1) / sensitivity
        
        return priority
    
    def _smooth_boundaries(self, complexity: str):
        """
        Smooth plate boundaries based on complexity
        
        Args:
            complexity: Complexity level
        """
        if complexity == "low":
            # Smooth boundaries by majority voting
            iterations = 3
        elif complexity == "high":
            # Keep irregular boundaries
            iterations = 0
        else:  # medium
            iterations = 1
        
        for _ in range(iterations):
            new_grid = self.hex_grid.grid.copy()
            
            for y in range(self.height):
                for x in range(self.width):
                    # Count neighbor plates
                    neighbor_counts = {}
                    for nx, ny in self.hex_grid.get_neighbors(x, y):
                        plate_id = self.hex_grid.grid[ny, nx]
                        neighbor_counts[plate_id] = neighbor_counts.get(plate_id, 0) + 1
                    
                    # Switch to majority if appropriate
                    current_plate = self.hex_grid.grid[y, x]
                    if neighbor_counts:
                        majority_plate = max(neighbor_counts, key=neighbor_counts.get)
                        if neighbor_counts.get(majority_plate, 0) >= 4:
                            new_grid[y, x] = majority_plate
            
            self.hex_grid.grid = new_grid
    
    def merge_small_plates(self, min_size: int):
        """
        Merge plates smaller than minimum size
        
        Args:
            min_size: Minimum plate size
        """
        sizes = self.hex_grid.get_plate_sizes()
        neighbors = self.hex_grid.calculate_plate_neighbors()
        
        # Find small plates
        small_plates = [pid for pid, size in sizes.items() if size < min_size]
        
        for plate_id in small_plates:
            if plate_id in neighbors and neighbors[plate_id]:
                # Merge into largest neighbor
                neighbor_sizes = {nid: sizes.get(nid, 0) for nid in neighbors[plate_id]}
                largest_neighbor = max(neighbor_sizes, key=neighbor_sizes.get)
                
                # Replace all occurrences
                self.hex_grid.grid[self.hex_grid.grid == plate_id] = largest_neighbor