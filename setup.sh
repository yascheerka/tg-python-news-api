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

# Create .env file interactively
if [ ! -f .env ]; then
    print_status "Setting up .env file interactively..."
    echo ""
    print_status "You'll need Telegram API credentials from https://my.telegram.org/apps"
    echo ""
    
    # Get API ID
    while true; do
        read -p "Enter your Telegram API ID: " api_id
        if [[ $api_id =~ ^[0-9]+$ ]]; then
            break
        else
            print_error "API ID must be a number"
        fi
    done
    
    # Get API Hash
    while true; do
        read -p "Enter your Telegram API Hash: " api_hash
        if [[ ${#api_hash} -eq 32 ]]; then
            break
        else
            print_error "API Hash must be 32 characters long"
        fi
    done
    
    # Get Phone Number
    while true; do
        read -p "Enter your phone number (with country code, e.g., +1234567890): " phone
        if [[ $phone =~ ^\+[0-9]+$ ]]; then
            break
        else
            print_error "Phone number must start with + and contain only digits"
        fi
    done
    
    # Get Secret Key
    while true; do
        read -p "Enter a secret key for API access (or press Enter for default '228'): " secret_key
        if [[ -z $secret_key ]]; then
            secret_key="228"
        fi
        if [[ ${#secret_key} -ge 3 ]]; then
            break
        else
            print_error "Secret key must be at least 3 characters long"
        fi
    done
    
    # Get Port
    while true; do
        read -p "Enter API port (or press Enter for default 80): " api_port
        if [[ -z $api_port ]]; then
            api_port="80"
        fi
        if [[ $api_port =~ ^[0-9]+$ ]] && [[ $api_port -ge 1 ]] && [[ $api_port -le 65535 ]]; then
            break
        else
            print_error "Port must be a number between 1 and 65535"
        fi
    done
    
    # Get Domain
    while true; do
        read -p "Enter your domain (or press Enter for localhost): " domain
        if [[ -z $domain ]]; then
            domain="localhost"
        fi
        if [[ $domain =~ ^[a-zA-Z0-9.-]+$ ]]; then
            break
        else
            print_error "Domain must contain only letters, numbers, dots, and hyphens"
        fi
    done
    
    # Create .env file
    cat > .env << EOF
# Telegram API Credentials
TELEGRAM_API_ID=$api_id
TELEGRAM_API_HASH=$api_hash

# Session string (will be generated)
TELEGRAM_SESSION_STRING=

# Phone number for session creation
TELEGRAM_PHONE=$phone

# Secret key for API access
SECRET_KEY=$secret_key

# API Port
API_PORT=$api_port

# Domain
DOMAIN=$domain
EOF
    
    print_success ".env file created successfully!"
    echo ""
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

# Session string generation (manual)
print_status "Session string setup..."
echo ""
print_warning "Session string generation requires interactive input (verification code)"
echo ""
print_info "You can generate the session string manually by running:"
echo "   source venv/bin/activate"
echo "   python3 create_session_string.py"
echo ""
print_warning "Make sure to copy the session string and add it to TELEGRAM_SESSION_STRING in .env"
echo ""

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

# Note about API testing
print_status "API Status..."
print_warning "API test skipped - session string needs to be added to .env first"
print_info "Run 'docker-compose restart' after adding session string to test the API"

# Final status
echo ""
echo "🎉 Setup Complete!"
echo "=================="
print_success "Your Telegram News API setup is complete!"
echo ""
print_warning "⚠️  IMPORTANT: You need to add your session string to .env before the API will work!"
echo ""
echo "📋 Next Steps:"
echo "  1. Generate session string: source venv/bin/activate && python3 create_session_string.py"
echo "  2. Copy the session string and add it to TELEGRAM_SESSION_STRING in .env"
echo "  3. Restart Docker: docker-compose restart"
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
