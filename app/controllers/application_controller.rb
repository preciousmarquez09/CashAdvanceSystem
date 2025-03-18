class ApplicationController < ActionController::Base

  before_action :configure_permitted_parameters, if: :devise_controller?

  protected

  def configure_permitted_parameters
    devise_parameter_sanitizer.permit(:sign_up, keys: [:role, :employee_id, :f_name, :m_name, :l_name, :birthday, :civil_status, :gender, :job_title, :employment_status, :hire_date, :salary])
    devise_parameter_sanitizer.permit(:account_update, keys: [:role, :employee_id, :f_name, :m_name, :l_name, :birthday, :civil_status, :gender, :job_title, :employment_status, :hire_date, :salary])
  end
  def after_sign_out_path_for(resource_or_scope)
    new_user_session_path # Redirect to login page after logout
  end
end
