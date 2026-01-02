# Chatwoot Local Setup

Automated setup script for running Chatwoot locally using Docker. Perfect for educational content and local development.

## Prerequisites

- **Docker**: Version 20.10.10 or higher
- **Docker Compose**: V2.14.1 or higher

[Install Docker](https://docs.docker.com/get-docker/)

## Quick Start

Run the automated setup script:

```bash
./setup-chatwoot.sh
```

That's it! The script will:
1. Download official Chatwoot configuration files
2. Configure environment variables
3. Set up database and services
4. Launch Chatwoot on http://localhost:3000

## What Gets Installed

The script sets up the following services:

- **Chatwoot Rails**: Main application (port 3000)
- **Sidekiq**: Background job processor
- **PostgreSQL**: Database (port 5432)
- **Redis**: Cache and message broker (port 6379)

## First Time Access

1. Open http://localhost:3000 in your browser
2. Create your admin account on first access
3. Start using Chatwoot!

## Useful Commands

```bash
# View logs
docker compose logs -f

# View logs for specific service
docker compose logs -f rails

# Stop all services
docker compose stop

# Start all services
docker compose start

# Restart all services
docker compose restart

# Stop and remove all containers and volumes
docker compose down -v
```

## Troubleshooting

### Services won't start
Check the logs:
```bash
docker compose logs rails
docker compose logs postgres
```

### Reset everything
```bash
docker compose down -v
./setup-chatwoot.sh
```

### Port conflicts
If ports 3000, 5432, or 6379 are already in use, stop the conflicting services first:
```bash
# Check what's using a port (example for 3000)
lsof -i :3000

# Or on Linux
netstat -tuln | grep 3000
```

## Configuration

After running the setup script, you can customize settings in:
- `.env`: Environment variables
- `docker-compose.yaml`: Docker services configuration

See [Chatwoot Environment Variables](https://www.chatwoot.com/docs/environment-variables) for all available options.

## For YouTube Content

This setup is designed for educational purposes:
- Uses default ports (3000, 5432, 6379)
- Includes example configuration
- Pre-configured for local development
- Easy to reset and start over

## Documentation

- [Official Chatwoot Docs](https://www.chatwoot.com/help-center)
- [Self-Hosted Deployment Guide](https://developers.chatwoot.com/self-hosted)
- [Environment Variables](https://www.chatwoot.com/docs/environment-variables)

## License

This setup script is provided as-is for educational purposes. Chatwoot is licensed under the MIT License.
