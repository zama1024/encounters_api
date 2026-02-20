Rails.application.routes.draw do
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Defines the root path route ("/")
  # root "articles#index"

  resources :users, only: [:create, :show] do
    post 'api_keys', to: 'users#create_api_key'
    delete 'api_keys/:key_id', to: 'users#revoke_api_key'
  end

  resources :encounters, only: [:create]
end
