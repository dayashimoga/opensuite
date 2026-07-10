# OpenSuite Setup Script for Windows
# Initializes the development environment using Docker

Write-Host "🚀 OpenSuite Development Setup" -ForegroundColor Cyan
Write-Host "================================"

# Check Docker
$docker = Get-Command docker -ErrorAction SilentlyContinue
if (-not $docker) {
    Write-Host "❌ Docker is required but not installed." -ForegroundColor Red
    Write-Host "   Install Docker: https://docs.docker.com/get-docker/"
    exit 1
}

Write-Host "✅ Docker found: $(docker --version)" -ForegroundColor Green

# Build Docker image
Write-Host "`n📦 Building development Docker image..." -ForegroundColor Yellow
docker compose -f docker/docker-compose.yml build dev

Write-Host "`n🔧 Getting dependencies..." -ForegroundColor Yellow
docker compose -f docker/docker-compose.yml run --rm dev bash -c @"
  cd packages/core && flutter pub get &&
  cd ../l10n && flutter pub get &&
  cd ../storage && flutter pub get &&
  cd ../ui_kit && flutter pub get &&
  cd ../../apps/opensuite && flutter pub get
"@

Write-Host "`n✅ Setup complete!" -ForegroundColor Green
Write-Host "`nAvailable commands:"
Write-Host "  docker compose -f docker/docker-compose.yml run --rm test       # Run tests"
Write-Host "  docker compose -f docker/docker-compose.yml run --rm lint       # Run analysis"
Write-Host "  docker compose -f docker/docker-compose.yml run --rm format     # Check formatting"
Write-Host "  docker compose -f docker/docker-compose.yml run --rm build-web  # Build web"
Write-Host "  docker compose -f docker/docker-compose.yml run --rm dev        # Interactive shell"
