class Finance::UsersController < ApplicationController
  load_and_authorize_resource
  
  def index
    @eligibility = Eligibility.first
    @next_payroll = next_payroll_date()
    @q = User.includes(:roles, :cash_adv_requests)
             .ransack(params[:q])
    @pagy, @users = pagy(@q.result(distinct: true), items: 10)
  
    # Users with at least one cash advance request matching specific statuses
    @users_with_cash_adv = User.joins(:cash_adv_requests)
                               .where(cash_adv_requests: { status: ["pending", "approved", "released", "on-going"] })
                               .distinct
                            
    # Determine cutoff range based on next payroll
    from_date, to_date = if @next_payroll.day == 15
      [Date.today.beginning_of_month, Date.new(Date.today.year, Date.today.month, 15)]
    else
      [Date.new(Date.today.year, Date.today.month, 16), Date.today.end_of_month]
    end
    
    @user_schedules = {}
    @users.each do |user|
      total_amount = RepaymentSchedule.joins(:cash_adv_request)
        .where(cash_adv_requests: { employee_id: user.employee_id })
        .where(status: 'pending', due_date: from_date..to_date)
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
