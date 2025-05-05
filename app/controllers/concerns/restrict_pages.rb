module RestrictPages
    extend ActiveSupport::Concern
  
    def authorize_admin!
      unless current_user&.has_role?(:admin)
        redirect_by_role
      end
    end
  
    def authorize_finance!
      unless current_user&.has_role?(:finance)
        redirect_by_role
      end
    end

    def authorize_employee!
      unless current_user&.has_role?(:employee)
        redirect_by_role
      end
    end

    def authorize_admin_finance!
      unless current_user&.has_role?(:admin) || current_user.has_role?(:finance)
        redirect_by_role
      end
    end

    def authorize_finance_employee!
      unless current_user&.has_role?(:finance) || current_user.has_role?(:employee)
        redirect_by_role
      end
    end
  
    def redirect_by_role
      
      
      unless user_signed_in?
         flash[:alert] = "You need to sign in or sign up before continuing."
        redirect_to new_user_session_path and return
      end

      flash[:alert] = "You don’t have permission to access this page"
      if current_user.has_role?(:admin)
        redirect_to admin_dashboard_path and return
      elsif current_user.has_role?(:finance)
        redirect_to finance_dashboard_path and return
      elsif current_user.has_role?(:employee)
        redirect_to employee_dashboard_path and return
      else
        redirect_to root_path and return
      end
    end
  
  end