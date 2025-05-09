# config/initializers/grover.rb
Grover.configure do |config|
  config.options = {
    # Path to Chrome binary (set via env var in production)
    executable_path: ENV.fetch("GOOGLE_CHROME_SHIM", "/usr/bin/google-chrome-stable"),
    headless: true,
    # Puppeteer launch args (override via CHROME_PUPPETEER_ARGS env var)
    args: ENV.fetch("CHROME_PUPPETEER_ARGS", "--disable-gpu,--disable-dev-shm-usage").split(","),
    # Production-ready defaults
    default_viewport: { width: 1280, height: 800 },
    timeout: 300_000,
    launch_args: ['--no-sandbox', '--disable-setuid-sandbox']
  }
end
