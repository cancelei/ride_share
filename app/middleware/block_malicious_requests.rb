class BlockMaliciousRequests
  def initialize(app)
    @app = app
  end

  def call(env)
    request = Rack::Request.new(env)

    # Block common malicious request patterns
    if malicious_request?(request)
      Rails.logger.info "Blocked malicious request to: #{request.path} from IP: #{request.ip}"
      return [ 403, {
        "Content-Type" => "text/plain",
        "X-Frame-Options" => "DENY",
        "X-Content-Type-Options" => "nosniff"
      }, [ "Forbidden" ] ]
    end

    @app.call(env)
  end

  private

  def malicious_request?(request)
    path = request.path.downcase
    user_agent = request.user_agent.to_s.downcase

    # Block common malicious paths
    return true if path.match?(/\.(php|asp|aspx|jsp|cgi)$/)
    return true if path.match?(/\/(?:wp-admin|wp-login|wp-content|wordpress|setup-config|phpinfo|php-info|admin|administrator|login|backup|wp|config|old|new|test|bak)/)

    # Block suspicious user agents
    return true if user_agent.match?(/(?:nikto|sqlmap|fimap|nmap|nessus|whatweb|bbqsql|jbrofuzz|havij|zmeu|w3af|acunetix|netsparker)/i)

    # Block requests trying to exploit common vulnerabilities
    return true if path.include?("../") # Path traversal attempt
    return true if path.match?(/\/(\.git|\.env|\.config|\.ssh|\.bash_history)/) # Sensitive files

    false
  end
end
