class ApplicationMailer < ActionMailer::Base
  default from: "admin@rideflow.live"
  layout "mailer"

  # Set the delivery method to API for all mailers
  # self.delivery_method = :api
end
