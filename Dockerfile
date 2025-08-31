FROM python:3.11-slim

WORKDIR /app

# Install system dependencies
RUN apt-get update && apt-get install -y \
    gcc \
    && rm -rf /var/lib/apt/lists/*

# Copy requirements and install Python dependencies
COPY requierment.txt .
RUN pip install --no-cache-dir -r requierment.txt python-dotenv

# Copy application code
COPY pull_news_api.py .
COPY .env .

# Expose port
EXPOSE 8000

# Run the application
CMD ["uvicorn", "pull_news_api:app", "--host", "0.0.0.0", "--port", "8000"]
