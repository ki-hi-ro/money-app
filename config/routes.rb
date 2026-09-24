Rails.application.routes.draw do
  devise_for :users
  namespace :finance do
    root "dashboard#index"
    resources :accounts, :entries, :tasks, :snapshots, :cards, except: :show
    resource :settings, only: [:edit, :update]
  end
  resources :dialies
  root "home#top"
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
