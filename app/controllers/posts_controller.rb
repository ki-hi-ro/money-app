class PostsController < ApplicationController
  def index
    @posts = Post.all
  end

  def new
  end

  def create
    @post = Post.new(content: params[:name], date: params[:date], price: params[:price])
    @post.save
    redirect_to("/posts/index")
  end
end
