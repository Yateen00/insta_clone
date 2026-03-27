class FollowsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_user

  def toggle
    current_user.toggle_follow(@user)
    @user.reload
    respond_to do |format|
      format.turbo_stream
      format.html { redirect_to request.referer || root_path }
    end
  end

  def remove_follower
    current_user.remove_follower(@user)
    @user.reload

    respond_to do |format|
      format.turbo_stream
      format.html { redirect_to followers_user_path(current_user) }
    end
  end

  def accept_follow_request
    @follow = current_user.follows_as_followee.pending.find_by(follower: @user)
    current_user.accept_follow_request(@user)
    respond_to do |format|
      format.turbo_stream
      format.html { redirect_to follow_requests_user_path(current_user) }
    end
  end

  def reject_follow_request
    @follow = current_user.follows_as_followee.pending.find_by(follower: @user)
    current_user.reject_follow_request(@user)
    respond_to do |format|
      format.turbo_stream
      format.html { redirect_to follow_requests_user_path(current_user) }
    end
  end

  private
    def set_user
      @user = User.find(params[:id])
    end
end
