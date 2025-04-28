# Base controller requiring authentication
#
# @abstract This controller ensures that users are authenticated before accessing
# any actions in controllers that inherit from it
class AuthenticatedApplicationController < ApplicationController
  before_action :authenticate_user!
end
