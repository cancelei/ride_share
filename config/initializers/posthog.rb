# frozen_string_literal: true

# PostHog Configuration
module PostHogAnalytics
  class << self
    def client
      @client ||= initialize_client
    end

    def capture(event_name, distinct_id, properties = {})
      return unless client

      client.capture({
        distinct_id: distinct_id,
        event: event_name,
        properties: properties
      })
    rescue StandardError => e
      Rails.logger.error("[PostHog] Failed to capture event: #{e.message}")
      nil
    end

    def identify(distinct_id, properties = {})
      return unless client

      client.capture({
        distinct_id: distinct_id,
        event: "$identify",
        properties: {
          '$set': properties
        }
      })
    rescue StandardError => e
      Rails.logger.error("[PostHog] Failed to identify user: #{e.message}")
      nil
    end

    def feature_enabled?(key, distinct_id, properties = {})
      return false unless client

      client.is_feature_enabled(key, distinct_id, properties)
    rescue StandardError => e
      Rails.logger.error("[PostHog] Failed to check feature flag: #{e.message}")
      false
    end

    def get_feature_flag(key, distinct_id, properties = {})
      return nil unless client

      client.get_feature_flag(key, distinct_id, properties)
    rescue StandardError => e
      Rails.logger.error("[PostHog] Failed to get feature flag: #{e.message}")
      nil
    end

    def group_identify(group_type, group_key, properties = {})
      return unless client

      client.group_identify({
        group_type: group_type,
        group_key: group_key,
        properties: properties
      })
    rescue StandardError => e
      Rails.logger.error("[PostHog] Failed to identify group: #{e.message}")
      nil
    end

    private

    def initialize_client
      return nil unless ENV["POSTHOG_API_KEY"].present?

      ::PostHog::Client.new({
        api_key: ENV["POSTHOG_API_KEY"],
        host: ENV.fetch("POSTHOG_HOST", "https://us.i.posthog.com"),
        on_error: ->(status, msg) { Rails.logger.error("[PostHog] #{status}: #{msg}") },
        feature_flag_request_timeout_seconds: ENV.fetch("POSTHOG_TIMEOUT", 3).to_i
      }).tap do |posthog|
        # Enable debug logging in development and staging
        if Rails.env.development? || Rails.env.staging?
          posthog.logger.level = Logger::DEBUG
        end
      end
    end
  end
end

# Make PostHog client globally accessible
$posthog = PostHogAnalytics.client
