# Configure Solid Queue with correct configuration API
SolidQueue.configure do |config|
  # Configure workers
  config.dispatch_process = {
    worker_pool_size: ENV.fetch("SOLID_QUEUE_CONCURRENCY", 2).to_i
  }

  # Configure polling interval
  config.polling_interval = 5.seconds

  # Configure maintenance processes
  config.maintenance_interval = 30.seconds

  # Configure dispatcher
  config.dispatcher_dispatch_batch_size = 50
end
