Rails.application.routes.draw do
  resources :users, only: [:index, :create] do
    get 'use', on: :member

    collection do
      get 'stats'
      get 'fetch'
    end
  end
end
