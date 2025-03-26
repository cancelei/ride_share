# Configure garbage collection to help prevent memory leaks
if defined?(GC) && !Rails.env.test?
  # Run garbage collection after each request in development mode
  if Rails.env.development?
    require 'objspace'
    
    Rails.application.middleware.insert_before(0, Rack::Runtime) do |app|
      lambda do |env|
        # Run GC before processing request
        GC.start(full_mark: true) if rand < 0.01 # 1% chance to run full GC
        
        result = app.call(env)
        
        # Run GC after processing request
        GC.start(full_mark: false) if rand < 0.1 # 10% chance to run regular GC
        
        result
      end
    end
  end
  
  # Configure GC for production
  if Rails.env.production? || Rails.env.staging?
    # Reduce memory fragmentation and encourage the GC to run more aggressively
    GC.configure(
      malloc_limit: 16_000_000,       # Run major GC when malloc exceeds this value
      malloc_limit_max: 32_000_000,   # Maximum malloc_limit
      malloc_limit_growth_factor: 1.4, # Growth factor for malloc_limit
      oldmalloc_limit: 16_000_000,    # Run major GC when oldmalloc exceeds this value
      oldmalloc_limit_max: 128_000_000 # Maximum oldmalloc_limit
    )
  end
end 