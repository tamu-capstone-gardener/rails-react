# Base class for all mailers in the application
#
# @abstract This class serves as the base class that all mailers inherit from
# and provides common configuration such as default from address and layout.
class ApplicationMailer < ActionMailer::Base
  default from: "from@example.com"
  layout "mailer"
end
