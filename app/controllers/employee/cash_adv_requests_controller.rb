class Employee::CashAdvRequestsController < ApplicationController
        load_and_authorize_resource
        include RestrictPages
  
        before_action :authorize_employee!
        def index
            @eligibility = Eligibility.first
            @eligible = current_user&.salary.to_f >= @eligibility&.min_net_salary.to_f

            #@cash_adv_request = current_user.cash_adv_requests.first
            @cash_adv_request = current_user.cash_adv_requests.where(status: ['released', 'on-going']).last
            if @cash_adv_request.present?
              @repayment_schedules = @cash_adv_request.repayment_schedules
            else
              @repayment_schedules = [] 
            end
          
            # Convert params[:q] to an unsafe hash to avoid strong parameters filtering
            @q = CashAdvRequest.includes(:employee).ransack(params[:q]&.to_unsafe_h || {})
          
            # Get the status from params or default to 'all'
            @status = params[:status] || 'all'
          
            if params[:q].present? && params[:status].blank?
              @status = 'all'
            end
          
            # Apply the search query but keep status count, and filter by current user
            @filtered_results = @q.result(distinct: false).where(employee_id: current_user.employee_id)
          
            # Apply status filter only if not all
            @filtered_results = @filtered_results.where(status: @status) unless @status == 'all'
          
            @pagy, @cash_adv_requests = pagy(@filtered_results.order(created_at: :desc), items: 10)
            @status = params[:status]&.downcase&.tr('_', '-')
          
            # Status counts based on search (but still restricted to current user's requests)
            @pending_count = @q.result.where(status: 'pending', employee_id: current_user.employee_id).count
            @approved_count = @q.result.where(status: 'approved', employee_id: current_user.employee_id).count
            @released_count = @q.result.where(status: 'released', employee_id: current_user.employee_id).count
            @ongoing_count = @q.result.where(status: 'on-going', employee_id: current_user.employee_id).count
            @settled_count = @q.result.where(status: 'settled', employee_id: current_user.employee_id).count
            @declined_count = @q.result.where(status: 'declined', employee_id: current_user.employee_id).count
          end
        
        
end
    