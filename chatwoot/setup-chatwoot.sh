#!/bin/bash

set -e

echo "=========================================="
echo "  Chatwoot Local Setup Script"
echo "  For YouTube Educational Content"
echo "=========================================="
echo ""

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Print functions
print_success() {
    echo -e "${GREEN}✓ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠ $1${NC}"
}

print_error() {
    echo -e "${RED}✗ $1${NC}"
    exit 1
}

# Check if Docker is installed
echo "Checking requirements..."
if ! command -v docker &> /dev/null; then
    print_error "Docker is not installed. Please install Docker first: https://docs.docker.com/get-docker/"
fi
print_success "Docker is installed"

# Detect Docker Compose command (v1 uses docker-compose, v2 uses docker compose)
if docker compose version &> /dev/null; then
    DOCKER_COMPOSE="docker compose"
elif command -v docker-compose &> /dev/null; then
    DOCKER_COMPOSE="docker-compose"
else
    print_error "Docker Compose is not available. Please install Docker Compose"
fi
print_success "Docker Compose is installed ($DOCKER_COMPOSE)"

# Stop existing containers if any
echo ""
echo "Cleaning up previous installation (if exists)..."
if [ -f "docker-compose.yaml" ]; then
    $DOCKER_COMPOSE down -v 2>/dev/null || true
    print_success "Previous containers stopped"
fi

# Download official configuration files
echo ""
echo "Downloading Chatwoot configuration files..."

# Download .env.example
if ! curl -fsSL https://raw.githubusercontent.com/chatwoot/chatwoot/develop/.env.example -o .env.example; then
    print_error "Failed to download .env.example"
fi
print_success "Downloaded .env.example"

# Download docker-compose.production.yaml
if ! curl -fsSL https://raw.githubusercontent.com/chatwoot/chatwoot/develop/docker-compose.production.yaml -o docker-compose.yaml; then
    print_error "Failed to download docker-compose.yaml"
fi
print_success "Downloaded docker-compose.yaml"

# Create .env file from .env.example if it doesn't exist
echo ""
echo "Configuring environment variables..."
if [ ! -f ".env" ]; then
    cp .env.example .env

    # Generate SECRET_KEY_BASE
    SECRET_KEY=$(openssl rand -hex 64)

    # Configure essential variables for local development
    sed -i.bak "s|SECRET_KEY_BASE=.*|SECRET_KEY_BASE=${SECRET_KEY}|g" .env
    sed -i.bak "s|FRONTEND_URL=.*|FRONTEND_URL=http://localhost:3000|g" .env
    sed -i.bak "s|REDIS_PASSWORD=.*|REDIS_PASSWORD=redis|g" .env
    sed -i.bak "s|POSTGRES_PASSWORD=.*|POSTGRES_PASSWORD=postgres|g" .env

    # Clean up backup files
    rm -f .env.bak

    print_success ".env file configured"
else
    print_warning ".env file already exists, won't overwrite"
fi

# Update docker-compose.yaml to use standard ports without localhost binding
echo ""
echo "Configuring ports for local development..."
sed -i.bak "s|127.0.0.1:3000:3000|3000:3000|g" docker-compose.yaml
sed -i.bak "s|127.0.0.1:5432:5432|5432:5432|g" docker-compose.yaml
sed -i.bak "s|127.0.0.1:6379:6379|6379:6379|g" docker-compose.yaml
rm -f docker-compose.yaml.bak
print_success "Ports configured (3000, 5432, 6379)"

# Update docker-compose.yaml with PostgreSQL password
echo ""
echo "Updating docker-compose.yaml with PostgreSQL password..."
sed -i.bak "s|POSTGRES_PASSWORD=|POSTGRES_PASSWORD=postgres|g" docker-compose.yaml
rm -f docker-compose.yaml.bak
print_success "PostgreSQL password configured in docker-compose.yaml"

# Pull Docker images
echo ""
echo "Downloading Docker images (this may take a few minutes)..."
$DOCKER_COMPOSE pull
print_success "Images downloaded"

# Start PostgreSQL and Redis first
echo ""
echo "Starting database services..."
$DOCKER_COMPOSE up -d postgres redis
print_success "PostgreSQL and Redis started"

# Wait for PostgreSQL to be ready
echo ""
echo "Waiting for PostgreSQL to be ready..."
echo "This may take 10-15 seconds..."
sleep 10
MAX_TRIES=30
TRIES=0
until $DOCKER_COMPOSE exec -T postgres pg_isready -U postgres > /dev/null 2>&1; do
    TRIES=$((TRIES+1))
    if [ $TRIES -ge $MAX_TRIES ]; then
        print_error "PostgreSQL did not start in time. Check logs with: $DOCKER_COMPOSE logs postgres"
    fi
    echo -n "."
    sleep 1
done
echo ""
print_success "PostgreSQL is ready"

# Prepare the database
echo ""
echo "Preparing database (this may take several minutes)..."
if $DOCKER_COMPOSE run --rm rails bundle exec rails db:chatwoot_prepare; then
    print_success "Database prepared successfully"
else
    print_error "Error preparing database. Check logs with: $DOCKER_COMPOSE logs rails"
fi

# Start all services
echo ""
echo "Starting all Chatwoot services..."
$DOCKER_COMPOSE up -d
print_success "Services started"

# Wait for Rails to be ready
echo ""
echo "Waiting for Chatwoot to be ready..."
sleep 10
for i in {1..30}; do
    if curl -s -o /dev/null -w "%{http_code}" http://localhost:3000/api | grep -q "200"; then
        print_success "Chatwoot is running!"
        break
    fi
    if [ $i -eq 30 ]; then
        print_warning "Chatwoot is taking longer to start. Check logs with: $DOCKER_COMPOSE logs rails"
    fi
    echo -n "."
    sleep 2
done
echo ""

# Display final information
echo ""
echo "=========================================="
echo -e "${GREEN}Installation completed!${NC}"
echo "=========================================="
echo ""
echo "Chatwoot is running at: http://localhost:3000"
echo ""
echo "Useful commands:"
echo "  - View logs:        $DOCKER_COMPOSE logs -f"
echo "  - Stop services:    $DOCKER_COMPOSE stop"
echo "  - Start services:   $DOCKER_COMPOSE start"
echo "  - Restart all:      $DOCKER_COMPOSE restart"
echo "  - Remove all:       $DOCKER_COMPOSE down -v"
echo ""
echo "Default credentials (first time):"
echo "  Email: admin@chatwoot.com"
echo "  Password: (set on first access)"
echo ""
echo "=========================================="
