class Finance::DashboardController < ApplicationController
  include Pagy::Backend
  before_action :authenticate_user!
  
  def index

    @eligibility = Eligibility.first
    @eligible = current_user&.salary.to_f >= @eligibility&.min_net_salary.to_f
    
    @cash_adv_request = current_user.cash_adv_requests.first
    if @cash_adv_request.present?
      @repayment_schedules = @cash_adv_request.repayment_schedules
    else
      @repayment_schedules = [] 
    end

    @total_pending_requests = CashAdvRequest.where(status: 'pending').count
    @total_released_requests = CashAdvRequest.where(status: ['released', 'on-going', 'settled']).count
    @total_ongoing_cash_advances = CashAdvRequest.where(status: 'on-going').count
    @total_cash_advances_year = CashAdvRequest
    .where("created_at >= ?", Time.current.beginning_of_year)
    .where(status: ['released', 'on-going', 'settled'])
    .sum("amount + interest_amount")

    @total_interest_earned_year = CashAdvRequest
    .where("created_at >= ?", Time.current.beginning_of_year)
    .where(status: ['released', 'on-going', 'settled'])
    .sum(:interest_amount)
  

    
    @total_ongoing_users = RepaymentSchedule.where(status: 'pending')
    .distinct
    .count(:cash_adv_request_id)

    @myaccount_total_cash_advance = current_user.cash_adv_requests.where(status: ['released', 'on-going', 'settled']).sum(:amount)

    @myaccount_pending_cash_advances = current_user.cash_adv_requests.pending.count

    @myaccount_released_cash_advances = current_user.cash_adv_requests.where(status: ['released', 'on-going', 'settled']).count

    @myaccount_approved_cash_advances = current_user.cash_adv_requests.where(status: 'approved').count

    day_cutoff = Date.today.day <= 15 ? 15 : 30

    day_cutoff = Date.today.day <= 15 ? 15 : 30

    @myaccount_due_next_payroll_records = RepaymentSchedule
    .includes(cash_adv_request: :employee)
    .where("DAY(due_date) = ?", day_cutoff)
    .where("due_date <= ?", Time.current.end_of_month)
    .where(status: "pending")
    .where("cash_adv_requests.employee_id = ?", current_user.employee_id)
  
    @myaccount_due_next_payroll_total = @myaccount_due_next_payroll_records.sum(:amount)
    @myaccount_due_next_payroll_date = @myaccount_due_next_payroll_records.minimum(:due_date)

    @myaccount_has_ongoing_repayment = RepaymentSchedule
    .joins(cash_adv_request: :employee)
    .where(cash_adv_requests: { employee_id: current_user.employee_id })
    .where("DATE(repayment_schedules.due_date) >= ?", Date.current)
    .where(status: 'pending')
    .exists?
  
 


    @pagy_due_next_payroll, @due_next_payroll = pagy(
      RepaymentSchedule
        .includes(cash_adv_request: :employee)
        .where("DAY(due_date) = ?", day_cutoff)
        .where("due_date <= ?", Time.current.end_of_month)
        .where(status: "pending")
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