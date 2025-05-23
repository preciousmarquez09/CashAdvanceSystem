class Finance::DashboardController < ApplicationController
  include Pagy::Backend
  include RestrictPages
  
  before_action :authorize_finance!
  before_action :authenticate_user!
  
  def index

    @eligibility = Eligibility.first
    @eligible = current_user&.salary.to_f >= @eligibility&.min_net_salary.to_f
    
    @cash_adv_request = current_user.cash_adv_requests.where(status: ['released', 'on-going']).last
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

    @myaccount_total_cash_advance = current_user.cash_adv_requests.where("created_at >=?", Time.current.beginning_of_year)
                                                                  .where(status: ['released', 'on-going', 'settled'])
                                                                  .sum("amount + interest_amount")

    @myaccount_pending_cash_advances = current_user.cash_adv_requests.pending.count

    @myaccount_released_cash_advances = current_user.cash_adv_requests.where(status: ['released', 'on-going', 'settled']).count

    @myaccount_approved_cash_advances = current_user.cash_adv_requests.where(status: 'approved').count

    today = Date.today
    if today.day <= 15
      pay_date = Date.new(today.year, today.month, 15)
    else
      pay_date = Date.new(today.year, today.month, 30)
    end
    
    @myaccount_due_next_payroll_records = RepaymentSchedule
      .joins(cash_adv_request: :employee)
      .includes(cash_adv_request: :employee)
      .where(due_date: pay_date)
      .where(status: "pending")
      .where(cash_adv_requests: { employee_id: current_user.employee_id })
    
    @pagy_due_next_payroll, @due_next_payroll = pagy(
      RepaymentSchedule
        .joins(cash_adv_request: :employee)
        .includes(cash_adv_request: :employee)
        .where(due_date: pay_date)
        .order(:due_date),
      items: 10,
      page_param: :page_due_next_payroll
    )
    @next_payroll = pay_date
  
    @myaccount_due_next_payroll_total = @myaccount_due_next_payroll_records.sum(:amount)
    @myaccount_due_next_payroll_date = @myaccount_due_next_payroll_records.minimum(:due_date)

    @myaccount_has_ongoing_repayment = RepaymentSchedule
    .joins(cash_adv_request: :employee)
    .where(cash_adv_requests: { employee_id: current_user.employee_id })
    .where("DATE(repayment_schedules.due_date) >= ?", Date.current)
    .where(status: 'pending')
    .exists?

    @pagy_payrolls, @payrolls = pagy(current_user.payrolls.order(created_at: :desc),
    items: 10,
    page_param: :page_payrolls
    )
  end
end