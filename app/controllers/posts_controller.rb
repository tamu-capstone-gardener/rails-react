class PostsController < ApplicationController
  def index
    @posts = Post.order(created_at: :desc).page(params[:page]).per(15)
  end

  def show
    @post = Post.find_by(id: params[:id])
  end
end
