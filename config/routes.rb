Rails.application.routes.draw do
  
  root to: "home#index"

 
  devise_for :users, controllers: {
    registrations: 'users/registrations'
  }

  # Admin 
  namespace :admin do
    resources :users do
      post :reset_password, on: :member
    end
    get "dashboard", to: "dashboard#index"
  end

  # Employee 
  namespace :employee do
    get "dashboard", to: "dashboard#index"
  end

  # Finance
  namespace :finance do
    get "dashboard", to: "dashboard#index"
  end

  
  get 'change_password', to: 'change_password#edit_password', as: :edit_password
  patch 'change_password', to: 'change_password#update_password', as: :update_password

  
  get 'eligibilities', to: 'eligibilities#edit_eligibility', as: :edit_eligibility
  patch 'eligibilities', to: 'eligibilities#update_eligibility', as: :update_eligibility
end
