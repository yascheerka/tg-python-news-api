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

### Deployment

1. **Clone and setup:**
   ```bash
   git clone <repository>
   cd <repository>
   ```

2. **Configure environment:**
   ```bash
   # Copy your .env file with Telegram credentials
   cp .env.example .env
   # Edit .env with your actual credentials
   ```

3. **Deploy:**
   ```bash
   ./deploy.sh
   ```

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
