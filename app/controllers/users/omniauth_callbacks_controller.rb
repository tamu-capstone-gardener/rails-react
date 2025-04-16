class Users::OmniauthCallbacksController < Devise::OmniauthCallbacksController
  def google_oauth2
    @user = User.from_omniauth(request.env["omniauth.auth"])

    if @user.persisted?
      sign_in @user

      if @user.zip_code.blank?
        redirect_to complete_profile_path
      else
        redirect_to root_path, notice: "Signed in successfully."
      end
    end
  end

  def failure
    redirect_to root_path
  end
end
