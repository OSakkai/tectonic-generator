#!/bin/bash

# Frontend Status Check Script

echo "🖥️  FRONTEND STATUS CHECK"
echo "========================"

# Check if frontend container is running
echo -n "Container Status: "
if docker ps | grep -q "tectonic_frontend"; then
    echo "✅ Running"
else
    echo "❌ Not Running"
    echo "Starting frontend container..."
    docker-compose up -d frontend
    sleep 10
fi

# Check frontend accessibility
echo -n "HTTP Accessibility: "
if curl -s --max-time 5 http://localhost:3000 > /dev/null 2>&1; then
    echo "✅ Accessible"
else
    echo "❌ Not Accessible"
fi

# Check React App Response
echo -n "React App Response: "
frontend_response=$(curl -s --max-time 5 http://localhost:3000 2>/dev/null || echo "")
if echo "$frontend_response" | grep -q "react\|React\|root"; then
    echo "✅ React App Detected"
else
    echo "⚠️  Basic Response (may need React implementation)"
fi

# Check if it's connecting to backend
echo -n "Backend Connection: "
if echo "$frontend_response" | grep -q "Tectonic\|tectonic\|noise"; then
    echo "✅ Tectonic App Detected"
else
    echo "⚠️  May need backend integration"
fi

echo ""
echo "FRONTEND ANALYSIS:"
echo "=================="

if [ -n "$frontend_response" ]; then
    if echo "$frontend_response" | grep -q "<!DOCTYPE html>"; then
        echo "✅ Valid HTML response"
        if echo "$frontend_response" | grep -q "Tectonic"; then
            echo "✅ Tectonic-specific content found"
        else
            echo "⚠️  Generic content - may need Tectonic implementation"
        fi
    else
        echo "❌ Invalid HTML response"
    fi
else
    echo "❌ No response from frontend"
fi

# Check container logs for errors
echo ""
echo "FRONTEND CONTAINER LOGS (last 10 lines):"
echo "========================================"
docker logs tectonic_frontend --tail 10 2>/dev/null || echo "No logs available"