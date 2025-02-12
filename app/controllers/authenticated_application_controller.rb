class AuthenticatedApplicationController < ApplicationController
  before_action :authenticate_user!
end
