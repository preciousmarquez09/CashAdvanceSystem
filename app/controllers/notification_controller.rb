class NotificationController < ApplicationController
  before_action :authenticate_user!

  def index
    user = User.find_by(employee_id: current_user.employee_id)
    
    if user
      if current_user.has_role?(:finance)
        # Paginate and group own notifications
        @pagy_own, @own_notifications = pagy(user.notifications.where(employee_id: user.employee_id).where.not(action: 'pending').where(message: nil)
                                          .order(created_at: :desc), items: 5, page_param: :page_own)
        @grouped_own_notifications = @own_notifications.group_by { |notification| notification.created_at.to_date }
      
        # Paginate and group other notifications
        @pagy_other, @other_notifications = pagy(user.notifications.where(action: ['pending', 'settled'])
                                              .where("employee_id = ? OR employee_id != ?", user.employee_id, user.employee_id)
                                              .order(created_at: :desc), items: 5, page_param: :page_other)
        @grouped_other_notifications = @other_notifications.group_by { |notification| notification.created_at.to_date }
      else 
        # Paginate all notifications for non-finance users
        @pagy, @all_notifications = pagy(user.notifications.order(created_at: :desc), items: 10)
        @grouped_notifications = @all_notifications.group_by { |notification| notification.created_at.to_date }
      end
    else
      flash[:alert] = "User not found"
      redirect_to root_path
    end
  end
  

  def read_and_redirect
    notification = current_user.notifications.find(params[:id])
    cash_adv_req = CashAdvRequest.find(notification.params[:cash_adv_request_id])
    status_choice = ['pending', 'approved']

    if current_user.has_role?(:finance)
      mark_read = Notification.where(cash_adv_request_id: notification.cash_adv_request_id, action: notification.action)
      mark_read.each do |notif|
        notif.mark_as_read! # Mark the notification for the finance as read
      end
    else
      notification.mark_as_read! # Mark the personal notification as read
    end

    if (status_choice.include?(cash_adv_req.status) && current_user.has_role?(:finance))
      redirect_to edit_admin_cash_adv_request_path(notification.params[:cash_adv_request_id])
    else
      redirect_to admin_cash_adv_request_path(notification.params[:cash_adv_request_id])
    end
  end
end
