# RideFlow - Community Ride Sharing Platform

A modern, community-powered ride-sharing platform built with Ruby on Rails. RideFlow enables passengers to request rides, drivers to offer services, and companies/event organizers to manage transportation fleets.

## 🚗 Overview

RideFlow is designed for communities, events, and organizations that need flexible transportation solutions. It features:

- **Multi-role system**: Passengers, Drivers, Companies, and Admins
- **Real-time tracking**: Live GPS location updates
- **Crypto payments**: Bitcoin, Ethereum, and ICC support
- **Fleet management**: Companies can manage driver pools
- **Reporting**: Tax and managerial reports

## 🚀 Quick Start

### Prerequisites
- Ruby 3.2+
- PostgreSQL
- Node.js & Yarn

### Setup
```bash
bin/setup
```

### Start Development Server
```bash
bin/dev
```

### Start Background Jobs
```bash
bin/rails solid_queue:work
```

## 🛠 Commands

### Testing
```bash
# Run all tests
bin/rails test

# Run single test file
bin/rails test TEST=test/models/ride_test.rb

# Run specific test (line number)
bin/rails test TEST=test/models/ride_test.rb:42

# System tests
bin/rails test:system
```

### Linting & Security
```bash
# Run RuboCop
bin/rubocop

# Auto-fix issues
bin/rubocop -a

# Security scanning
bin/brakeman
```

## 👥 User Roles

| Role | Description |
|------|-------------|
| **Passenger** | Request rides, track status, rate drivers |
| **Driver** | Accept rides, manage vehicles, earn money |
| **Company** | Manage driver fleet, view analytics, generate reports |
| **Admin** | System administration, user management |

## 📱 Key Features

### For Passengers
- Request rides with Google Places autocomplete
- Real-time ride tracking
- Price estimation before booking
- Security code verification
- Driver ratings and reviews

### For Drivers
- Accept pending rides
- Multiple vehicle registration
- Real-time GPS tracking
- Earnings dashboard
- Crypto payment addresses

### For Companies/Event Organizers
- Driver fleet management
- Performance analytics
- Financial summaries
- Tax and managerial reports
- Real-time operations dashboard

### For Admins
- User management
- Ride monitoring
- Revenue tracking
- Background job management (SolidQueue)

## 🔧 Configuration

### Required Environment Variables
```bash
GOOGLE_MAPS_API_KEY=     # Maps, Places, Distance Matrix APIs
BREVO_API_KEY=           # Email service
DATABASE_URL=            # PostgreSQL connection
SECRET_KEY_BASE=         # Rails encryption key
```

### Optional Services
```bash
POSTHOG_API_KEY=         # Analytics (optional)
```

## 📚 Documentation

- [Feature Review](doc/FEATURE_REVIEW.md) - Comprehensive feature analysis
- [API Documentation](doc/API.md) - REST API endpoints (if available)

## 🏗 Tech Stack

- **Backend**: Ruby on Rails 8.0
- **Database**: PostgreSQL
- **Background Jobs**: SolidQueue
- **WebSockets**: SolidCable
- **Frontend**: Hotwire (Turbo + Stimulus), Tailwind CSS
- **Maps**: Google Maps Platform
- **Email**: Brevo (Sendinblue)
- **Auth**: Devise

## 📊 Code Style

- Ruby: Rubocop Rails Omakase
- 2 spaces indentation
- Single quotes (unless interpolation)
- snake_case for methods/variables
- CamelCase for classes/modules

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Run tests: `bin/rails test`
4. Run linter: `bin/rubocop`
5. Submit a pull request

## 📄 License

[Add license information here]

---

Built with ❤️ for community-powered transportation
