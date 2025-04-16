# frozen_string_literal: true

module PosthogTracking
  extend ActiveSupport::Concern

  included do
    after_action :track_page_view, if: :should_track_page_view?
  end

  private

  def track_to_posthog(event_name, properties = {})
    return unless $posthog && current_user

    event_properties = default_properties.merge(properties)

    $posthog.capture({
      distinct_id: current_user.id,
      event: event_name,
      properties: event_properties
    })
  end

  def track_page_view
    return unless $posthog && current_user

    $posthog.capture({
      distinct_id: current_user.id,
      event: "$pageview",
      properties: {
        '$current_url': request.url,
        '$pathname': request.path,
        '$host': request.host,
        'controller': controller_name,
        'action': action_name
      }.merge(default_properties)
    })
  end

  def default_properties
    {
      environment: Rails.env,
      controller: controller_name,
      action: action_name,
      user_agent: request.user_agent,
      ip_address: request.ip,
      referrer: request.referrer,
      timestamp: Time.current
    }
  end

  def should_track_page_view?
    # Override this method in your controllers to customize when to track page views
    request.format.html? && !request.xhr?
  end
end
