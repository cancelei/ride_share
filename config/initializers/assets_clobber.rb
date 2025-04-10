# Ensure JavaScript caching is disabled in development
if Rails.env.development?
  # Run the clobber task when Rails starts (safely)
  Rails.application.config.after_initialize do
    # Clear JavaScript caches on start
    begin
      puts "Clearing JavaScript cache on server start..."
      FileUtils.rm_rf(Dir.glob(Rails.root.join("tmp", "cache", "assets", "**", "*.js")))
      FileUtils.rm_rf(Dir.glob(Rails.root.join("public", "assets", "**", "*.js")))
      FileUtils.rm_rf(Dir.glob(Rails.root.join("public", "packs", "**", "*.js")))
      puts "JavaScript cache cleared on server start!"
    rescue => e
      puts "Warning: Failed to clear JavaScript cache: #{e.message}"
    end
  end

  # Add middleware to clear caches on each request
  module AssetsClobberMiddleware
    class Middleware
      def initialize(app)
        @app = app
      end

      def call(env)
        # Only clobber on page navigations, not asset requests
        unless env["PATH_INFO"].match?(/\.(js|css|png|jpg|jpeg|gif|ico|svg)/)
          # Clear JavaScript caches
          FileUtils.rm_rf(Dir.glob(Rails.root.join("tmp", "cache", "assets", "**", "*.js")))
        end

        @app.call(env)
      end
    end
  end

  Rails.application.config.middleware.insert_before 0, AssetsClobberMiddleware::Middleware
end
