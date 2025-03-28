class ApplicationController < ActionController::Base
  include Pagy::Backend
  before_action :configure_permitted_parameters, if: :devise_controller?

  rescue_from CanCan::AccessDenied do |exception|
    flash[:alert] = "You don’t have permission to access this page"
    redirect_to root_path
  end

  def after_sign_in_path_for(resource)
    user = resource.is_a?(User) ? resource : current_user

    # Redirect first-time login to change password
    return edit_password_path if (user.has_role?(:employee) || user.has_role?(:finance)) && user.is_first == false
   

    # Redirect users based on role
    if user.has_role?(:admin)
      admin_dashboard_path
    elsif user.has_role?(:finance)
      finance_dashboard_path
    elsif user.has_role?(:employee)
      employee_dashboard_path
    else
      root_path 
    end
  end

  # Redirect after password change
  def after_update_path_for(resource)
    user = resource.is_a?(User) ? resource : current_user

    if user.has_role?(:admin)
      admin_dashboard_path
    elsif user.has_role?(:finance)
      finance_dashboard_path
    elsif user.has_role?(:employee)
      employee_dashboard_path
    else
      root_path
    end
  end

  protected

  def configure_permitted_parameters
    devise_parameter_sanitizer.permit(:sign_up, keys: [:profile_picture, :role, :employee_id, :f_name, :m_name, :l_name, :birthday, :civil_status, :gender, :job_title, :employment_status, :hire_date, :salary, :temporary_password])
    devise_parameter_sanitizer.permit(:account_update, keys: [:profile_picture, :role, :employee_id, :f_name, :m_name, :l_name, :birthday, :civil_status, :gender, :job_title, :employment_status, :hire_date, :salary, :temporary_password])
  end

  def after_sign_out_path_for(resource_or_scope)
    new_user_session_path # Redirect to login page after logout
  end
end
