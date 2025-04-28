# Base controller for the application
#
# @abstract This controller provides common functionality for all controllers
# in the application including browser compatibility checks, helper inclusion,
# and parameter sanitization.
class ApplicationController < ActionController::Base
  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern
  include ZipCodeHelper

  before_action :set_navbar_links

  before_action :configure_permitted_parameters, if: :devise_controller?

  private

  # Sets up navigation links based on user authentication status
  #
  # @return [void]
  def set_navbar_links
    @page_links = [
      { name: "Home", path: root_path }
      # { name: 'Posts (TODO)', path: root_path },
      # { name: 'Advice (TODO)', path: root_path },
      # { name: 'Data (TODO)', path: root_path },
      # { name: 'Schedules (TODO)', path: root_path },
      # { name: 'Settings (TODO)', path: root_path },
      # { name: 'Profile (TODO)', path: root_path },
    ]
    if user_signed_in?
      @page_links << { name: "Create Module", path: new_plant_module_path }
    else
      @page_links << { name: "Login", path: new_user_session_path }
    end
    @page_links << { name: "Help", path: help_path }
  end

  protected

  # Configures permitted parameters for Devise
  #
  # @note Allows zip_code to be submitted during user sign up and account update
  # @return [void]
  def configure_permitted_parameters
    # Add zip_code to sign up and account update
    devise_parameter_sanitizer.permit(:sign_up, keys: [ :zip_code ])
    devise_parameter_sanitizer.permit(:account_update, keys: [ :zip_code ])
  end
end
