Rails.application.routes.draw do
  root 'watch_lists#index'

  # root 'pages#index'

  get 'pages/show'

  devise_for :users
  # root to: "pages#index"
  # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html
end