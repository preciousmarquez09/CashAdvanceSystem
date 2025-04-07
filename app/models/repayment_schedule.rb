class RepaymentSchedule < ApplicationRecord
  belongs_to :cash_adv_request
  has_many :notifications, dependent: :destroy
  
  validates :cash_adv_request_id, :amount, :due_date, :status, presence: true
  
  def self.update_due_statuses
    pending_payments = where("due_date <= ?", Date.today).where(status: 'pending')
    Rails.logger.info "[CRON] Found #{pending_payments.count} pending payments"
  
    if pending_payments.any?
      updated_count = 0
  
      pending_payments.each do |payment|
        begin
          ActiveRecord::Base.transaction do
            # Update the payment status to 'paid'
            payment.update!(status: 'paid', updated_at: Time.current)
  
            # Get the cash_adv_request_id from the repayment schedule
            cash_adv_request = CashAdvRequest.find_by(id: payment.cash_adv_request_id)
            
            if cash_adv_request
              # Retrieve the employee_id from the CashAdvRequest
              employee = User.find_by(employee_id: cash_adv_request.employee_id)
  
              if employee
                notification_data = {
                  employee_id: employee.employee_id,
                  cash_adv_request_id: cash_adv_request.id,
                  repayment_schedule_id: payment.id,
                  action: 'paid'
                }
                UserMailer.notification_email(employee, notification_data).deliver_now
                # Deliver the notification
                CashAdvNotification.with(notification_data).deliver(employee)
              end
            end
  
            updated_count += 1
          end
        rescue => e
          Rails.logger.error "[CRON] Error updating payment #{payment.id}: #{e.message}"
        end
      end
  
      Rails.logger.info "[CRON] Updated #{updated_count} pending payments to 'paid'."
    else
      Rails.logger.info "[CRON] No pending payments to update."
    end
  end
  

  def self.update_cashadvreq_status_to_ongoing
    near_due_schedules = where("due_date <= ?", 15.days.from_now)
    cash_adv_request_ids = near_due_schedules.pluck(:cash_adv_request_id).uniq
    
    updated_count = 0
    
    if cash_adv_request_ids.present?
      CashAdvRequest.where(id: cash_adv_request_ids, status: 'released').each do |cash_adv_request|
        begin
          ActiveRecord::Base.transaction do
            cash_adv_request.update!(status: 'on-going')
            
            employee = User.find_by(employee_id: cash_adv_request.employee_id)
            if employee
                notification_data = {
                  employee_id: employee.employee_id,
                  cash_adv_request_id: cash_adv_request.id,
                  action: 'on-going'
                }
                UserMailer.notification_email(employee, notification_data).deliver_now
                # Deliver the notification
                CashAdvNotification.with(notification_data).deliver(employee)
            end
          end
          
          updated_count += 1
        rescue => e
          Rails.logger.error "[CRON] Error updating cash advance request #{cash_adv_request.id}: #{e.message}"
        end
      end
      
      Rails.logger.info "[CRON] Updated #{updated_count} cash advance requests to 'on-going'."
    end
  end
  

  def self.update_cashadvreq_status_to_settled
    settled_requests = CashAdvRequest.all.select do |cash_adv_request| 
      cash_adv_request.repayment_schedules.any? && 
      cash_adv_request.repayment_schedules.where.not(status: 'paid').empty? && 
      cash_adv_request.status != 'settled'
    end
  
    if settled_requests.any?
      # Process each request individually
      updated_count = 0
  
      settled_requests.each do |cash_adv_request|
        begin
          ActiveRecord::Base.transaction do
            # Update the status to 'settled'
            cash_adv_request.update!(status: 'settled')
  
            # Find the employee to notify
            employee = User.find_by(employee_id: cash_adv_request.employee_id)
  
            if employee
              notification_data = {
                employee_id: employee.employee_id,
                cash_adv_request_id: cash_adv_request.id,
                action: 'settled'
              }
              UserMailer.notification_email(employee, notification_data).deliver_now
                # Deliver the notification
              CashAdvNotification.with(notification_data).deliver(employee)
  
              Rails.logger.info "[CRON] Settlement notification sent to employee #{employee.employee_id} for request ID #{cash_adv_request.id}"
            else
              Rails.logger.info "[CRON] No user found for employee_id: #{cash_adv_request.employee_id}, no settlement notification sent."
            end
  
            updated_count += 1
          end
        rescue => e
          Rails.logger.error "[CRON] Error updating cash advance request #{cash_adv_request.id}: #{e.message}"
        end
      end
  
      Rails.logger.info "[CRON] Updated #{updated_count} cash advance requests to 'settled'."
    else
      Rails.logger.info "[CRON] No cash advance requests to update to 'settled'."
    end
  end
  


  
end
