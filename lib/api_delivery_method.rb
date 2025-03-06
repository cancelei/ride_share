class ApiDeliveryMethod
  attr_accessor :settings

  def initialize(settings = {})
    @settings = settings
    # Store any configuration options
    Rails.logger.debug "ApiDeliveryMethod initialized with options: #{settings.inspect}"
  end

  def deliver!(mail)
    Rails.logger.info "Delivering mail via API"

    # Handle both Mail objects and parameter hashes
    if mail.is_a?(Hash)
      # Direct hash parameters
      to = mail[:to]
      subject = mail[:subject]
      html_body = mail[:html_content] || mail[:body]
      text_body = mail[:text_content] || ActionView::Base.full_sanitizer.sanitize(html_body.to_s)
      from = mail[:from] || "noreply@rideflow.com"
    else
      # Standard Mail object
      to = mail.to.is_a?(Array) ? mail.to.first : mail.to
      subject = mail.subject

      # Extract HTML and text content
      if mail.html_part && mail.text_part
        html_body = mail.html_part.body.to_s
        text_body = mail.text_part.body.to_s
      elsif mail.content_type&.include?("text/html")
        html_body = mail.body.to_s
        text_body = ActionView::Base.full_sanitizer.sanitize(html_body)
      else
        html_body = "<html><body>#{mail.body}</body></html>"
        text_body = mail.body.to_s
      end

      from = mail.from.is_a?(Array) ? mail.from.first : mail.from
    end

    # Prepare email parameters
    email_params = {
      to: to,
      subject: subject,
      html_content: html_body,
      text_content: text_body,
      sender: { email: from || "noreply@rideflow.com", name: "RideFlow" }
    }

    Rails.logger.info "Prepared email params: #{email_params.inspect}"

    # Send via API service
    begin
      result = EmailApiService.send_email(email_params)
      Rails.logger.info "Email sent successfully via API: #{result}"
      result
    rescue => e
      Rails.logger.error "Email sending failed: #{e.message}"
      Rails.logger.error e.backtrace.join("\n")
      raise e
    end
  end
end
