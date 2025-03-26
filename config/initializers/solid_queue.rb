# Configure database connection
Rails.application.config.solid_queue.connects_to = { database: { writing: :primary } }

# Configure mailers queue
Rails.application.config.action_mailer.deliver_later_queue_name = :mailers
