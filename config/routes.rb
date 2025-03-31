Rails.application.routes.draw do
  get 'repayment_schedules/index'
  # For details on the DSL available within this file, see https://guides.rubyonrails.org/routing.html

  root to: "home#index"

  devise_for :users, controllers: {
    registrations: 'users/registrations'
  }

  namespace :admin do
    resources :users do
      post :reset_password, on: :member
    end
    resources :cash_adv_requests

    get "dashboard", to: "dashboard#index"
    get 'eligibilities', to: 'eligibilities#edit_eligibility', as: :edit_eligibility
    patch 'eligibilities', to: 'eligibilities#update_eligibility', as: :update_eligibility
    
  end

  get 'change_password', to: 'change_password#edit_password', as: :edit_password
  patch 'change_password', to: 'change_password#update_password', as: :update_password
end
