Rails.application.routes.draw do
  # For details on the DSL available within this file, see https://guides.rubyonrails.org/routing.html
  root to: "home#index"

  devise_for :users, controllers: {
    registrations: 'users/registrations'
  }
  namespace :admin do
    resources :users do
      post :reset_password, on: :member
    end
  end
  
  
end
