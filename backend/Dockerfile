FROM python:3.11.9-slim-bullseye

WORKDIR /app

# Install system dependencies including jq for testing
RUN apt-get update && apt-get install -y \
    gcc \
    g++ \
    jq \
    curl \
    && rm -rf /var/lib/apt/lists/*

# Copy requirements first for better caching
COPY requirements.txt .

# Install Python dependencies
RUN pip install --no-cache-dir -r requirements.txt

# Copy application code
COPY . .

# Create data directory
RUN mkdir -p /app/data/exports

# Expose port
EXPOSE 5000

# Run the application
CMD ["python", "app.py"]