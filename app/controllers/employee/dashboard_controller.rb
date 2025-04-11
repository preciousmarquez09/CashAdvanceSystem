module Employee
    class DashboardController < ApplicationController
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
        
        @total_cash_advance = current_user.cash_adv_requests.where(status: 'released').sum(:amount)

        @pending_cash_advances = current_user.cash_adv_requests.pending.count
      
        @q = current_user.cash_adv_requests.ransack(params[:q])
        @pagy_cash_advance_history, @cash_advance_history = pagy(@q.result.order(created_at: :desc), 
        items: 10, page_param: :page_cash_adv_history)

        @pagy_employee_payrolls, @employee_payrolls = pagy(current_user.payrolls.order(created_at: :desc),
        items: 10,
        page_param: :page_employee_payrolls
        )
      end
    end
  end
  