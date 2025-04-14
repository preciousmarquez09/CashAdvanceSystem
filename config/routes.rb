Rails.application.routes.draw do
  root to: "home#index"
 
  devise_for :users, controllers: {
    registrations: 'users/registrations'
  }

  # Admin 
  namespace :admin do
    resources :users do
      post :reset_password, on: :member
      collection do
        get :pdf_file
      end
    end
    resources :cash_adv_requests do
      collection do
        get :pdf_file
      end

    end
    
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

  resources :notification do
    member do
      get :read_and_redirect
    end
  end
  get 'change_password', to: 'change_password#edit_password', as: :edit_password
  patch 'change_password', to: 'change_password#update_password', as: :update_password

  resources :cashadv_file_generator

  get 'user_pdf_generator/user', to: 'user_pdf_generator#user', as: :user_pdf_generator_user
  get 'audit_logs_pdf_generator', to: 'user_pdf_generator#audit_logs'


  get 'download_complete', to: 'user_pdf_generator#download_complete'

  get 'cashadv_file_generator/select_type', to: 'cashadv_file_generator#select_type'
  post 'cashadv_file_generator/select_type', to: 'cashadv_file_generator#select_type'

  get 'cashadv_file_generator/pdf_file', to: 'cashadv_file_generator#pdf_file'
  post 'cashadv_file_generator/pdf_file', to: 'cashadv_file_generator#pdf_file'
  
  get 'cashadv_file_generator/excel_file', to: 'cashadv_file_generator#excel_file'
end
