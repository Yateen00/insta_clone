# frozen_string_literal: true

class Users::OmniauthCallbacksController < Devise::OmniauthCallbacksController
  # You should configure your model like this:
  # devise :omniauthable, omniauth_providers: [:twitter]

  # You should also create an action method in this controller like this:
  # def twitter
  # end
  skip_before_action :verify_authenticity_token, only: [:github, :google_oauth2]
  # More info at:
  # https://github.com/heartcombo/devise#omniauth

  # GET|POST /resource/auth/twitter
  # def passthru
  #   super
  # end
  def github
    handle_omniauth("GitHub")
  end

  def google_oauth2
    handle_omniauth("Google")
  end

  private
    def handle_omniauth(provider)
      auth = request.env["omniauth.auth"]
      @user = User.find_or_initialize_by(provider: auth.provider, uid: auth.uid)

      if @user.persisted?
        sign_in_and_redirect @user, event: :authentication
        set_flash_message(:notice, :success, kind: provider) if is_navigational_format?
      else
        session["devise.#{provider.downcase}_data"] = {
          provider: auth.provider,
          uid: auth.uid,
          email: auth.info.email
        }
        session["devise.#{provider.downcase}_profile"] = { username: auth.info.name }

        redirect_to confirm_profile_path(provider: provider.downcase)
      end
    end

  # GET|POST /users/auth/twitter/callback
  # def failure
  #   super
  # end

  # protected

  # The path used when OmniAuth fails
  # def after_omniauth_failure_path_for(scope)
  #   super(scope)
  # end
end
