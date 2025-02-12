class Users::OmniauthCallbacksController < Devise::OmniauthCallbacksController
  # google_oauth2 is the method that is called when the user logs in with Google
  def google_oauth2
    user = User.from_google(**from_google_params)
    if user.present?
      # Prevent other signed in scopes from interfering with the sign in
      sign_out_all_scopes

      # Store OAuth tokens in session for future API access
      # store_oauth_session_data(auth.credentials)

      flash[:success] = t "devise.omniauth_callbacks.success", kind: "Google"
      sign_in_and_redirect user, event: :authentication

    else
      flash[:alert] = t "devise.omniauth_callbacks.failure", kind: "Google",
                                                              reason: "#{auth.info.email} is not authorized."
      redirect_to new_user_session_path
    end
  end

  protected

  def after_omniauth_failure_path_for(_scope)
    new_user_session_path
  end

  # def after_sign_in_path_for(_resource_or_scope)
  #   root_path
  # end

  private

  def from_google_params
    @from_google_params ||= {
      uid: auth.info.uid,
      email: auth.info.email,
      full_name: auth.info.name,
      avatar_url: auth.info.avatar_url
    }
  end

  def auth
    @auth ||= request.env["omniauth.auth"]
  end

  # def store_oauth_session_data(credentials)
  #   # Storing access token, refresh token, and expiration in the session
  #   session[:google_access_token] = credentials.token
  #   session[:google_refresh_token] = credentials.refresh_token
  #   session[:google_expires_at] = credentials.expires_at.to_i.seconds
  # end
end
