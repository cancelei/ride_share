# Self-Hosting RideFlow

This guide provides comprehensive instructions for self-hosting RideFlow, a ride-sharing application built with Ruby on Rails 8.

## Table of Contents

- [Requirements](#requirements)
- [Quick Start with Docker](#quick-start-with-docker)
- [Manual Installation](#manual-installation)
- [Environment Variables](#environment-variables)
- [Third-Party Services](#third-party-services)
- [Deployment Options](#deployment-options)
- [Database Setup](#database-setup)
- [Background Jobs](#background-jobs)
- [SSL/HTTPS Setup](#sslhttps-setup)
- [Troubleshooting](#troubleshooting)

## Requirements

### System Requirements
- Ruby 3.2.1
- PostgreSQL 14+
- Node.js 18+ (for asset compilation)
- Google Chrome or Chromium (for PDF generation)

### Hardware Recommendations
- **Minimum**: 1 CPU core, 1GB RAM, 10GB storage
- **Recommended**: 2+ CPU cores, 2GB+ RAM, 20GB+ storage

## Quick Start with Docker

The easiest way to self-host RideFlow is using Docker.

### 1. Build the Docker Image

```bash
docker build -t rideflow .
```

### 2. Run with Docker Compose

Create a `docker-compose.yml` file:

```yaml
version: '3.8'

services:
  app:
    build: .
    ports:
      - "3000:80"
    environment:
      - RAILS_ENV=production
      - RAILS_MASTER_KEY=${RAILS_MASTER_KEY}
      - DATABASE_URL=postgresql://postgres:password@db:5432/rideflow_production
      - GOOGLE_MAPS_API_KEY=${GOOGLE_MAPS_API_KEY}
      - BREVO_API_KEY=${BREVO_API_KEY}
      - POSTHOG_API_KEY=${POSTHOG_API_KEY}
      - APP_HOST=your-domain.com
      - SOLID_QUEUE_IN_PUMA=true
    depends_on:
      - db
    volumes:
      - storage:/rails/storage

  db:
    image: postgres:15
    environment:
      - POSTGRES_PASSWORD=password
      - POSTGRES_DB=rideflow_production
    volumes:
      - postgres_data:/var/lib/postgresql/data

volumes:
  storage:
  postgres_data:
```

### 3. Start the Application

```bash
# Set your master key
export RAILS_MASTER_KEY=$(cat config/master.key)

# Start the services
docker-compose up -d

# Run database migrations
docker-compose exec app bin/rails db:prepare
```

## Manual Installation

### 1. Clone the Repository

```bash
git clone https://github.com/cancelei/ride_share.git
cd ride_share
```

### 2. Install Dependencies

```bash
# Install Ruby dependencies
bundle install

# Install Node.js dependencies (if applicable)
yarn install
```

### 3. Configure the Database

Copy and edit the database configuration:

```bash
# Edit config/database.yml for your PostgreSQL setup
# The production section uses DATABASE_URL environment variable
```

### 4. Set Up Environment Variables

Create a `.env` file (see [Environment Variables](#environment-variables) section).

### 5. Prepare the Database

```bash
RAILS_ENV=production bin/rails db:prepare
```

### 6. Precompile Assets

```bash
RAILS_ENV=production bin/rails assets:precompile
```

### 7. Start the Application

```bash
# Start the web server
RAILS_ENV=production bin/rails server

# In a separate process, start the background job worker
RAILS_ENV=production bin/rails solid_queue:start
```

## Environment Variables

Create a `.env` file with the following variables:

```bash
# Required
RAILS_MASTER_KEY=your_master_key_here
DATABASE_URL=postgresql://user:password@localhost:5432/rideflow_production
RAILS_ENV=production

# Google Maps (required for map functionality)
GOOGLE_MAPS_API_KEY=your_google_maps_api_key
GOOGLE_MAPS_MAP_ID=your_map_id  # Optional, has default

# Email Service (required for notifications)
BREVO_API_KEY=your_brevo_api_key
MAILER_FROM=no-reply@your-domain.com

# Analytics (optional)
POSTHOG_API_KEY=your_posthog_api_key
POSTHOG_HOST=https://app.posthog.com

# Application Host
APP_HOST=your-domain.com
HOST_URL=your-domain.com

# Performance Tuning (optional)
WEB_CONCURRENCY=2
RAILS_MAX_THREADS=5
RAILS_LOG_LEVEL=info

# Background Jobs
SOLID_QUEUE_IN_PUMA=true  # Run jobs in the web process (single server)

# PDF Generation (optional)
GOOGLE_CHROME_SHIM=/usr/bin/google-chrome-stable
CHROME_PUPPETEER_ARGS=--disable-gpu,--disable-dev-shm-usage
```

### Generating a Master Key

If you don't have a `config/master.key`:

```bash
# This will create config/master.key and config/credentials.yml.enc
EDITOR="nano" bin/rails credentials:edit
```

**Important**: Keep your `master.key` secret and backed up. Never commit it to version control.

## Third-Party Services

### Google Maps Platform (Required)

RideFlow uses Google Maps for:
- Location autocomplete
- Route calculation
- Distance and duration estimation
- Map display

**Setup Steps:**
1. Go to [Google Cloud Console](https://console.cloud.google.com/)
2. Create a new project or select an existing one
3. Enable the following APIs:
   - Maps JavaScript API
   - Places API
   - Directions API
   - Distance Matrix API
   - Geocoding API
4. Create an API key and restrict it to your domain
5. Set the `GOOGLE_MAPS_API_KEY` environment variable

### Brevo (Email Service)

RideFlow uses Brevo (formerly Sendinblue) for transactional emails.

**Setup Steps:**
1. Sign up at [Brevo](https://www.brevo.com/)
2. Go to SMTP & API settings
3. Generate an API key
4. Set the `BREVO_API_KEY` environment variable

**Alternative**: You can modify the mailer configuration in `config/environments/production.rb` to use another SMTP service.

### PostHog (Analytics - Optional)

RideFlow uses PostHog for product analytics.

**Setup Steps:**
1. Sign up at [PostHog](https://posthog.com/)
2. Get your project API key
3. Set the `POSTHOG_API_KEY` environment variable

## Deployment Options

### Option 1: Kamal (Recommended)

RideFlow includes Kamal deployment configuration.

1. Edit `config/deploy.yml` with your server details
2. Set up `.kamal/secrets` with your secrets
3. Deploy:

```bash
bin/kamal setup
bin/kamal deploy
```

### Option 2: Traditional VPS/Server

1. Set up a Linux server (Ubuntu 22.04 recommended)
2. Install PostgreSQL, Ruby, and Node.js
3. Use a process manager like systemd or PM2
4. Set up Nginx as a reverse proxy

Example systemd service (`/etc/systemd/system/rideflow.service`):

```ini
[Unit]
Description=RideFlow Web Server
After=network.target

[Service]
Type=simple
User=deploy
WorkingDirectory=/var/www/rideflow
Environment=RAILS_ENV=production
ExecStart=/var/www/rideflow/bin/rails server -p 3000
Restart=always

[Install]
WantedBy=multi-user.target
```

### Option 3: Platform as a Service

RideFlow can be deployed to:
- **Render**: Use the included `Procfile`
- **Heroku**: Requires PostgreSQL addon
- **Railway**: Direct deployment from Git
- **Fly.io**: Use the Dockerfile

## Database Setup

### Multiple Database Architecture

RideFlow uses Rails 8's multiple database feature:
- **Primary**: Main application data
- **Cache**: Solid Cache (application caching)
- **Queue**: Solid Queue (background jobs)
- **Cable**: Solid Cable (WebSocket/Action Cable)

For production, you can either:
1. Use a single PostgreSQL instance with multiple databases
2. Use separate database instances for better performance

### Database Migrations

```bash
# Run all migrations
RAILS_ENV=production bin/rails db:prepare

# Or manually:
RAILS_ENV=production bin/rails db:migrate
RAILS_ENV=production bin/rails db:migrate:cache
RAILS_ENV=production bin/rails db:migrate:queue
RAILS_ENV=production bin/rails db:migrate:cable
```

## Background Jobs

RideFlow uses Solid Queue for background jobs (email notifications, etc.).

### Running as a Separate Process

```bash
RAILS_ENV=production bin/rails solid_queue:start
```

### Running Inside Puma (Single Server)

Set the environment variable:
```bash
SOLID_QUEUE_IN_PUMA=true
```

### Monitoring Jobs

Access the Solid Queue web UI at `/solid_queue` (admin users only in production).

## SSL/HTTPS Setup

### Using Kamal with Let's Encrypt

The included `config/deploy.yml` has SSL enabled by default using Kamal's built-in proxy.

### Using Nginx

Example Nginx configuration with Let's Encrypt:

```nginx
server {
    listen 80;
    server_name your-domain.com;
    return 301 https://$server_name$request_uri;
}

server {
    listen 443 ssl http2;
    server_name your-domain.com;

    ssl_certificate /etc/letsencrypt/live/your-domain.com/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/your-domain.com/privkey.pem;

    location / {
        proxy_pass http://127.0.0.1:3000;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }

    # WebSocket support for Turbo Streams
    location /cable {
        proxy_pass http://127.0.0.1:3000/cable;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
        proxy_set_header Host $host;
    }
}
```

## User Roles

RideFlow supports the following user roles:
- **Admin** (role: 0): Full access, user management, reports
- **Driver** (role: 1): Accept rides, manage vehicle, view earnings
- **Passenger** (role: 2): Request rides, rate drivers
- **Company** (role: 3): Manage drivers, view company statistics

### Creating an Admin User

After deployment, create an admin user via Rails console:

```bash
RAILS_ENV=production bin/rails console
```

```ruby
User.create!(
  email: 'admin@example.com',
  password: 'secure_password',
  password_confirmation: 'secure_password',
  first_name: 'Admin',
  last_name: 'User',
  role: :admin,
  phone_number: '+1234567890',
  country: 'US'
)
```

## Troubleshooting

### Common Issues

**Assets not loading:**
```bash
RAILS_ENV=production bin/rails assets:precompile
RAILS_ENV=production bin/rails assets:clean
```

**Database connection errors:**
- Verify `DATABASE_URL` is correct
- Ensure PostgreSQL is running
- Check firewall rules

**Email not sending:**
- Verify `BREVO_API_KEY` is set
- Check Rails logs for mailer errors
- Verify email templates exist

**Maps not working:**
- Verify `GOOGLE_MAPS_API_KEY` is set
- Check API key restrictions in Google Cloud Console
- Ensure required APIs are enabled

**PDF generation failing:**
- Ensure Chrome/Chromium is installed
- Set `GOOGLE_CHROME_SHIM` to Chrome binary path
- Check Chrome can run headless

### Viewing Logs

```bash
# Production logs
tail -f log/production.log

# With Docker
docker-compose logs -f app

# With Kamal
bin/kamal logs
```

### Health Check

RideFlow provides a health check endpoint at `/up` that returns:
- `200 OK` when the application is healthy
- `500 Error` when there are issues

## Support

For issues and feature requests, please visit:
https://github.com/cancelei/ride_share/issues

## License

Please refer to the LICENSE file in the repository for licensing information.
