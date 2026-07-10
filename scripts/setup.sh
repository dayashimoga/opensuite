#!/bin/bash
# OpenSuite - Setup Script
# Initializes the development environment using Docker

set -e

echo "🚀 OpenSuite Development Setup"
echo "================================"

# Check Docker
if ! command -v docker &> /dev/null; then
    echo "❌ Docker is required but not installed."
    echo "   Install Docker: https://docs.docker.com/get-docker/"
    exit 1
fi

echo "✅ Docker found: $(docker --version)"

# Check Docker Compose
if ! docker compose version &> /dev/null; then
    echo "❌ Docker Compose is required but not available."
    exit 1
fi

echo "✅ Docker Compose found"

# Build Docker image
echo ""
echo "📦 Building development Docker image..."
docker compose -f docker/docker-compose.yml build dev

echo ""
echo "🔧 Getting dependencies..."
docker compose -f docker/docker-compose.yml run --rm dev bash -c "
  cd packages/core && flutter pub get &&
  cd ../l10n && flutter pub get &&
  cd ../storage && flutter pub get &&
  cd ../ui_kit && flutter pub get &&
  cd ../../apps/opensuite && flutter pub get
"

echo ""
echo "✅ Setup complete!"
echo ""
echo "Available commands:"
echo "  docker compose -f docker/docker-compose.yml run --rm test    # Run tests"
echo "  docker compose -f docker/docker-compose.yml run --rm lint    # Run analysis"
echo "  docker compose -f docker/docker-compose.yml run --rm format  # Check formatting"
echo "  docker compose -f docker/docker-compose.yml run --rm build-web    # Build web"
echo "  docker compose -f docker/docker-compose.yml run --rm build-android # Build Android"
echo "  docker compose -f docker/docker-compose.yml run --rm dev     # Interactive shell"
