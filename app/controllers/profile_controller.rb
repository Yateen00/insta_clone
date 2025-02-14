class ProfilesController < ApplicationController
  before_action :authenticate_user!, except: [:confirm, :create_oauth]
  before_action :load_temp_profile, only: [:confirm, :create_oauth]

  def edit
    @profile = current_user.profile
  end

  def update
    @profile = current_user.profile
    if current_user.update(user_params) && @profile.update(profile_params)
      redirect_to root_path, notice: "Profile updated successfully."
    else
      render :edit
    end
  end

  def confirm
    @profile = @temp_profile
  end

  def create_oauth
    @profile = Profile.new(profile_params)
    @user = User.new(session["devise.#{params[:provider]}_data"])

    if @profile.valid?
      @user.profile = @profile
      if @user.save
        sign_in @user, event: :authentication
        redirect_to root_path, notice: "Profile created successfully."
      else
        render :confirm
      end
    else
      render :confirm
    end
  end

  private
    def profile_params
      params.require(:profile).permit(:username)
    end

    def user_params
      params.require(:user).permit(:email, :password, :password_confirmation)
    end

    def load_temp_profile
      @temp_profile = Profile.new(session["devise.#{params[:provider]}_profile"])
    end
end
