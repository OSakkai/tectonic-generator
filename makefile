# Tectonic Generator Test Makefile
# Provides convenient commands for testing and development

.PHONY: help test test-quick test-backend test-frontend test-performance clean setup docker-up docker-down logs

# Default target
help:
	@echo "🧪 Tectonic Generator Test Commands"
	@echo "==================================="
	@echo ""
	@echo "Setup Commands:"
	@echo "  make setup          - Install dependencies and prepare environment"
	@echo "  make docker-up      - Start Docker containers"
	@echo "  make docker-down    - Stop Docker containers"
	@echo ""
	@echo "Test Commands:"
	@echo "  make test           - Run complete test suite"
	@echo "  make test-quick     - Run quick validation tests"
	@echo "  make test-backend   - Run backend tests only"
	@echo "  make test-frontend  - Run frontend tests only"
	@echo "  make test-performance - Run performance tests only"
	@echo ""
	@echo "Development Commands:"
	@echo "  make logs           - Show Docker container logs"
	@echo "  make clean          - Clean test artifacts"
	@echo "  make status         - Show system status"
	@echo ""

# Setup development environment
setup:
	@echo "🔧 Setting up Tectonic Generator development environment..."
	@chmod +x test_runner.sh
	@chmod +x quick_test.sh
	@mkdir -p test_results
	@echo "✅ Setup complete!"

# Start Docker containers
docker-up:
	@echo "🐳 Starting Docker containers..."
	@docker-compose up -d
	@echo "⏳ Waiting for services to start..."
	@sleep 15
	@echo "✅ Containers started!"

# Stop Docker containers
docker-down:
	@echo "🛑 Stopping Docker containers..."
	@docker-compose down
	@echo "✅ Containers stopped!"

# Run complete test suite
test: docker-up
	@echo "🧪 Running complete test suite..."
	@./test_runner.sh
	@echo "🏁 Test suite complete!"

# Run quick tests
test-quick: docker-up
	@echo "⚡ Running quick tests..."
	@./quick_test.sh
	@echo "🏁 Quick tests complete!"

# Run backend tests only
test-backend: docker-up
	@echo "🔧 Running backend tests..."
	@./test_runner.sh --backend-only
	@echo "🏁 Backend tests complete!"

# Run frontend tests only
test-frontend: docker-up
	@echo "🖥️ Running frontend tests..."
	@./test_runner.sh --frontend-only
	@echo "🏁 Frontend tests complete!"

# Run performance tests only
test-performance: docker-up
	@echo "⚡ Running performance tests..."
	@./test_runner.sh --performance
	@echo "🏁 Performance tests complete!"

# Show container logs
logs:
	@echo "📋 Docker container logs:"
	@echo "=========================="
	@echo ""
	@echo "Backend logs:"
	@docker-compose logs backend | tail -20
	@echo ""
	@echo "Frontend logs:"
	@docker-compose logs frontend | tail -20

# Show system status
status:
	@echo "📊 Tectonic Generator System Status"
	@echo "===================================="
	@echo ""
	@echo "Docker containers:"
	@docker ps --filter "name=tectonic" --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"
	@echo ""
	@echo "Backend health:"
	@curl -s http://localhost:5000/api/health 2>/dev/null | jq '.data.status // "Not responding"' || echo "Backend not responding"
	@echo ""
	@echo "Test results directory:"
	@ls -la test_results/ 2>/dev/null || echo "No test results yet"

# Clean test artifacts
clean:
	@echo "🧹 Cleaning test artifacts..."
	@rm -rf test_results/*
	@rm -f /tmp/tectonic_test_*
	@docker system prune -f > /dev/null 2>&1 || true
	@echo "✅ Cleanup complete!"

# Development shortcuts
dev-start: docker-up status
	@echo "🚀 Development environment ready!"
	@echo ""
	@echo "Backend: http://localhost:5000"
	@echo "Frontend: http://localhost:3000"
	@echo ""
	@echo "Run 'make test-quick' to validate setup"

dev-stop: docker-down clean
	@echo "🛑 Development environment stopped!"

# Test specific algorithm
test-perlin:
	@echo "🌊 Testing Perlin algorithm..."
	@curl -s -H "Content-Type: application/json" -d '{"width":128,"height":128,"scale":0.05,"octaves":4,"seed":12345}' http://localhost:5000/api/noise/perlin | jq '.success // false'

test-simplex:
	@echo "🌋 Testing Simplex algorithm..."
	@curl -s -H "Content-Type: application/json" -d '{"width":128,"height":128,"scale":0.02,"octaves":5,"seed":12345}' http://localhost:5000/api/noise/simplex | jq '.success // false'

test-worley:
	@echo "🧩 Testing Worley algorithm..."
	@curl -s -H "Content-Type: application/json" -d '{"width":128,"height":128,"frequency":0.1,"distance_function":"euclidean","cell_type":"F1","seed":12345}' http://localhost:5000/api/noise/worley | jq '.success // false'