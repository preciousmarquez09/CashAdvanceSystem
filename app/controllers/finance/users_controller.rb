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
