# Telegram News API

A FastAPI application that fetches news from Telegram channels with search capabilities.

## Features

- 🔍 Search messages across multiple Telegram channels
- 📅 Configurable time range (1-365 days)
- 🔎 Case-insensitive keyword search
- 🚀 Fast API responses with concurrent channel fetching
- 🐳 Dockerized with Nginx reverse proxy
- 🔒 Secure headers and proxy configuration

## Quick Start

### Prerequisites

- Docker and Docker Compose installed
- Telegram API credentials (API_ID, API_HASH, SESSION_STRING)

### Quick Installation (One Command)

**From anywhere, run this single command:**

```bash
curl -sSL https://raw.githubusercontent.com/yascheerka/tg-python-news-api/master/install.sh | bash
```

**Or manually:**

1. **Clone and setup:**
   ```bash
   git clone https://github.com/yascheerka/tg-python-news-api.git
   cd tg-python-news-api
   ```

2. **Run the complete setup:**
   ```bash
   ./setup.sh
   ```

The setup script will:
- ✅ Check all prerequisites (Docker, Python)
- ✅ Create virtual environment and install dependencies
- ✅ Guide you through Telegram API setup
- ✅ Generate session string automatically
- ✅ Build and start Docker containers
- ✅ Test the API and provide usage examples

4. **Access the API:**
   - API: http://tg.1488.fun
   - Documentation: http://tg.1488.fun/docs

## API Usage

### Fetch messages from channels

```
GET /fetch?channels=@channel1,@channel2&days=7&q=keyword1,keyword2&limit=100
```

**Parameters:**
- `channels` (required): Comma-separated list of Telegram channels
- `days` (optional): Lookback window in days (default: 7, max: 365)
- `q` (optional): Comma-separated search terms
- `limit` (optional): Max messages per channel (default: all, max: 2000)

### Examples

**Basic fetch:**
```
http://tg.1488.fun/fetch?channels=@WatcherGuru&days=1
```

**With search:**
```
http://tg.1488.fun/fetch?channels=@WatcherGuru,@reuters&days=7&q=Bitcoin,ETH
```

**Limited results:**
```
http://tg.1488.fun/fetch?channels=@WatcherGuru&days=1&limit=50&q=Elon
```

## Docker Commands

```bash
# Start services
docker-compose up -d

# View logs
docker-compose logs -f

# Stop services
docker-compose down

# Rebuild and restart
docker-compose up --build -d
```

## Environment Variables

Create a `.env` file with:

```env
TELEGRAM_API_ID=your_api_id
TELEGRAM_API_HASH=your_api_hash
TELEGRAM_SESSION_STRING=your_session_string
SECRET_KEY=your_secret_key
API_PORT=8080  # Optional: Change the port (default: 80)
```

## Architecture

- **FastAPI**: Python web framework for the API
- **Nginx**: Reverse proxy and load balancer
- **Docker**: Containerization
- **Telethon**: Telegram client library

## Security

- Security headers configured in Nginx
- Environment variable-based configuration
- No sensitive data in code
- Health checks and monitoring

## Monitoring

- Health check endpoint: `/health`
- Container health checks enabled
- Log aggregation in `./logs/`

## Troubleshooting

1. **API not responding**: Check container logs with `docker-compose logs`
2. **Authentication errors**: Verify Telegram credentials in `.env`
3. **Channel access issues**: Ensure the bot/user has access to requested channels
