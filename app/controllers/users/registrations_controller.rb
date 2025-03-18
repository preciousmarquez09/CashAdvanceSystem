# frozen_string_literal: true

class Users::RegistrationsController < Devise::RegistrationsController
  # before_action :configure_sign_up_params, only: [:create]
  # before_action :configure_account_update_params, only: [:update]
  prepend_before_action :check_user_authentication, only: [:new, :create]
  skip_before_action :require_no_authentication, only: [:new, :create]
  def new
    super
  end

  def create
    super
  end
  # GET /resource/sign_up
  # def new
  #   super
  # end

  # POST /resource
  # def create
  #   super
  # end

  # GET /resource/edit
  # def edit
  #   super
  # end

  # PUT /resource
  # def update
  #   super
  # end

  # DELETE /resource
  # def destroy
  #   super
  # end

  # GET /resource/cancel
  # Forces the session data which is usually expired after sign
  # in to be expired now. This is useful if the user wants to
  # cancel oauth signing in/up in the middle of the process,
  # removing all OAuth session data.
  # def cancel
  #   super
  # end

  # protected

  # If you have extra params to permit, append them to the sanitizer.
  # def configure_sign_up_params
  #   devise_parameter_sanitizer.permit(:sign_up, keys: [:attribute])
  # end

  # If you have extra params to permit, append them to the sanitizer.
  # def configure_account_update_params
  #   devise_parameter_sanitizer.permit(:account_update, keys: [:attribute])
  # end

  # The path used after sign up.
  # def after_sign_up_path_for(resource)
  #   super(resource)
  # end

  # The path used after sign up for inactive accounts.
  # def after_inactive_sign_up_path_for(resource)
  #   super(resource)
  # end

  private

  def redirect_if_not_authenticated
    unless user_signed_in?
      redirect_to new_user_session_path, alert: "You must be logged in to register a new account."
    end
  end
  
  def check_user_authentication
    unless user_signed_in?
      redirect_to new_user_session_path, alert: "You must be logged in to register a new account."
    end
  end
  
  # This ensures flash messages are preserved through the redirect
  def set_flash_message!(*args)
    return super(*args) if signed_in?
    super(*args) if is_flashing_format?
  end
  
  # Allow logged-in users to register
  def require_no_authentication
    assert_is_devise_resource!
    return if action_name == 'new' || action_name == 'create'
    # For other actions, use the default behavior
    super
  end
end
