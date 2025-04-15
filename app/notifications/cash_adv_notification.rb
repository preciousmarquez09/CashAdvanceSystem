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

    cash_adv_request = CashAdvRequest.find_by(id: params[:cash_adv_request_id])
    if cash_adv_request.nil?
      return "Cash advance request not found for ID: #{params[:cash_adv_request_id]}"
    end
  
    cash_adv_status = [ "declined", "approved"]
    if params[:action] == "pending"
      "#{user.f_name} #{user.l_name} requested a new cash advance."
    elsif cash_adv_status.include?(params[:action])
      "Your cash advance updated to #{params[:action]}"
    elsif params[:action] == "released"
      "Your cash advance is already #{params[:action]}."
    elsif params[:action] == "on-going"
      "Your cash advance is #{params[:action]}. It will deduct to your next payroll"
    elsif params[:action] == "paid"
      repayment_schedule_id = RepaymentSchedule.find_by(id: params[:repayment_schedule_id])
      "Your cash advance for #{repayment_schedule_id&.due_date&.strftime('%B %d, %Y') || 'unknown date'} successfully paid."
    elsif params[:action] == "settled"
      if params[:message]
        "#{user.f_name} #{user.l_name} cash advance successfully settled."
      else
        "Your cash advance successfully settled."
      end
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
