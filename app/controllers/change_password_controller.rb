class ChangePasswordController < ApplicationController
  before_action :authenticate_user!
  before_action :authorize_update_password

  def edit_password
    @user = current_user
  end

  def update_password
    @user = current_user
    first_loggedin = @user.is_first
  
    if @user.update(user_params)
      
      @user.update_columns(is_first: true)
      # Keep the user signed in after password change
      @user.update(is_first: true)
      bypass_sign_in(@user)
      redirect_to first_loggedin ? edit_password_path : after_sign_in_path_for(current_user), notice: "Password updated successfully."
    else
      render :edit_password, status: :unprocessable_entity
    end
  end

  private

  def user_params
    params.require(:user).permit(:password, :password_confirmation)
  end

  def authorize_update_password
    authorize! :update_password, current_user
  end
end
