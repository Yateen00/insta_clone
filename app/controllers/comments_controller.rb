class CommentsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_comment, only: %i[edit update destroy cancel_edit]
  before_action :set_post
  before_action :authorize_user!, only: %i[edit update destroy cancel_edit]
  def new
    @comment = Comment.new(reply_to_id: params[:reply_to_id])
    respond_to do |format|
      format.turbo_stream
    end
  end

  # edit
  def edit; end

  # create
  def create
    parent_comment = Comment.find_by(id: comment_params[:reply_to_id])
    parent_comment = parent_comment&.reply_to_id || parent_comment&.id
    @comment = current_user.comments.new(
      content: comment_params[:content],
      post_id: @post.id,
      reply_to_id: parent_comment
    )
    respond_to do |format|
      if @comment.save
        format.turbo_stream { flash.now[:notice] = "Comment was successfully created." }
        format.html { redirect_to @post, notice: "Comment was successfully created." }
      else
        format.turbo_stream { flash.now[:alert] = "Comment was not created." }
        format.html { render :new, alert: "Comment was not created.", status: :unprocessable_entity }
      end
    end
  end

  def cancel_edit
    respond_to do |format|
      format.turbo_stream { flash.now[:notice] = "Edit canceled." }
    end
  end

  # update
  def update
    respond_to do |format|
      if @comment.update(comment_params.except(:reply_to_id))
        format.turbo_stream { flash.now[:notice] = "Comment was successfully updated." }
        format.html { redirect_to @post, notice: "Comment was successfully updated." }
      else
        format.turbo_stream { flash.now[:alert] = "Comment was not updated." }
        format.html { render :edit, alert: "Comment was not updated.", status: :unprocessable_entity }
      end
    end
  end

  # destroy
  def destroy
    respond_to do |format|
      if @comment.destroy
        format.turbo_stream { flash.now[:notice] = "Comment was successfully destroyed." }
        format.html { redirect_to @post, notice: "Comment was successfully destroyed." }
      else
        format.turbo_stream { flash.now[:alert] = "Comment was not destroyed." }
        format.html { redirect_to @post, alert: "Comment was not destroyed.", status: :unprocessable_entity }
      end
    end
  end

  private
    def set_comment
      @comment = current_user.comments.find(params[:id])
    end

    def set_post
      @post = Post.find(params[:post_id])
    end

    def comment_params
      params.expect(comment: %i[content reply_to_id])
    end

    def authorize_user!
      return if @comment.user == current_user

      redirect_to @comment.post, alert: "You are not authorized to perform this action.",
                                 status: :unauthorized
    end
end
