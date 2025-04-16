# Configure process limits through environment variables
if Rails.env.production?
  # Limit Puma workers
  ENV["WEB_CONCURRENCY"] = "2" unless ENV["WEB_CONCURRENCY"]
  ENV["RAILS_MAX_THREADS"] = "5" unless ENV["RAILS_MAX_THREADS"]
end
