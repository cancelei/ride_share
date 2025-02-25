class PagesController < ApplicationController
  skip_before_action :authenticate_user!, only: [ :landing ]

  def landing
    redirect_to dashboard_path if user_signed_in?
  end
end
