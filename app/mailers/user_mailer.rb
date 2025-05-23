class UserMailer < ApplicationMailer
  def notification_email(employee, notification_data)
    @employee = employee
    @notification_data = notification_data
    @eligibility = Eligibility.first
    @cash_advance_request = CashAdvRequest.find(notification_data[:cash_adv_request_id])

    if notification_data[:repayment_schedule_id].present?
      @repayment_schedule = RepaymentSchedule.find(notification_data[:repayment_schedule_id])
    end

    mail(to: @employee.email, subject: "Cash Advance Request #{notification_data[:action].capitalize}")

  end

  def finance_settlement(finance_user, settlements)
    @finance_user = finance_user
    @settlements = settlements
    mail(to: finance_user.email, subject: "Settled Cash Advance Requests #{@settlements.first[:due_date].strftime("%B %d, %Y")}")
  end
  

  
end
