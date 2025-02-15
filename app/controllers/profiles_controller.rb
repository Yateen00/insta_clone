class ProfilesController < ApplicationController
  before_action :set_profile, only: %i[edit update]

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

    def profile_params
      params.require(:profile).permit(:name, :gender, :dob, :link, :bio, :profile_picture, user_attributes: [:username, :id])
    end
end
