#!/bin/bash

# Telegram News API Deployment Script
echo "🚀 Deploying Telegram News API"

# Check if .env file exists
if [ ! -f .env ]; then
    echo "❌ Error: .env file not found!"
    echo "Please create a .env file with your Telegram API credentials:"
    echo "TELEGRAM_API_ID=your_api_id"
    echo "TELEGRAM_API_HASH=your_api_hash"
    echo "TELEGRAM_SESSION_STRING=your_session_string"
    exit 1
fi

# Create logs directory
mkdir -p logs/nginx

# Create SSL directory (for future HTTPS setup)
mkdir -p ssl

# Stop existing containers
echo "🛑 Stopping existing containers..."
docker-compose down

# Build and start containers
echo "🔨 Building and starting containers..."
docker-compose up --build -d

# Wait for services to be ready
echo "⏳ Waiting for services to be ready..."
sleep 10

# Check if services are running
echo "🔍 Checking service status..."
docker-compose ps

# Test the API
echo "🧪 Testing API endpoint..."
curl -s http://localhost/fetch?channels=@WatcherGuru&days=1&limit=1 > /dev/null
if [ $? -eq 0 ]; then
    echo "✅ API is responding successfully!"
    # Get domain from .env
    DOMAIN=$(grep DOMAIN .env | cut -d'=' -f2 || echo "localhost")
    echo "🌐 Your API is now available at: http://$DOMAIN"
    echo "📖 API documentation: http://$DOMAIN/docs"
else
    echo "❌ API test failed. Check logs with: docker-compose logs"
fi

echo "🎉 Deployment complete!"
