class Admin::UsersController < ApplicationController
  load_and_authorize_resource
  
  include RestrictPages
  before_action :authorize_admin!
  
    def index
      @q = User.includes(:roles).ransack(params[:q])
      @pagy, @users = pagy(@q.result(distinct: true), items: 10)
    end

    def edit
      @temporary_password = generate_password()
      @user = User.includes(:roles).find(params[:id])
      @employee = User.find_by(employee_id: @user.employee_id)
      @current_cash_adv_request = @employee&.cash_adv_requests 
    end

    def update
      @user = User.find(params[:id])
      current_role = @user.roles.first&.name
    
      if params[:user][:role].present? && params[:user][:role] != current_role
        @user.roles.destroy_all
        @user.add_role(params[:user][:role])
      end
    
      if params[:user][:remove_profile] == "true"
        @user.profile_picture.purge if @user.profile_picture.attached?
      end
    
      is_current_user = (@user.id == current_user.id)
      
      salary = params[:user][:salary].to_f
      contributions = User.gov_contribution(params[:user][:salary].to_f)
      @user.net_salary = params[:user][:salary].to_f - (contributions[:sss] + contributions[:pagibig] + contributions[:philhealth])

      if @user.update(user_params)
        bypass_sign_in(@user) if is_current_user
        redirect_to admin_users_path, notice: "User updated successfully."
      else
        flash[:alert] = "Failed to update user." 
        render action: :edit, status: :unprocessable_entity
      end
    end
    
    def show
        @user = User.includes(:roles).find(params[:id])
    end

    def destroy
      @user = User.find(params[:id])

      @user.cash_adv_requests.destroy_all
      @user.approved_cash_adv_requests.destroy_all
      @user.audit_logs.destroy_all
    
      if @user.destroy
        redirect_to admin_users_path, status: :see_other, notice: "User deleted successfully."
      else
        redirect_to admin_users_path, alert: "Failed to delete user."
      end
    end

    def reset_password
      @user = User.find(params[:id])
      current_admin = current_user # Store the current admin user
        
      new_password = params[:temporary_password]
      
      if new_password.blank?
        flash[:alert] = "Temporary password is missing."
        return redirect_to edit_admin_user_path(@user)
      end
      
      if (current_user.has_role?(:admin) && @user.id != current_user.id) || !@user.has_role?(:admin)
        @user.is_first = false
      end

      if @user.update(password: new_password, password_confirmation: new_password, temporary_password: new_password)
        if @user.id == current_user.id && current_user.has_role?(:admin)
            bypass_sign_in(@user)
        end
          flash[:notice] = "Password reset successfully!"
      else
        flash[:alert] = "Failed to reset password."
      end
      redirect_to edit_admin_user_path(@user)
    end

    def pdf_file
      pdfgenerator = Pdf::UserPdfGenerator.new(params)
    
      if pdfgenerator.empty?
        flash[:alert] = "No users found"
        redirect_to admin_users_path
        return
      end
    
      send_data pdfgenerator.generate, filename: "Users List (#{Time.current.strftime('%B %-d, %Y - %I:%M %p')}).pdf" , type: 'application/pdf',disposition: 'attachment'
    end

    def excel_file
      excel_generator = Excel::UserExcelGenerator.new(params)
    
      if excel_generator.empty?
        flash[:alert] = "No users found"
        redirect_to admin_users_path
        return
      end
      
      send_data excel_generator.generate, filename: "Users List (#{Time.current.strftime('%B %-d, %Y - %I:%M %p')}).xlsx", type: "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet"
    end
      
    private
    def user_params
      permitted_params = [ :f_name, :m_name, :l_name, :birthday, :civil_status, :email, :gender, :employee_id, :job_title, :hire_date, :employment_status, 
                            :salary, :role, :temporary_password, :profile_picture, :remove_profile ]
    
      permitted_params << :password if params[:user][:password].present?
      params.require(:user).permit(permitted_params)
    end
    
    def generate_password
      loop do
        password = SecureRandom.alphanumeric(6)
        return password if password.match?(/(?=.*[A-Z])(?=.*[a-z])(?=.*\d)/)
      end
    end

end
