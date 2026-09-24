class PostsController < ApplicationController
  before_action :authenticate_user!
  def index
    @posts = current_user.posts
  end

  def new
  end

  def create
    @post = current_user.posts.new(content: params[:name], date: params[:date], price: params[:price])
    @post.save
    redirect_to("/posts/index")
  end

  def show
    @post = current_user.posts.find(params[:id])
  end

  def destroy
    @post = current_user.posts.find(params[:id])
    @post.destroy
    redirect_to("/posts/index")
  end
end
