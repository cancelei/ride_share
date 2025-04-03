# frozen_string_literal: true

module PosthogTrackable
  extend ActiveSupport::Concern

  class_methods do
    def track_event(event_name, properties = {})
      after_commit -> { track_to_posthog(event_name, properties) }
    end
  end

  private

  def track_to_posthog(event_name, properties = {})
    return unless PostHogAnalytics.client

    # Merge default properties with custom properties
    event_properties = default_properties.merge(properties)

    # Add timestamps
    event_properties[:created_at] = Time.current
    event_properties[:environment] = Rails.env

    # Send event to PostHog
    PostHogAnalytics.capture(
      event_name,
      posthog_distinct_id,
      event_properties
    )
  end

  def posthog_distinct_id
    return id if respond_to?(:id)
    return uuid if respond_to?(:uuid)

    # Generate a unique identifier if none exists
    SecureRandom.uuid
  end

  def default_properties
    attributes = {}

    # Add model name
    attributes[:model] = self.class.name

    # Add important timestamps if they exist
    attributes[:created_at] = created_at if respond_to?(:created_at)
    attributes[:updated_at] = updated_at if respond_to?(:updated_at)

    # Add any custom default properties
    attributes.merge(custom_posthog_properties)
  end

  # Override this method in your models to add custom properties
  def custom_posthog_properties
    {}
  end
end
