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

    get "dashboard", to: "dashboard#index"
  end

  get 'change_password', to: 'change_password#edit_password', as: :edit_password
  patch 'change_password', to: 'change_password#update_password', as: :update_password

  
  get 'eligibilities', to: 'eligibilities#edit_eligibility', as: :edit_eligibility
  patch 'eligibilities', to: 'eligibilities#update_eligibility', as: :update_eligibility
  
end
