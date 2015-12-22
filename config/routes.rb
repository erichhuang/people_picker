Rails.application.routes.draw do
  resources :users, only: [:index, :create] do
    get 'use', on: :member

    collection do
      get 'stats'
      get 'fetch_existing'
      get 'feeling_lucky'
      get 'fetch_ldap'
      post 'multi', to: 'users#create_multi'
    end
  end
end
