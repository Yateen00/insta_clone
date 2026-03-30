class UsersController < ApplicationController
  before_action :set_user, only: %i[show followers follows]
  before_action :authenticate_user!
  def show; end

  def followers
    @followers = @user.followers
    render json: @followers.as_json(only: %i[id username online])
  end

  def follows
    @follows = @user.follows
    render json: @follows.as_json(only: %i[id username online])
  end

  def all_with_online
    users = User.all
    render json: users.as_json(only: %i[id username online])
  end

  private
    def set_user
      @user = User.find(params[:id])
    end
end
