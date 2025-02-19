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
    @post.build_postable(post_params[:postable_attributes])
    if @post.save
      redirect_to @post, notice: "Post created successfully"
    else
      render :new, status: :unprocessable_entity
    end
  end

  def update
    @post = Post.find(params[:id])

    if @post.postable.update(content: post_params[:postable_attributes][:content]) && @post.update(post_params.except(:postable_attributes))
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
      params.require(:post).permit(:title, :description, :content, postable_attributes: %i[type content])
    end
end
