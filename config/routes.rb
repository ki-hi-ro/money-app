Rails.application.routes.draw do
  get '/' => "home#top"
  get '/about' => "home#about"
  get '/posts/index' => "posts#index"
  get '/posts/new/' => "posts#new"
  post '/posts/create' => "posts#create"
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Defines the root path route ("/")
  # root "articles#index"
end
