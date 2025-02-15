class ProfilesController < ApplicationController
  before_action :set_profile, only: %i[edit update]

  def edit
  end

  def update
    if @profile.update(profile_params)
      current_user.update(username: params[:profile][:username]) if params[:profile][:username].present?
      redirect_to @profile, notice: "Profile was successfully updated."
    else
      render :edit
    end
  end

  private
    def set_profile
      @profile = Profile.find(params[:id])
    end

    def profile_params
      params.require(:profile).permit(:name, :dob, :gender, :link, :bio, :profile_picture)
    end
end
