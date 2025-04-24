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

        @myaccount_pending_cash_advances = current_user.cash_adv_requests.pending.count

        @released_cash_advances = current_user.cash_adv_requests.released.count

        day_cutoff = Date.today.day <= 15 ? 15 : 30
        @due_next_payroll_records = RepaymentSchedule
        .includes(cash_adv_request: :employee)
        .where("DAY(due_date) = ?", day_cutoff)
        .where("due_date <= ?", Time.current.end_of_month)
        .where("cash_adv_requests.employee_id = ?", current_user.employee_id)
      
        @due_next_payroll_total = @due_next_payroll_records.sum(:amount)
        @due_next_payroll_date = @due_next_payroll_records.minimum(:due_date) # earliest among them

        @myaccount_has_ongoing_repayment = RepaymentSchedule
        .joins(cash_adv_request: :employee)
        .where(cash_adv_requests: { employee_id: current_user.employee_id })
        .where("repayment_schedules.due_date >= ?", Time.current)
        .where.not(status: 'paid') # adjust if you track status differently
        .exists?
        
      
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
  