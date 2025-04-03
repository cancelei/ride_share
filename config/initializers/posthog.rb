# frozen_string_literal: true

PostHogClient = if ENV["POSTHOG_API_KEY"].present?
  PostHog::Client.new(
    api_key: ENV["POSTHOG_API_KEY"],
    host: ENV.fetch("POSTHOG_HOST", "https://app.posthog.com"),
    on_error: ->(status, msg) { Rails.logger.error("[PostHog] \#{status}: \#{msg}") }
  )
else
  Rails.logger.warn("PostHog API key missing. PostHogClient is disabled.")
  nil
end

if PostHogClient && (Rails.env.development? || Rails.env.staging?)
  PostHogClient.logger.level = Logger::DEBUG
end

# Puma worker boot configuration
if defined?(Puma) && Rails.env.production?
  Puma.on_worker_boot do
    if ENV["POSTHOG_API_KEY"].present?
      PostHogClient = PostHog::Client.new(
        api_key: ENV["POSTHOG_API_KEY"],
        host: ENV.fetch("POSTHOG_HOST", "https://app.posthog.com"),
        on_error: ->(status, msg) { Rails.logger.error("[PostHog] \#{status}: \#{msg}") }
      )
    else
      Rails.logger.warn("PostHog API key missing on Puma worker boot. PostHogClient is disabled.")
      PostHogClient = nil
    end
  end
end
