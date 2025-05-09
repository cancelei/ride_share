# frozen_string_literal: true

begin
  $posthog = PostHog::Client.new(
    api_key: ENV.fetch("POSTHOG_API_KEY"),
    host: ENV.fetch("POSTHOG_HOST", "https://app.posthog.com"),
    on_error: proc { |status, msg| Rails.logger.error("PostHog Error: #{status} - #{msg}") }
  )
  Rails.logger.debug "PostHog initialized successfully"
rescue => e
  Rails.logger.error "Failed to initialize PostHog: #{e.message}"
  Rails.logger.debug e.backtrace.join("\n")
end
