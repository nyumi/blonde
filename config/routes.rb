Rails.application.routes.draw do
  root 'watch_lists#index'

  get 'search', to: 'watch_lists#search'
  post 'add', to: 'watch_lists#add'


  # get 'pages/show'
    
  devise_for :users
  # root to: "pages#index"
  # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html
end