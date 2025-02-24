class UsersController < ApplicationController
  before_action :set_user, only: %i[show followers follows]
  before_action :authenticate_user!
  def show; end

  def followers
    @followers = @user.followers
  end

  def follows
    @follows = @user.follows
  end

  private
    def set_user
      @user = User.find(params[:id])
    end
end
