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
    resources :cash_adv_requests
    
    get 'eligibilities', to: 'eligibilities#edit_eligibility', as: :edit_eligibility
    patch 'eligibilities', to: 'eligibilities#update_eligibility', as: :update_eligibility
    get "dashboard", to: "dashboard#index"
  end

  # Employee 
  namespace :employee do
    get "dashboard", to: "dashboard#index"
    get '/profile', to: 'profile#index', as: 'profile'
     patch '/profile', to: 'profile#update'
  end

  # Finance
  namespace :finance do
    get "dashboard", to: "dashboard#index"
    get '/profile', to: 'profile#index', as: 'profile'
     patch '/profile', to: 'profile#update'
    resources :users
  end

  
  get 'change_password', to: 'change_password#edit_password', as: :edit_password
  patch 'change_password', to: 'change_password#update_password', as: :update_password
end
