Rails.application.routes.draw do
  root to: "home#index"

  devise_for :users, controllers: {
    registrations: 'users/registrations'
  }

  namespace :admin do
    resources :users do
      post :reset_password, on: :member
    end

    get "dashboard", to: "dashboard#index"
  end
end
