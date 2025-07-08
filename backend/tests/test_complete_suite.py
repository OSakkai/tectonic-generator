#!/usr/bin/env python3
"""
Complete test suite for Tectonic Generator Backend
Tests all noise algorithms, API endpoints, and utilities
"""

import sys
import os
import time
import json
import requests
import numpy as np
from pathlib import Path

# Add backend to path for imports
backend_path = Path(__file__).parent.parent
sys.path.insert(0, str(backend_path))

# Import modules to test
from noise.perlin import generate_perlin_noise, validate_perlin_parameters
from noise.simplex import generate_simplex_noise, validate_simplex_parameters
from noise.worley import generate_worley_noise, validate_worley_parameters
from utils.validation import validate_noise_parameters, sanitize_parameters
from utils.image_processing import normalize_array, array_to_image, calculate_image_statistics

class TectonicTestSuite:
    def __init__(self, api_base_url="http://localhost:5000"):
        self.api_base_url = api_base_url
        self.test_results = []
        self.failed_tests = []
        
    def log_test(self, test_name, success, message="", error=None):
        """Log test result"""
        result = {
            "test": test_name,
            "success": success,
            "message": message,
            "error": str(error) if error else None,
            "timestamp": time.time()
        }
        self.test_results.append(result)
        
        status = "✅ PASS" if success else "❌ FAIL"
        print(f"{status} - {test_name}: {message}")
        
        if not success:
            self.failed_tests.append(test_name)
            if error:
                print(f"    Error: {error}")
    
    def test_perlin_generation(self):
        """Test Perlin noise generation"""
        try:
            # Test basic generation
            noise = generate_perlin_noise(256, 256, scale=0.05, octaves=4, seed=12345)
            
            # Validate output
            assert noise.shape == (256, 256), f"Expected shape (256, 256), got {noise.shape}"
            assert np.all(np.isfinite(noise)), "Noise contains non-finite values"
            
            # Test statistical properties
            mean_val = np.mean(noise)
            std_val = np.std(noise)
            assert -1 <= mean_val <= 1, f"Mean {mean_val} outside expected range [-1, 1]"
            assert std_val > 0, f"Standard deviation {std_val} should be > 0"
            
            self.log_test("Perlin Generation", True, f"Generated 256x256, mean={mean_val:.3f}, std={std_val:.3f}")
            
        except Exception as e:
            self.log_test("Perlin Generation", False, "Failed to generate Perlin noise", e)
    
    def test_simplex_generation(self):
        """Test Simplex noise generation"""
        try:
            # Test basic generation
            noise = generate_simplex_noise(256, 256, scale=0.02, octaves=5, seed=12345)
            
            # Validate output
            assert noise.shape == (256, 256), f"Expected shape (256, 256), got {noise.shape}"
            assert np.all(np.isfinite(noise)), "Noise contains non-finite values"
            
            # Test statistical properties
            mean_val = np.mean(noise)
            std_val = np.std(noise)
            assert -1 <= mean_val <= 1, f"Mean {mean_val} outside expected range [-1, 1]"
            assert std_val > 0, f"Standard deviation {std_val} should be > 0"
            
            self.log_test("Simplex Generation", True, f"Generated 256x256, mean={mean_val:.3f}, std={std_val:.3f}")
            
        except Exception as e:
            self.log_test("Simplex Generation", False, "Failed to generate Simplex noise", e)
    
    def test_worley_generation(self):
        """Test Worley noise generation"""
        try:
            # Test basic generation
            noise = generate_worley_noise(256, 256, frequency=0.1, seed=12345)
            
            # Validate output
            assert noise.shape == (256, 256), f"Expected shape (256, 256), got {noise.shape}"
            assert np.all(np.isfinite(noise)), "Noise contains non-finite values"
            assert np.min(noise) >= 0, f"Worley noise should be non-negative, got min={np.min(noise)}"
            
            # Test statistical properties
            mean_val = np.mean(noise)
            std_val = np.std(noise)
            assert std_val > 0, f"Standard deviation {std_val} should be > 0"
            
            self.log_test("Worley Generation", True, f"Generated 256x256, mean={mean_val:.3f}, std={std_val:.3f}")
            
        except Exception as e:
            self.log_test("Worley Generation", False, "Failed to generate Worley noise", e)
    
    def test_parameter_validation(self):
        """Test parameter validation functions"""
        try:
            # Test Perlin validation
            valid_perlin = {'scale': 0.05, 'octaves': 4, 'persistence': 0.5, 'lacunarity': 2.0}
            result = validate_perlin_parameters(valid_perlin)
            assert result['valid'], f"Valid Perlin parameters rejected: {result['errors']}"
            
            invalid_perlin = {'scale': 2.0, 'octaves': 10, 'persistence': 1.5, 'lacunarity': 0.5}
            result = validate_perlin_parameters(invalid_perlin)
            assert not result['valid'], "Invalid Perlin parameters accepted"
            
            # Test Simplex validation
            valid_simplex = {'scale': 0.02, 'octaves': 5, 'persistence': 0.4, 'lacunarity': 3.0}
            result = validate_simplex_parameters(valid_simplex)
            assert result['valid'], f"Valid Simplex parameters rejected: {result['errors']}"
            
            # Test Worley validation
            valid_worley = {'frequency': 0.1, 'distance_function': 'euclidean', 'cell_type': 'F1'}
            result = validate_worley_parameters(valid_worley)
            assert result['valid'], f"Valid Worley parameters rejected: {result['errors']}"
            
            self.log_test("Parameter Validation", True, "All validation functions working correctly")
            
        except Exception as e:
            self.log_test("Parameter Validation", False, "Parameter validation failed", e)
    
    def test_image_processing(self):
        """Test image processing utilities"""
        try:
            # Create test array
            test_array = np.random.rand(64, 64)
            
            # Test normalization
            normalized = normalize_array(test_array, (0, 255))
            assert 0 <= np.min(normalized) <= np.max(normalized) <= 255, "Normalization failed"
            
            # Test image conversion
            image_data = array_to_image(test_array)
            assert image_data.startswith("data:image/png;base64,"), "Image conversion failed"
            
            # Test statistics
            stats = calculate_image_statistics(test_array)
            required_keys = ['min_value', 'max_value', 'mean_value', 'std_value']
            for key in required_keys:
                assert key in stats, f"Missing statistic: {key}"
            
            self.log_test("Image Processing", True, "All image processing functions working")
            
        except Exception as e:
            self.log_test("Image Processing", False, "Image processing failed", e)
    
    def test_api_health(self):
        """Test API health endpoint"""
        try:
            response = requests.get(f"{self.api_base_url}/api/health", timeout=10)
            
            assert response.status_code == 200, f"Health check returned {response.status_code}"
            
            data = response.json()
            assert data['success'], "Health check returned success=False"
            assert 'algorithms' in data['data'], "Health check missing algorithms info"
            
            self.log_test("API Health", True, f"Health check passed: {data['data']['status']}")
            
        except requests.exceptions.RequestException as e:
            self.log_test("API Health", False, "Could not connect to API", e)
        except Exception as e:
            self.log_test("API Health", False, "Health check failed", e)
    
    def test_api_parameters(self):
        """Test API parameters endpoint"""
        try:
            response = requests.get(f"{self.api_base_url}/api/noise/parameters", timeout=10)
            
            assert response.status_code == 200, f"Parameters endpoint returned {response.status_code}"
            
            data = response.json()
            assert data['success'], "Parameters endpoint returned success=False"
            
            # Validate parameter structure
            params = data['data']
            required_algorithms = ['perlin', 'simplex', 'worley']
            for algo in required_algorithms:
                assert algo in params, f"Missing algorithm parameters: {algo}"
            
            self.log_test("API Parameters", True, "Parameters endpoint working correctly")
            
        except requests.exceptions.RequestException as e:
            self.log_test("API Parameters", False, "Could not connect to parameters endpoint", e)
        except Exception as e:
            self.log_test("API Parameters", False, "Parameters endpoint failed", e)
    
    def test_api_perlin_generation(self):
        """Test API Perlin noise generation"""
        try:
            payload = {
                "width": 128,
                "height": 128,
                "scale": 0.05,
                "octaves": 4,
                "persistence": 0.5,
                "lacunarity": 2.0,
                "seed": 12345
            }
            
            response = requests.post(
                f"{self.api_base_url}/api/noise/perlin",
                json=payload,
                timeout=30
            )
            
            assert response.status_code == 200, f"Perlin API returned {response.status_code}"
            
            data = response.json()
            assert data['success'], f"Perlin API failed: {data.get('error')}"
            assert 'image_data' in data['data'], "Missing image data in response"
            assert 'generation_time' in data, "Missing generation time"
            
            # Validate generation time
            gen_time = data['generation_time']
            assert gen_time < 30, f"Generation time {gen_time}s exceeds 30s limit"
            
            self.log_test("API Perlin Generation", True, f"Generated 128x128 in {gen_time:.3f}s")
            
        except requests.exceptions.RequestException as e:
            self.log_test("API Perlin Generation", False, "Could not connect to Perlin API", e)
        except Exception as e:
            self.log_test("API Perlin Generation", False, "Perlin API test failed", e)
    
    def test_api_simplex_generation(self):
        """Test API Simplex noise generation"""
        try:
            payload = {
                "width": 128,
                "height": 128,
                "scale": 0.02,
                "octaves": 5,
                "persistence": 0.4,
                "lacunarity": 3.0,
                "seed": 12345
            }
            
            response = requests.post(
                f"{self.api_base_url}/api/noise/simplex",
                json=payload,
                timeout=30
            )
            
            assert response.status_code == 200, f"Simplex API returned {response.status_code}"
            
            data = response.json()
            assert data['success'], f"Simplex API failed: {data.get('error')}"
            assert 'image_data' in data['data'], "Missing image data in response"
            
            gen_time = data['generation_time']
            assert gen_time < 30, f"Generation time {gen_time}s exceeds 30s limit"
            
            self.log_test("API Simplex Generation", True, f"Generated 128x128 in {gen_time:.3f}s")
            
        except requests.exceptions.RequestException as e:
            self.log_test("API Simplex Generation", False, "Could not connect to Simplex API", e)
        except Exception as e:
            self.log_test("API Simplex Generation", False, "Simplex API test failed", e)
    
    def test_api_worley_generation(self):
        """Test API Worley noise generation"""
        try:
            payload = {
                "width": 128,
                "height": 128,
                "frequency": 0.1,
                "distance_function": "euclidean",
                "cell_type": "F1",
                "seed": 12345
            }
            
            response = requests.post(
                f"{self.api_base_url}/api/noise/worley",
                json=payload,
                timeout=30
            )
            
            assert response.status_code == 200, f"Worley API returned {response.status_code}"
            
            data = response.json()
            assert data['success'], f"Worley API failed: {data.get('error')}"
            assert 'image_data' in data['data'], "Missing image data in response"
            
            gen_time = data['generation_time']
            assert gen_time < 30, f"Generation time {gen_time}s exceeds 30s limit"
            
            self.log_test("API Worley Generation", True, f"Generated 128x128 in {gen_time:.3f}s")
            
        except requests.exceptions.RequestException as e:
            self.log_test("API Worley Generation", False, "Could not connect to Worley API", e)
        except Exception as e:
            self.log_test("API Worley Generation", False, "Worley API test failed", e)
    
    def test_api_error_handling(self):
        """Test API error handling"""
        try:
            # Test invalid parameters
            invalid_payload = {
                "width": 128,
                "height": 128,
                "scale": 999,  # Invalid scale
                "octaves": 50  # Invalid octaves
            }
            
            response = requests.post(
                f"{self.api_base_url}/api/noise/perlin",
                json=invalid_payload,
                timeout=10
            )
            
            # Should return 400 for validation error
            assert response.status_code == 400, f"Expected 400 for invalid params, got {response.status_code}"
            
            data = response.json()
            assert not data['success'], "API should reject invalid parameters"
            assert 'error' in data, "Missing error message for invalid parameters"
            
            self.log_test("API Error Handling", True, "API correctly handles invalid parameters")
            
        except requests.exceptions.RequestException as e:
            self.log_test("API Error Handling", False, "Could not test error handling", e)
        except Exception as e:
            self.log_test("API Error Handling", False, "Error handling test failed", e)
    
    def test_performance_benchmarks(self):
        """Test performance benchmarks"""
        try:
            # Test different resolutions and measure time
            resolutions = [(64, 64), (128, 128), (256, 256), (512, 512)]
            results = []
            
            for width, height in resolutions:
                start_time = time.time()
                
                # Test Perlin generation
                noise = generate_perlin_noise(width, height, scale=0.05, octaves=4, seed=12345)
                
                generation_time = time.time() - start_time
                pixels = width * height
                
                results.append({
                    'resolution': f"{width}x{height}",
                    'pixels': pixels,
                    'time': generation_time,
                    'pixels_per_second': pixels / generation_time
                })
                
                # Check performance limits from doc2_structure.md
                if pixels <= 512 * 512 and generation_time > 5:
                    raise AssertionError(f"Performance too slow: {generation_time:.3f}s for {width}x{height}")
            
            # Log performance results
            for result in results:
                print(f"    {result['resolution']}: {result['time']:.3f}s ({result['pixels_per_second']:.0f} pixels/s)")
            
            self.log_test("Performance Benchmarks", True, f"Tested {len(resolutions)} resolutions")
            
        except Exception as e:
            self.log_test("Performance Benchmarks", False, "Performance test failed", e)
    
    def test_reproducibility(self):
        """Test that same seeds produce same results"""
        try:
            seed = 42
            
            # Generate same noise twice with same seed
            noise1 = generate_perlin_noise(64, 64, scale=0.05, octaves=4, seed=seed)
            noise2 = generate_perlin_noise(64, 64, scale=0.05, octaves=4, seed=seed)
            
            # Should be identical
            assert np.allclose(noise1, noise2), "Same seed produced different results"
            
            # Generate with different seed
            noise3 = generate_perlin_noise(64, 64, scale=0.05, octaves=4, seed=seed + 1)
            
            # Should be different
            assert not np.allclose(noise1, noise3), "Different seeds produced same results"
            
            self.log_test("Reproducibility", True, "Seeds produce consistent and different results")
            
        except Exception as e:
            self.log_test("Reproducibility", False, "Reproducibility test failed", e)
    
    def run_all_tests(self):
        """Run complete test suite"""
        print("🧪 Starting Tectonic Generator Test Suite...")
        print("=" * 60)
        
        start_time = time.time()
        
        # Core algorithm tests
        print("\n📊 Testing Core Algorithms...")
        self.test_perlin_generation()
        self.test_simplex_generation()
        self.test_worley_generation()
        self.test_parameter_validation()
        self.test_image_processing()
        self.test_reproducibility()
        
        # Performance tests
        print("\n⚡ Testing Performance...")
        self.test_performance_benchmarks()
        
        # API tests
        print("\n🌐 Testing API Endpoints...")
        self.test_api_health()
        self.test_api_parameters()
        self.test_api_perlin_generation()
        self.test_api_simplex_generation()
        self.test_api_worley_generation()
        self.test_api_error_handling()
        
        # Summary
        total_time = time.time() - start_time
        total_tests = len(self.test_results)
        passed_tests = sum(1 for r in self.test_results if r['success'])
        failed_tests = total_tests - passed_tests
        
        print("\n" + "=" * 60)
        print("🏁 TEST SUITE COMPLETE")
        print(f"⏱️  Total Time: {total_time:.2f} seconds")
        print(f"✅ Passed: {passed_tests}/{total_tests}")
        
        if failed_tests > 0:
            print(f"❌ Failed: {failed_tests}/{total_tests}")
            print("\nFailed Tests:")
            for test_name in self.failed_tests:
                print(f"  - {test_name}")
            return False
        else:
            print("🎉 All tests passed!")
            return True

def main():
    """Main test runner"""
    import argparse
    
    parser = argparse.ArgumentParser(description="Tectonic Generator Test Suite")
    parser.add_argument("--api-url", default="http://localhost:5000", 
                       help="Base URL for API tests")
    parser.add_argument("--output", help="JSON output file for results")
    
    args = parser.parse_args()
    
    # Run tests
    suite = TectonicTestSuite(api_base_url=args.api_url)
    success = suite.run_all_tests()
    
    # Save results if requested
    if args.output:
        with open(args.output, 'w') as f:
            json.dump(suite.test_results, f, indent=2)
        print(f"\n📁 Results saved to {args.output}")
    
    # Exit with appropriate code
    sys.exit(0 if success else 1)

if __name__ == "__main__":
    main()