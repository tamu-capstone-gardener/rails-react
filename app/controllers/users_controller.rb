class UsersController < AuthenticatedApplicationController
  def complete_profile
    # Just render form
  end

  def update_profile
    if current_user.update(zip_code: params[:user][:zip_code])
      redirect_to root_path, notice: "Profile updated."
    else
      flash.now[:alert] = "Please enter a valid zip code."
      render :complete_profile
    end
  end
end
