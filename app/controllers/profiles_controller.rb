class ProfilesController < ApplicationController
  before_action :authenticate_user!
  before_action :set_profile, only: %i[edit update]
  before_action :authorize_user!, only: %i[edit update]

  def edit
    render layout: "form"
  end

  def update
    if @profile.update(profile_params)
      redirect_to root_path, notice: "Profile was successfully updated."
    else
      @profile.errors.add(:username, "is already taken") if @profile.user.errors[:username].present?
      flash.now[:alert] = "There was an error updating the profile. Please check the form and try again."
      render :edit
    end
  end

  private
    def set_profile
      @profile = Profile.find(params[:id])
    end

    def authorize_user!
      redirect_to root_path, alert: "You can only edit your own profile." unless current_user.profile == @profile
    end

    def profile_params
      params.require(:profile).permit(:name, :gender, :dob, :link, :bio, :profile_picture,
                                      user_attributes: %i[username id])
    end
end
