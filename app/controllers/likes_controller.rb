class LikesController < ApplicationController
  before_action :authenticate_user!
  before_action :set_likeable

  def like
    if current_user.liked?(@likeable)
      current_user.likes.find_by(likeable: @likeable).destroy
      message = "Unliked"
    else
      current_user.likes.create(likeable: @likeable)
      message = "Liked"
    end
    @likeable.reload

    respond_to do |format|
      format.turbo_stream do
        flash.now[:notice] = "#{@likeable.class.name} #{message}"
        render "likes/like", locals: { size: params[:size] }
      end
      format.html { redirect_to @likeable&.post || @likeable }
    end
  end

  private
    def set_likeable
      @likeable = params[:type].constantize.find(params[:id])
    end
end
