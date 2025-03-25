class ChangePasswordController < ApplicationController
  before_action :authenticate_user!

  def edit_password
    @user = current_user
  end

  def update_password
    @user = current_user

    if @user.update(user_params)
      # Keep the user signed in after password change
      bypass_sign_in(@user) 
      redirect_to edit_password_path, notice: "Password updated successfully."
    else
      render :edit_password, status: :unprocessable_entity
    end
  end

  private

  def user_params
    params.require(:user).permit(:password, :password_confirmation)
  end
end
