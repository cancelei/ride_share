# Ride Flow - Network State Apps

A Ruby on Rails application that helps you find the best ride for your trips, it has an extensive roadmap that could be already implemented without any updates on the readme.

[![MIT License](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)

## Quick Start 🚀

Configure Ruby envieroment with asdf or rbenv and install the correct version by looking at the .tool-versions or ruby-version file.

1. Clone the repository:
   ```bash
   git clone https://github.com/yourusername/your-project-name.git
   cd your-project-name
   ```

2. Install dependencies:
   ```bash
   bin/setup
   ```

3. Open your browser and navigate to `http://localhost:3000` to see the application in action.

## Project Structure 📂

The project is organized into the following directories:

- `app/`: Contains the main application files.
- `config/`: Contains the configuration files.
- `db/`: Contains the database files.
- `lib/`: Contains the custom libraries.
- `public/`: Contains the public files.
- `spec/`: Contains the test files.
- `vendor/`: Contains the vendor files.

## Configuration 🔧

The configuration is done in the `config/application.rb` file.

## Database 🗄️

The database is created using the `rails db:prepare` command.

## Testing 🧪

The tests are run using the `rails test` command.

## Deployment 📦

The application is deployed using the `heroku` command.

Migrate in production:

```bash
heroku run rails db:migrate --app your-app-name
```

Or act accordingly when using other hosting providers.

## Contributing 🤝

## License 📝

This project is licensed under the MIT License. See the [LICENSE](LICENSE) file for details.
