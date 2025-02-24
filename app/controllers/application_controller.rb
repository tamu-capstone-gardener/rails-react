class ApplicationController < ActionController::Base
  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern

  before_action :set_navbar_links

  private

  def set_navbar_links
    @page_links = [
      { name: 'Home', path: root_path },
      { name: 'Modules', path: plant_modules_path },
      { name: 'Posts (TODO)', path: root_path },
      { name: 'Advice (TODO)', path: root_path },
      { name: 'Data (TODO)', path: root_path },
      { name: 'Schedules (TODO)', path: root_path },
      { name: 'Settings (TODO)', path: root_path },
      { name: 'Profile (TODO)', path: root_path },
      { name: 'Logout', path: destroy_user_session_path, method: :delete }
    ]
  end
end
