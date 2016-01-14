Rails.application.routes.draw do
  resources :users, only: [:index, :create] do
    get 'use', on: :member

    collection do
      get 'stats'
      get 'fetch'
    end
  end
  mount DukeAuth::Base, at: '/'
  get :authenticate, to: 'users#index'
end
