# frozen_string_literal: true

class Users::RegistrationsController < Devise::RegistrationsController
  # before_action :configure_sign_up_params, only: [:create]
  # before_action :configure_account_update_params, only: [:update]
  prepend_before_action :check_user_authentication, only: [:new, :create]
  skip_before_action :require_no_authentication, only: [:new, :create]
  def new
    session[:temporary_password] = generate_password()
    super
  end

  def create
    params[:user][:password] = session[:temporary_password] if session[:temporary_password].present?
    super do |resource|
      if resource.persisted?
        case resource.role
          when "admin" then resource.add_role(:admin)
          when "employee" then resource.add_role(:employee)
          when "finance" then resource.add_role(:finance)
        end

        # Compute and save net salary
        salary = resource.salary.to_f
        contributions = User.gov_contribution(salary)  
        resource.net_salary = salary - (contributions[:sss] + contributions[:pagibig] + contributions[:philhealth])

        flash[:notice] = "User successfully created"
        resource.save
        session.delete(:temporary_password)
        return redirect_to admin_users_path, notice: "User successfully created"
      end
    end
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
  def generate_password
    loop do
      password = SecureRandom.alphanumeric(6)
      return password if password.match?(/(?=.*[A-Z])(?=.*[a-z])(?=.*\d)/)
    end
  end
  

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

  # Allow logged-in users to register
  def require_no_authentication
    assert_is_devise_resource!
    return if action_name == 'new' || action_name == 'create'
    super
  end
end
