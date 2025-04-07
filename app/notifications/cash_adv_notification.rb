# To deliver this notification:
#
# CashAdvNotification.with(post: @post).deliver_later(current_user)
# CashAdvNotification.with(post: @post).deliver(current_user)


class CashAdvNotification < Noticed::Base
  # Add your delivery methods
  #
    deliver_by :database
    deliver_by :action_cable
  # deliver_by :email, mailer: "UserMailer"
  # deliver_by :slack
  # deliver_by :custom, class: "MyDeliveryMethod"

  param :cash_adv_request_id
  param :action
  # Add required params
  #
  # param :post
  
  def message
    user = User.find_by(employee_id: params[:employee_id])
    if user.nil?
      return "User not found for employee ID: #{params[:employee_id]}"
    end
  
    cash_adv_status = [ "declined", "approved"]
    if params[:action] == "pending"
      cash_adv_request_id = CashAdvRequest.find_by(id: params[:cash_adv_request_id])
      "#{user.f_name} #{user.l_name} requested a new cash advance."
    elsif cash_adv_status.include?(params[:action])
      cash_adv_request_id = CashAdvRequest.find_by(id: params[:cash_adv_request_id])
      "Your cash advance updated to #{params[:action]}"
    elsif params[:action] == "released"
      cash_adv_request_id = CashAdvRequest.find_by(id: params[:cash_adv_request_id])
      "Your cash advance is already #{params[:action]}."
    elsif params[:action] == "on-going"
      cash_adv_request_id = CashAdvRequest.find_by(id: params[:cash_adv_request_id])
      "Your cash advance is #{params[:action]}. It will deduct to your next payroll"
    elsif params[:action] == "paid"
      cash_adv_request_id = CashAdvRequest.find_by(id: params[:cash_adv_request_id])
      repayment_schedule_id = RepaymentSchedule.find_by(id: params[:repayment_schedule_id])
      "Your cash advance for #{repayment_schedule_id&.due_date&.strftime('%B %d, %Y') || 'unknown date'} successfully paid."
    elsif params[:action] == "settled"
      cash_adv_request_id = CashAdvRequest.find_by(id: params[:cash_adv_request_id])
      "Your cash advance successfully settled."
    end
  end
  

  # Define helper methods to make rendering easier.
  #
  # def message
  #   t(".message")
  # end
  #
  def url
    # This should use a Rails path helper
    Rails.application.routes.url_helpers.admin_cash_adv_request_path(params[:cash_adv_request_id])
  end
end
