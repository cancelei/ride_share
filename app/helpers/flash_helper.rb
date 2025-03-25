module FlashHelper
  # Helper method to set flash message either for HTML or Turbo Stream responses
  # Usage: set_flash(:notice, "Item created successfully")
  def set_flash(type, message)
    # For regular HTML responses
    flash[type] = message
    # For Turbo Stream responses
    flash.now[type] = message if request.format.turbo_stream?
  end

  # Helper method to render flash messages via Turbo Stream
  # Usage: render_flash_turbo_stream
  def render_flash_turbo_stream
    turbo_stream.update("flash", partial: "shared/flash")
  end
end
