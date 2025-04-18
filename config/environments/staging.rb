require "active_support/core_ext/integer/time"
require "email_interceptor"

Rails.application.configure do
  # Settings specified here will take precedence over those in config/application.rb.

  # Code is not reloaded between requests.
  config.enable_reloading = false

  # Eager load code on boot for better performance and memory savings (ignored by Rake tasks).
  config.eager_load = true

  # Full error reports are disabled and caching is turned on.
  config.consider_all_requests_local = false
  config.action_controller.perform_caching = true

  # Cache assets for far-future expiry since they are all digest stamped.
  config.public_file_server.headers = { "cache-control" => "public, max-age=#{1.year.to_i}" }

  # Enable serving of images, stylesheets, and JavaScripts from an asset server.
  # config.asset_host = "http://assets.example.com"

  # Store uploaded files on the local file system (see config/storage.yml for options).
  config.active_storage.service = :local

  # Assume all access to the app is happening through a SSL-terminating reverse proxy.
  config.assume_ssl = true

  # Force all access to the app over SSL, use Strict-Transport-Security, and use secure cookies.
  config.force_ssl = true

  # Skip http-to-https redirect for the default health check endpoint.
  # config.ssl_options = { redirect: { exclude: ->(request) { request.path == "/up" } } }

  # Log to STDOUT with the current request id as a default log tag.
  config.log_tags = [ :request_id ]
  config.logger   = ActiveSupport::TaggedLogging.logger(STDOUT)

  # Change to "debug" to log everything (including potentially personally-identifiable information!)
  config.log_level = ENV.fetch("RAILS_LOG_LEVEL", "info")

  # Prevent health checks from clogging up the logs.
  config.silence_healthcheck_path = "/up"

  # Don't log any deprecations.
  config.active_support.report_deprecations = false

  # Replace the default in-process memory cache store with a durable alternative.
  config.cache_store = :memory_store

  # Replace the default in-process and non-durable queuing backend for Active Job.
  config.active_job.queue_adapter = :solid_queue
  config.solid_queue.connects_to = { database: { writing: :queue } }

  # Set delivery method to API
  config.action_mailer.delivery_method = :letter_opener_web

  # Remove any SMTP settings
  # config.action_mailer.smtp_settings = nil

  # Ignore bad email addresses and do not raise email delivery errors
  config.action_mailer.raise_delivery_errors = true
  config.action_mailer.perform_caching = false

  # Set default URL options for your staging environment
  config.action_mailer.default_url_options = { host: ENV.fetch("HOST_URL", "staging.example.com") }

  # Enable locale fallbacks for I18n (makes lookups for any locale fall back to
  # the I18n.default_locale when a translation cannot be found).
  config.i18n.fallbacks = true

  # Do not dump schema after migrations.
  config.active_record.dump_schema_after_migration = false

  # Only use :id for inspections in production.
  config.active_record.attributes_for_inspect = [ :id ]

  # Enable Action Cable in production.
  config.action_cable.url = "wss://staging.rideflow.live/cable"
  config.action_cable.allowed_request_origins = [ "https://staging.rideflow.live" ]

  # Enable DNS rebinding protection and other `Host` header attacks.
  config.hosts = [ "staging.rideflow.live" ]

  # Skip DNS rebinding protection for the default health check endpoint.
  config.host_authorization = { exclude: ->(request) { request.path == "/up" } }

  # Similar to production settings but for staging environment
  config.cache_classes = true
  config.public_file_server.enabled = true
  config.assets.compile = false
  config.action_mailer.perform_deliveries = true
  config.action_mailer.deliver_later_queue_name = :mailers

  # Enable detailed email logging
  config.action_mailer.logger = ActiveSupport::Logger.new(STDOUT)
  config.action_mailer.logger.level = Logger::DEBUG

  # Print deprecation notices to the Rails logger.
  config.active_support.deprecation = :log

  # Enable verbose query logs
  config.active_record.verbose_query_logs = true

  # Enable verbose job logs
  config.active_job.verbose_enqueue_logs = true

  ActionMailer::Base.register_interceptor(EmailInterceptor)
end
