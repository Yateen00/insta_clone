class UsersController < ApplicationController
  before_action :set_user, only: %i[show followers follows follow_requests]
  before_action :authenticate_user!

  def show; end

  def followers
    @followers = @user.followers
  end

  def follows
    @follows = @user.follows
  end

  def follow_requests
    redirect_to root_path, alert: "Access denied." and return unless current_user == @user
    @follow_requests = @user.pending_follow_requests
  end

  def toggle_private
    current_user.update(private_account: !current_user.private_account?)
    redirect_to request.referer || user_path(current_user)
  end

  private
    def set_user
      @user = User.find(params[:id])
    end
end
