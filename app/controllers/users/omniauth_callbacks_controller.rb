# frozen_string_literal: true

class Users::OmniauthCallbacksController < Devise::OmniauthCallbacksController
  # You should configure your model like this:
  # devise :omniauthable, omniauth_providers: [:twitter]

  # You should also create an action method in this controller like this:
  # def twitter
  # end
  skip_before_action :verify_authenticity_token, only: %i[github google_oauth2]
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

      if @user.persisted? # user exists
        sign_in @user, event: :authentication
        redirect_to root_path, notice: "Signed in with #{provider} successfully."
        return
      end

      # new user
      if provider == "GitHub"
        @user.username = format_username(auth.info.nickname)
        @user.email = fetch_github_email(auth.credentials.token)
      elsif provider == "Google"
        @user.username = format_username(auth.info.name)
        @user.email = auth.info.email
      end
      @user.username = !User.exists?(username: @user.username) && @user.username ? @user.username : generate_unique_username(auth.uid)
      @user.password = Devise.friendly_token[0, 20]
      if @user.save
        @user.create_profile if @user.profile.nil?
        update_profile(@user.profile, auth, provider)
        sign_in @user, event: :authentication

        redirect_to edit_profile_path(@user.profile), notice: "Please complete your profile."
        return
      end
      # failed
      Rails.logger.debug "provider:"
      Rails.logger.debug auth.provider
      Rails.logger.debug "Auth info:"
      Rails.logger.debug auth.info
      Rails.logger.debug "User attributes:"
      Rails.logger.debug @user.attributes
      Rails.logger.debug { "User errors: #{@user.errors.full_messages.join(', ')}" }
      session["devise.#{auth.provider.downcase}_data"] = auth.except("extra")

      redirect_to new_user_registration_url, alert: "Failed to sign in with #{provider} account."
    end

    def fetch_github_email(token)
      require "net/http"
      require "json"

      uri = URI("https://api.github.com/user/emails")
      request = Net::HTTP::Get.new(uri)
      request["Authorization"] = "token #{token}"
      request["Accept"] = "application/json"

      response = Net::HTTP.start(uri.hostname, uri.port, use_ssl: true) { |http| http.request(request) }

      emails = JSON.parse(response.body)
      primary_email = emails.find { |email| email["primary"] && email["verified"] }["email"]
      primary_email || emails.first["email"]
    end

    def update_profile(profile, auth, provider)
      profile_attributes = {
        name: auth.info.name,
        link: find_url(auth.info.urls, provider),
        bio: auth.info.Blog&.truncate(200, omission: ""),
        remote_profile_picture_url: auth.info.image
        # can be assigned if it its invalid path, it defualts to defualt url. and in db it stores nil for profile_picture. so no isusues.
      }.compact
      # carreriwave method. can be used in forms too to accept image link with :remote_profile_picture_url varaible name
      return if profile.update(profile_attributes)

      Rails.logger.debug { "Profile errors: #{profile.errors.full_messages.join(', ')}" }
      profile.errors.each_key { |attribute| profile_attributes.delete(attribute) }
      profile.update(profile_attributes)
    end

    def find_url(urls, provider)
      # as already foramtted in rest of way
      provider = provider.downcase
      urls&.detect { |key, _| key.downcase.include?(provider) }&.[](1) || urls&.values&.first
    end

    def generate_unique_username(_uid)
      base_username = "user_"
      username = base_username.truncate(15, omission: "")
      counter = rand(9_999_999)

      while User.exists?(username: username)
        username = "#{base_username}_#{counter}"
        counter += 1
      end

      username
    end

    def format_username(username)
      username.tr(" ", "_").gsub(/[^a-zA-Z0-9_.-]/, "").truncate(20, omission: "")
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
