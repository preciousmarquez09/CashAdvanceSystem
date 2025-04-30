module RestrictPages
    extend ActiveSupport::Concern
  
    def authorize_admin!
      unless current_user.has_role?(:admin)
        redirect_by_role
      end
    end
  
    def authorize_finance!
      unless current_user.has_role?(:finance)
        redirect_by_role
      end
    end

    def authorize_employee!
      unless current_user.has_role?(:employee)
        redirect_by_role
      end
    end

    def authorize_admin_finance!
      unless current_user.has_role?(:admin) || current_user.has_role?(:finance)
        redirect_by_role
      end
    end

    def authorize_finance_employee!
      unless current_user.has_role?(:finance) || current_user.has_role?(:employee)
        redirect_by_role
      end
    end
  
    def redirect_by_role
      if current_user.has_role?(:admin)
        flash[:alert] = "You don’t have permission to access this page"
        redirect_to admin_dashboard_path
      elsif current_user.has_role?(:finance)
        flash[:alert] = "You don’t have permission to access this page"
        redirect_to finance_dashboard_path
      elsif current_user.has_role?(:employee)
        flash[:alert] = "You don’t have permission to access this page"
        redirect_to employee_dashboard_path
      else
        flash[:alert] = "You don’t have permission to access this page"
        redirect_to root_path
      end
    end
  end