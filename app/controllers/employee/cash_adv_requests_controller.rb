class Employee::CashAdvRequestsController < ApplicationController
        load_and_authorize_resource
        before_action :authenticate_user!
        
        include RestrictPages
        before_action :authorize_employee!
        
        def index
            @eligibility = Eligibility.first
            @eligible = current_user&.salary.to_f >= @eligibility&.min_net_salary.to_f

            @cash_adv_request = current_user.cash_adv_requests.where(status: ['released', 'on-going']).last
            if @cash_adv_request.present?
              @repayment_schedules = @cash_adv_request.repayment_schedules
            else
              @repayment_schedules = [] 
            end
          
            # Convert params[:q] to an unsafe hash to avoid strong parameters filtering
            @q = CashAdvRequest.includes(:employee).ransack(params[:q]&.to_unsafe_h || {})
          
            @pagy, @cash_adv_requests = pagy(@q.result.where(employee_id: current_user.employee_id).order(created_at: :desc), items: 10)
          
            
        end
        
        
end
    