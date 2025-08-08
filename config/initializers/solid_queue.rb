# frozen_string_literal: true

# Configure Solid Queue
Rails.application.reloader.to_prepare do
  SolidQueue.preserve_finished_jobs = false

  # Automatically clear finished jobs after 7 days
  SolidQueue.clear_finished_jobs_after = 7.days

  # Optional: Configure the cleanup interval (default is 1 hour)
  # SolidQueue.clear_finished_jobs_interval = 1.hour
end
