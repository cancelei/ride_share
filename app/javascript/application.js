// Configure your import map in config/importmap.rb. Read more: https://github.com/rails/importmap-rails
import "@hotwired/turbo-rails"
import "controllers"

// Initialize PostHog
import posthog from 'posthog-js'

posthog.init('phc_DPxPX8BS8ejaf1Z6pILVCYCoiWre27rth7QmYmFmH2D', {
    api_host: 'https://us.i.posthog.com',
    person_profiles: 'identified_only'
})
