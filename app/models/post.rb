class Post < ApplicationRecord
  def index
    @posts = Post.all
  end
end
