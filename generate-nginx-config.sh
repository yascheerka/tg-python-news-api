#!/bin/bash

# Generate nginx.conf from template with environment variables
set -e

# Load environment variables
if [ -f .env ]; then
    export $(cat .env | grep -v '^#' | xargs)
fi

# Set defaults
DOMAIN=${DOMAIN:-localhost}
API_PORT=${API_PORT:-80}

# Generate nginx.conf from template
envsubst '${DOMAIN}' < nginx.conf.template > nginx.conf

echo "✅ Generated nginx.conf with DOMAIN=$DOMAIN"
