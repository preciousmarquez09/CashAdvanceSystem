module Employee
    class ProfileController < ApplicationController
      before_action :authenticate_user!

      include RestrictPages
      before_action :authorize_employee!
      
      def index
        @user = current_user
      end
  
      def update
        @user = current_user
        if params[:user]&.dig(:profile_picture).present?
          if @user.update(user_params)
            redirect_to employee_profile_path, notice: "Profile Picture updated successfully."
          else
            redirect_to employee_profile_path, alert: "Failed to update profile picture."
          end
        else
          redirect_to employee_profile_path, alert: "Select a photo to change."
        end
      end
  
      private
      def user_params
        params.require(:user).permit(:profile_picture)
      end
    end
  end
  