#!/bin/bash

# One-liner Telegram News API Installer
# Run this from anywhere to install the complete project

set -e

echo "🚀 Installing Telegram News API..."

# Clone the repository
if [ ! -d "tg-python-news-api" ]; then
    git clone https://github.com/yascheerka/tg-python-news-api.git
fi

cd tg-python-news-api

# Run the setup script
./setup.sh

echo "✅ Installation complete! Your API is running at http://localhost"
