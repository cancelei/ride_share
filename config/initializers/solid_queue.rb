# Configure Solid Queue to use fewer processes
Rails.application.config.solid_queue.concurrency = ENV.fetch("SOLID_QUEUE_CONCURRENCY", 2).to_i

# Configure supervisor to manage fewer workers
Rails.application.config.solid_queue.supervisor_options = {
  max_workers: ENV.fetch("SOLID_QUEUE_MAX_WORKERS", 2).to_i,
  polling_interval: 5, # seconds between checks
  heartbeat_interval: 30 # seconds between heartbeats
}

# Configure dispatcher to prevent too many queued jobs
Rails.application.config.solid_queue.dispatcher_options = {
  batch_size: 50,
  polling_interval: 5,
  max_threads: 5
}
