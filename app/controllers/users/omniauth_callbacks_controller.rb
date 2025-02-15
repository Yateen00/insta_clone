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
        sign_in @user, event: :authentication
        set_flash_message(:notice, :success, kind: provider) if is_navigational_format?
        redirect_to root_path
      elsif @user.new_record?
        @user.username = auth.info.nickname || auth.info.name || generate_unique_username(auth.uid)
        @user.email = auth.info.email if @user.email.blank?
        if @user.save
          @user.create_profile unless @user.profile
          sign_in @user, event: :authentication
          set_flash_message(:notice, :success, kind: provider) if is_navigational_format?
          redirect_to edit_profile_path(@user.profile)
        else
          session["devise.#{provider.downcase}_data"] = auth.except("extra")
          redirect_to new_user_registration_url
        end
      end
    end


    def generate_unique_username(uid)
      base_username = "user_#{uid}"
      username = base_username
      counter = 1

      while User.exists?(username: username)
        username = "#{base_username}_#{counter}"
        counter += 1
      end

      username
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
