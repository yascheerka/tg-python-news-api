#!/bin/bash

# Telegram News API - Complete Setup Script
# This script sets up the entire project from scratch

set -e  # Exit on any error

echo "🚀 Telegram News API - Complete Setup"
echo "======================================"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if running on macOS
if [[ "$OSTYPE" == "darwin"* ]]; then
    print_status "Detected macOS"
else
    print_warning "This script is optimized for macOS"
fi

# Check prerequisites
print_status "Checking prerequisites..."

# Check if Docker is installed
if ! command -v docker &> /dev/null; then
    print_error "Docker is not installed. Please install Docker Desktop first."
    print_status "Visit: https://www.docker.com/products/docker-desktop"
    exit 1
fi

# Check if Docker Compose is available
if ! docker-compose --version &> /dev/null; then
    print_error "Docker Compose is not available. Please install Docker Desktop."
    exit 1
fi

# Check if Python 3 is installed
if ! command -v python3 &> /dev/null; then
    print_error "Python 3 is not installed. Please install Python 3 first."
    exit 1
fi

print_success "All prerequisites are satisfied!"

# Create project structure
print_status "Setting up project structure..."

# Create necessary directories
mkdir -p logs/nginx
mkdir -p ssl

print_success "Project structure created"

# Create .env file if it doesn't exist
if [ ! -f .env ]; then
    print_status "Creating .env file template..."
    cat > .env << EOF
# Telegram API Credentials
# Get these from https://my.telegram.org/apps
TELEGRAM_API_ID=your_api_id_here
TELEGRAM_API_HASH=your_api_hash_here

# Session string (will be generated)
TELEGRAM_SESSION_STRING=

# Phone number for session creation
TELEGRAM_PHONE=your_phone_number_here

# Secret key for API access
SECRET_KEY=your_secret_key_here

# API Port (default: 80)
API_PORT=80
EOF
    print_warning "Please edit .env file with your Telegram credentials before continuing"
    print_status "You can get API credentials from: https://my.telegram.org/apps"
    echo ""
    read -p "Press Enter when you've updated the .env file..."
fi

# Check if .env has proper values
if grep -q "your_api_id_here" .env; then
    print_error "Please update .env file with your actual Telegram credentials"
    exit 1
fi

# Create virtual environment
print_status "Setting up Python virtual environment..."
python3 -m venv venv
source venv/bin/activate

# Install Python dependencies
print_status "Installing Python dependencies..."
pip install --upgrade pip
pip install -r requierment.txt python-dotenv websockets

print_success "Python dependencies installed"

# Generate session string if not exists
if ! grep -q "TELEGRAM_SESSION_STRING=1B" .env; then
    print_status "Generating Telegram session string..."
    print_warning "You will need to enter your phone number and verification code"
    
    # Run session creation
    python3 create_session_string.py
    
    # Extract session string from output and update .env
    print_status "Updating .env with session string..."
    # This is a simplified approach - in practice, you'd need to parse the output
    print_warning "Please manually copy the session string from above and update .env"
    echo ""
    read -p "Press Enter when you've updated the session string in .env..."
fi

# Build and start Docker containers
print_status "Building and starting Docker containers..."
docker-compose down 2>/dev/null || true
docker-compose up --build -d

# Wait for services to be ready
print_status "Waiting for services to start..."
sleep 10

# Check if services are running
print_status "Checking service status..."
if docker-compose ps | grep -q "Up"; then
    print_success "Docker containers are running!"
else
    print_error "Docker containers failed to start"
    docker-compose logs
    exit 1
fi

# Get the configured port
API_PORT=$(grep API_PORT .env | cut -d'=' -f2 || echo "80")

# Test the API
print_status "Testing API endpoint..."
if curl -s "http://localhost:${API_PORT}/fetch?channels=@WatcherGuru&days=1&limit=1&key=$(grep SECRET_KEY .env | cut -d'=' -f2)" > /dev/null; then
    print_success "API is responding successfully!"
else
    print_warning "API test failed, but containers are running"
fi

# Final status
echo ""
echo "🎉 Setup Complete!"
echo "=================="
print_success "Your Telegram News API is now running!"
echo ""
echo "📋 Quick Reference:"
echo "  • API Base URL: http://localhost:${API_PORT}"
echo "  • API Docs: http://localhost:${API_PORT}/docs"
echo "  • WebSocket: ws://localhost:${API_PORT}/ws"
echo ""
echo "🔧 Management Commands:"
echo "  • View logs: docker-compose logs -f"
echo "  • Stop services: docker-compose down"
echo "  • Restart services: docker-compose restart"
echo "  • Update and restart: docker-compose up --build -d"
echo ""
echo "🌐 Example API calls:"
echo "  • curl 'http://localhost:${API_PORT}/fetch?channels=@WatcherGuru&days=1&key=YOUR_SECRET_KEY'"
echo "  • curl 'http://localhost:${API_PORT}/fetch?channels=@reuters&days=7&q=Bitcoin&key=YOUR_SECRET_KEY'"
echo ""
echo "📡 WebSocket Example:"
echo "  • python3 test_websocket.py"
echo ""
print_success "Setup completed successfully! 🚀"
