class Finance::DashboardController < ApplicationController
  include Pagy::Backend
  before_action :authenticate_user!
  
  def index
    @cash_adv_request = current_user.cash_adv_requests.first
    if @cash_adv_request.present?
      @repayment_schedules = @cash_adv_request.repayment_schedules
    else
      @repayment_schedules = [] 
    end

    @total_pending_requests = CashAdvRequest.where(status: 'pending').count
    @total_released_requests = CashAdvRequest.where(status: 'released').count
    @total_ongoing_cash_advances = CashAdvRequest.where(status: 'ongoing').count
    @total_cash_advances_year = CashAdvRequest.where("created_at >= ?", Time.current.beginning_of_year).sum(:amount)
    
    @total_ongoing_users = RepaymentSchedule.where(status: 'pending')
    .distinct
    .count(:cash_adv_request_id)

    @pagy_due_next_payroll, @due_next_payroll = pagy(RepaymentSchedule
    .includes(cash_adv_request: :employee)
    .where("DAY(due_date) IN (15, 30)")
    .where("due_date <= ?", Time.current.end_of_month)
    .order(:due_date),
    items: 10,
    page_param: :page_due_next_payroll
    )
    @pagy_payrolls, @payrolls = pagy(current_user.payrolls.order(created_at: :desc),
    items: 10,
    page_param: :page_payrolls
    )
  end
end