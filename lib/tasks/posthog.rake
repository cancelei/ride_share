# frozen_string_literal: true

namespace :posthog do
  desc "Test PostHog integration"
  task test: :environment do
    puts "\n=== Testing PostHog Integration ==="

    if defined?(PostHogAnalytics) && PostHogAnalytics.client
      begin
        # Test basic event capture
        PostHogAnalytics.capture(
          "test_event",
          "test_user_123",
          { test: true, environment: Rails.env }
        )
        puts "✅ Successfully sent test event"

        # Test feature flag
        flag_value = PostHogAnalytics.feature_enabled?("test-flag", "test_user_123")
        puts "✅ Successfully checked feature flag (value: #{flag_value})"

        # Test group analytics
        PostHogAnalytics.group_identify(
          "company",
          "test_company_123",
          { name: "Test Company", industry: "Technology" }
        )
        puts "✅ Successfully identified group"

        # Print configuration
        puts "\nCurrent PostHog Configuration:"
        puts "Host: #{ENV['POSTHOG_HOST']}"
        puts "API Key: #{ENV['POSTHOG_API_KEY']&.slice(0..10)}..."
        puts "Environment: #{Rails.env}"
        puts "Timeout: #{ENV['POSTHOG_TIMEOUT']} seconds"
      rescue => e
        puts "\n❌ Error testing PostHog:"
        puts e.message
        puts e.backtrace.first(5)
      end
    else
      puts "\n❌ PostHog client is not properly initialized"
      puts "Please check your configuration in config/initializers/posthog.rb"
      puts "and ensure POSTHOG_API_KEY is set in your environment"
    end
  end

  desc "Verify PostHog configuration"
  task verify_config: :environment do
    puts "\n=== Verifying PostHog Configuration ==="

    # Check environment variables
    required_vars = %w[POSTHOG_API_KEY POSTHOG_HOST]
    missing_vars = required_vars.reject { |var| ENV[var].present? }

    if missing_vars.any?
      puts "❌ Missing required environment variables:"
      missing_vars.each { |var| puts "  - #{var}" }
    else
      puts "✅ All required environment variables are set"
    end

    # Check PostHog client initialization
    if defined?(PostHogAnalytics) && PostHogAnalytics.client
      puts "✅ PostHog client is properly initialized"
    else
      puts "❌ PostHog client is not initialized"
    end

    # Print current configuration
    puts "\nCurrent Configuration:"
    puts "Host: #{ENV['POSTHOG_HOST']}"
    puts "API Key: #{ENV['POSTHOG_API_KEY']&.slice(0..10)}..."
    puts "Environment: #{Rails.env}"
    puts "Debug Mode: #{(Rails.env.development? || Rails.env.staging?).inspect}"
  end
end
