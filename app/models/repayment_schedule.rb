class RepaymentSchedule < ApplicationRecord
  belongs_to :cash_adv_request

  validates :cash_adv_request_id, :amount, :due_date, :status, presence: true

  def self.update_due_statuses
    pending_payments = where("due_date <= ?", Date.today).where(status: 'pending')
    Rails.logger.info "[CRON] Found #{pending_payments.count} pending payments"
  
    if pending_payments.any?
      updated_count = pending_payments.update_all(status: 'paid', updated_at: Time.current)
      Rails.logger.info "[CRON] Updated #{updated_count} records."
    else
      Rails.logger.info "[CRON] No pending payments to update."
    end
  end
  
  def self.update_cashadvreq_status_to_ongoing
    # Update 'on-going' status for CashAdvRequests with due repayment schedules
    near_due_schedules = where("due_date <= ?", 15.days.from_now)
    cash_adv_request_ids = near_due_schedules.pluck(:cash_adv_request_id).uniq
  
    if cash_adv_request_ids.any?
      updated_count = CashAdvRequest.where(id: cash_adv_request_ids, status: 'released')
                                    .update_all(status: 'on-going', updated_at: Time.current)
      Rails.logger.info "[CRON] Updated #{updated_count} cash advance requests to 'on-going'."
    end
  
    # Update 'settled' status if all repayment schedules for a request are 'paid'
    settled_requests = CashAdvRequest.all.select do |cash_adv_request|
      cash_adv_request.repayment_schedules.where.not(status: 'paid').empty?
    end.map(&:id)
  
    if settled_requests.any?
      settled_count = CashAdvRequest.where(id: settled_requests).update_all(status: 'settled', updated_at: Time.current)
      Rails.logger.info "[CRON] Updated #{settled_count} cash advance requests to 'settled'."
    end
  end
  
end
