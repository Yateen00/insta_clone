# frozen_string_literal: true

class Users::SessionsController < Devise::SessionsController
  # before_action :configure_sign_in_params, only: [:create]
  before_action :check_omniauth_user, only: [:create]
  # GET /resource/sign_in
  # def new
  #   super
  # end
  before_action :check_omniauth_user, only: [:create]

  private
    def check_omniauth_user
      user = User.find_by(email: params[:user][:email])
      if user && user.provider.present?
        flash[:alert] = "Please use #{user.provider.capitalize} to log in."
        redirect_to new_user_session_path
      end
    end
  # POST /resource/sign_in
  # def create
  #   super
  # end

  # DELETE /resource/sign_out
  # def destroy
  #   super
  # end

  # protected

  # If you have extra params to permit, append them to the sanitizer.
  # def configure_sign_in_params
  #   devise_parameter_sanitizer.permit(:sign_in, keys: [:attribute])
  # end
end
