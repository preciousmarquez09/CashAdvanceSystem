class Finance::UsersController < ApplicationController
  load_and_authorize_resource
  before_action :authenticate_user!

  include RestrictPages
  before_action :authorize_finance!
  
  def index
    @eligibility = Eligibility.first
    @eligible = current_user&.salary.to_f >= @eligibility&.min_net_salary.to_f

    @next_payroll = next_payroll_date()
    @q = User.includes(:roles, :cash_adv_requests)
             .ransack(params[:q])
    @pagy, @users = pagy(@q.result(distinct: true), items: 10)
  
    # Users with at least one cash advance request matching specific statuses
    @users_with_cash_adv = User.joins(:cash_adv_requests)
                               .where(cash_adv_requests: { status: ["pending", "approved", "released", "on-going"] })
                               .distinct
    #repayment amount for next payroll for each user
    @user_schedules = {}
    @users.each do |user|
      total_amount = RepaymentSchedule.joins(:cash_adv_request)
        .where(cash_adv_requests: { employee_id: user.employee_id })
        .where(status: ['pending', 'paid'])
        .where(due_date: @next_payroll.to_date)
        .sum(:amount)

      @user_schedules[user.id] = total_amount if total_amount > 0
    end

  end
  
  def next_payroll_date
    today = Date.today
    if today.day <= 15
      Date.new(today.year, today.month, 15)
    else
      Date.new(today.year, today.month, 30)
    end
  end

end
