class Admin::UsersController < ApplicationController
  load_and_authorize_resource
  
    def index
      @q = User.includes(:roles).ransack(params[:q])
      @pagy, @users = pagy(@q.result(distinct: true), items: 10)
    end

    def edit
      @temporary_password = generate_password()
      @user = User.includes(:roles).find(params[:id])
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
    
      if @user.update(user_params)
        bypass_sign_in(@user) if is_current_user
        redirect_to admin_users_path, notice: "User updated successfully."
      else
        render action: :edit, status: :unprocessable_entity
      end
    end
    
    def show
        @user = User.includes(:roles).find(params[:id])
    end

    def destroy
      @user = User.find(params[:id])
    
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
      
      if current_user.has_role?(:admin) && @user.id != current_user.id
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
