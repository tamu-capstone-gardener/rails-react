# Controller for user profile management
#
# @example Request to complete profile form
#   GET /users/complete_profile
#
# @example Request to update profile
#   PATCH /users/update_profile
class UsersController < AuthenticatedApplicationController
  # Renders the form for completing user profile
  #
  # @return [void]
  def complete_profile
    # Just render form
  end

  # Updates the user's profile with submitted data
  #
  # @param user [Hash] user parameters from form
  # @option user [String] :zip_code ZIP code for the user's location
  #
  # @return [void]
  def update_profile
    if current_user.update(zip_code: params[:user][:zip_code])
      redirect_to root_path, notice: "Profile updated."
    else
      flash.now[:alert] = "Please enter a valid zip code."
      render :complete_profile
    end
  end
end
