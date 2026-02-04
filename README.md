# RideFlow - Ride Sharing Platform

RideFlow is an open-source ride-sharing platform built with Ruby on Rails 8. It enables passengers to request rides and drivers to accept and complete them, with built-in payment tracking, real-time notifications, and comprehensive reporting.

## ✨ Features

### For Passengers
- 📍 Location-based ride requests with Google Maps integration
- 🗺️ Select pickup/dropoff by address search or map pindrop
- 🔐 Security code verification for safe ride starts
- 📧 Email notifications for ride status updates
- ⭐ Rate your driver after completed rides
- 📱 Mobile-responsive design

### For Drivers
- 🚗 Accept available ride requests
- 🧭 Turn-by-turn navigation via Google Maps
- 💰 Crypto payment address display (Bitcoin, Ethereum, ICC)
- 📊 Earnings tracking and reports
- ⏰ 3-minute waiting timer at pickup
- 🚫 Ride cancellation with restrictions (not within 4 hours)

### For Companies
- 👥 Manage driver fleet
- 📈 View company-wide statistics
- 📋 Managerial reports with PDF export
- 🏢 Multi-driver support

### For Admins
- 👤 User management (create, edit, deactivate, restore)
- 🔑 Role management (admin, driver, passenger, company)
- 🏢 Company profile management
- 📊 Access to all reports

## 🚀 Getting Started

### Prerequisites

- Ruby 3.2.1
- PostgreSQL 14+
- Node.js 18+
- Google Maps API key
- Brevo (Sendinblue) API key for emails

### Quick Setup

```bash
# Clone the repository
git clone https://github.com/cancelei/ride_share.git
cd ride_share

# Install dependencies
bundle install

# Set up the database
bin/rails db:prepare

# Start the development server
bin/dev
```

### Environment Variables

Create a `.env` file with:

```bash
GOOGLE_MAPS_API_KEY=your_key_here
BREVO_API_KEY=your_key_here
POSTHOG_API_KEY=your_key_here  # Optional, for analytics
```

## 📖 Documentation

- [Self-Hosting Guide](SELF_HOSTING.md) - Complete guide for deploying RideFlow on your own infrastructure
- [Development Guide](CLAUDE.md) - Guidelines for development and code contributions

## 🛠️ Tech Stack

- **Framework**: Ruby on Rails 8.0
- **Frontend**: Hotwire (Turbo + Stimulus), Tailwind CSS
- **Database**: PostgreSQL
- **Background Jobs**: Solid Queue
- **WebSockets**: Solid Cable
- **Caching**: Solid Cache
- **Maps**: Google Maps Platform
- **Email**: Brevo (Sendinblue)
- **PDF Generation**: Grover (Puppeteer/Chrome)
- **Deployment**: Docker, Kamal

## 📋 Commands Reference

```bash
# Start development server
bin/dev

# Run tests
bin/rails test

# Run linter
bin/rubocop

# Security scan
bin/brakeman

# Background jobs (if not using SOLID_QUEUE_IN_PUMA)
bin/rails solid_queue:start
```

## 🤝 Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add some amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## 📄 License

This project is open source. See the repository for license details.

## 🐛 Issues

Found a bug or have a feature request? Please open an issue:
https://github.com/cancelei/ride_share/issues

## 📞 Support

For questions about self-hosting or deployment, see the [Self-Hosting Guide](SELF_HOSTING.md).

