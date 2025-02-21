class PostsController < ApplicationController
  layout "form", only: %i[new edit]
  before_action :authenticate_user!, except: %i[index show]

  def index
    @posts = Post.all
  end

  def show
    @post = Post.find(params[:id])
  end

  def new
    @post = current_user.posts.build
    @post.build_postable("Text")
  end

  def edit
    @post = Post.find(params[:id])
  end

  def create
    @post = current_user.posts.build(post_params.except(:postable_attributes))
    type = determine_postable_type(post_params[:postable_attributes][:content])
    unless type == "Unknown"
      p(post_params[:postable_attributes].merge(type: type))

      @post.build_postable(post_params[:postable_attributes].merge(type: type))
      if @post.save
        redirect_to @post, notice: "Post created successfully"
        return
      end
    end
    render :new, status: :unprocessable_entity, alert: "Post creation failed"
  end

  def update
    @post = Post.find(params[:id])
    new_type = determine_postable_type(post_params[:postable_attributes][:content])

    if new_type == @post.postable_type
      # Update the existing postable
      @post.postable.update(post_params[:postable_attributes])
    else
      # Destroy the old postable and build a new one with the new type
      @post.postable.destroy
      @post.build_postable(post_params[:postable_attributes].merge(type: new_type))
    end

    if @post.update(post_params.except(:postable_attributes))
      redirect_to @post, notice: "Post updated successfully"
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @post = Post.find(params[:id])
    @post.destroy
    redirect_to root_path, notice: "Post deleted successfully"
  end

  private
    def post_params
      params.require(:post).permit(:title, :description, postable_attributes: [:content])
    end

    def determine_postable_type(content)
      if content.is_a?(String)
        "Text"
      elsif content.is_a?(ActionDispatch::Http::UploadedFile) || content.respond_to?(:file)
        mime_type = content.content_type

        if mime_type.start_with?("image/")
          "Image"
        elsif mime_type.start_with?("video/")
          "Video"
        else
          "Unknown" # Handle unsupported file types
        end
      else
        "Unknown" # empty content
      end
    end
end
