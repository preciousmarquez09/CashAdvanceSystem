module Employee
    class DashboardController < ApplicationController
      include Pagy::Backend
      before_action :authenticate_user!
  
      def index
        @eligibility = Eligibility.first
        @eligible = current_user&.salary.to_f >= @eligibility&.min_net_salary.to_f
        
        @total_cash_advance = current_user.cash_adv_requests
        .where(status: ['released', 'on-going', 'settled'])
        .sum("amount + interest_amount")

        @current_user_pending_cash_advances = current_user.cash_adv_requests.pending.count

        @released_cash_advances = current_user.cash_adv_requests.where(status: ['released', 'on-going', 'settled']).count
        CashAdvRequest.where(status: ['released', 'on-going', 'settled']).count

        day_cutoff = Date.today.day <= 15 ? 15 : 30

        @due_next_payroll_records = RepaymentSchedule
        .includes(cash_adv_request: :employee)
        .where("DAY(due_date) = ?", day_cutoff)
        .where("due_date <= ?", Time.current.end_of_month)
        .where(status: "pending")
        .where("cash_adv_requests.employee_id = ?", current_user.employee_id)

        @current_user_approved_cash_advances = current_user.cash_adv_requests.where(status: 'approved').count
      
        @due_next_payroll_total = @due_next_payroll_records.sum(:amount)
        @due_next_payroll_date = @due_next_payroll_records.minimum(:due_date) # earliest among them

        @current_user_has_ongoing_repayment = RepaymentSchedule
        .joins(cash_adv_request: :employee)
        .where(cash_adv_requests: { employee_id: current_user.employee_id })
        .where("DATE(repayment_schedules.due_date) >= ?", Date.current)
        .where(status: 'pending')
        .exists?

        @pagy_employee_payrolls, @employee_payrolls = pagy(current_user.payrolls.order(created_at: :desc),
        items: 10,
        page_param: :page_employee_payrolls
        )
      end
    end
  end
  