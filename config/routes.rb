Rails.application.routes.draw do
  devise_for :users
  resources :dialies
  get '/' => "home#top"
  get '/about' => "home#about"
  get '/posts/index' => "posts#index"
  get '/posts/new/' => "posts#new"
  post '/posts/create' => "posts#create"
  get '/posts/:id' => 'posts#show'
  delete '/posts/:id' => 'posts#destroy'

  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Defines the root path route ("/")
  # root "articles#index"
end
