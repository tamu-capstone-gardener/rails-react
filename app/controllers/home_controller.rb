# Controller for static home pages
#
# @example Request to welcome page
#   GET /
#
# @example Request to help page
#   GET /help
class HomeController < ApplicationController
  # Renders the welcome/landing page
  #
  # @return [void]
  def welcome
  end

  # Renders the help/documentation page
  #
  # @return [void]
  def help
  end
end
