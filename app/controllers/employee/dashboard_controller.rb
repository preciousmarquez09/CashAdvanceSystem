module Employee
    class DashboardController < ApplicationController
      before_action :authenticate_user!
  
      def index
        @eligibility = Eligibility.first
        @eligible = current_user&.salary.to_f >= @eligibility&.min_net_salary.to_f
        
        @total_cash_advance = current_user.cash_adv_requests.sum(:amount)
        @pending_cash_advances = current_user.cash_adv_requests.pending.count
        @cash_advance_history = current_user.cash_adv_requests.order(created_at: :desc)
        #@approved_cash_advances = current_user.cash_adv_requests.approved.order(due_date: :asc)
      end
    end
  end
  