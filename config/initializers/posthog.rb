# frozen_string_literal: true

if ENV["POSTHOG_API_KEY"].present?
  PostHogClient = PostHog::Client.new(api_key: ENV["POSTHOG_API_KEY"])
else
  Rails.logger.warn("PostHog API key missing. PostHogClient is disabled.")
  PostHogClient = nil
end
# PostHog configuration
if defined?(PostHog)
  $posthog = PostHog::Client.new({
    api_key: ENV.fetch("POSTHOG_API_KEY", nil),
    host: ENV.fetch("POSTHOG_HOST", "https://app.posthog.com"),
    on_error: Proc.new { |status, msg| Rails.logger.error("[PostHog] #{status}: #{msg}") }
  })

  # Enable debug logging in development & staging
  if Rails.env.development? || Rails.env.staging?
    $posthog.logger.level = Logger::DEBUG
  end

  # If using Puma with multiple workers
  if defined?(Puma) && Rails.env.production?
    on_worker_boot do
      $posthog = PostHog::Client.new({
        api_key: ENV.fetch("POSTHOG_API_KEY", nil),
        host: ENV.fetch("POSTHOG_HOST", "https://app.posthog.com"),
        on_error: Proc.new { |status, msg| Rails.logger.error("[PostHog] #{status}: #{msg}") }
      })
    end
  end
end
