class Admin::CashAdvRequestsController < ApplicationController
    load_and_authorize_resource
    include RestrictPages
    
    before_action :authorize_admin_finance!, only: [:index, :edit, :update]
    def index
      @eligibility = Eligibility.first
      @eligible = current_user&.salary.to_f >= @eligibility&.min_net_salary.to_f
    
      if params.dig(:q, :created_at_lteq).present?
        params[:q][:created_at_lteq] = Date.parse(params[:q][:created_at_lteq]).end_of_day
      end
      # Convert params[:q] to an unsafe hash to avoid strong parameters filtering
      @q = CashAdvRequest.includes(:employee).ransack(params[:q]&.to_unsafe_h || {})
    
      # Get the status from params or default to 'all'
      @status = params[:status] || 'all'

      if params[:q].present? && params[:status].blank?
        @status = 'all'
      end
    
      # Apply the search query but keep status count
      @filtered_results = @q.result(distinct: false)
    
      # Apply status filter only if not all
      @filtered_results = @filtered_results.where(status: @status) unless @status == 'all'
    
      @pagy, @cash_adv_requests = pagy(@filtered_results.order(updated_at: :desc), items: 10)
      @status = params[:status]&.downcase&.tr('_', '-')
      # Status counts based on search
      @pending_count = @q.result.where(status: 'pending').count
      @approved_count = @q.result.where(status: 'approved').count
      @released_count = @q.result.where(status: 'released').count
      @ongoing_count = @q.result.where(status: 'on-going').count
      @settled_count = @q.result.where(status: 'settled').count
      @declined_count = @q.result.where(status: 'declined').count
    end
  
    def new
        @user = current_user
        @eligibility = Eligibility.first
        @cash_adv_request = CashAdvRequest.new
    end
    
    def create
        @cash_adv_request = CashAdvRequest.new(cash_adv_request_params)
        @cash_adv_request.employee_id = current_user.employee_id
        @cash_adv_request.status = "pending"
        if params[:attachments].present?
          params[:attachments].each do |attachment|
              @cash_adv_request.attachments.attach(attachment)
          end
        end
        if @cash_adv_request.save
          User.with_role(:finance).find_each do |user|
            next unless user.present?
          
            notification = CashAdvNotification.with(
              employee_id: current_user.employee_id,
              cash_adv_request_id: @cash_adv_request.id,
              action: 'pending'
            )
            notification.deliver(user)
          end
          if current_user.has_role?(:finance)
            redirect_to admin_cash_adv_requests_path, notice: "Cash advance request submitted. Please wait for finance approval."
          else
            redirect_to employee_cash_adv_requests_path, notice: "Cash advance request submitted. Please wait for finance approval."
          end
        else
          @user = current_user
          @eligibility = Eligibility.first
          flash[:alert] = "Failed to submit request."
          render :new, status: :unprocessable_entity
        end
    end

    def edit
      @cash_adv_request = CashAdvRequest.includes(:employee).find(params[:id])
    end

    def update
      @cash_adv_request = CashAdvRequest.find(params[:id])
    
      #Set approver_id before updating
      if params.dig(:cash_adv_request, :status) == "approved" || "declined" && @cash_adv_request.approver_id.nil?
        @cash_adv_request.approver_id = current_user.employee_id
      end
    
      if @cash_adv_request.update(cash_adv_request_params)
        # if (@cash_adv_request.status == "approved" || @cash_adv_request.status == "declined") && @cash_adv_request.approver_id.nil?
        #   @cash_adv_request.update_column(:approver_id, current_user.employee_id)
        # end      
        GenerateSchedule.new(@cash_adv_request).perform if @cash_adv_request.status == "released"
        
        employee = User.find_by(employee_id: @cash_adv_request.employee_id)
        repayment_schedule = RepaymentSchedule.find_by(cash_adv_request_id: @cash_adv_request.id)
    
        notification_data = {
          employee_id: employee.employee_id,
          cash_adv_request_id: @cash_adv_request.id,
          action: @cash_adv_request.status,
        }
    
        if repayment_schedule.present?
          notification_data[:repayment_schedule_id] = repayment_schedule.id
        end
    
        if @cash_adv_request.status == "released" || @cash_adv_request.status == "declined"
          UserMailer.notification_email(employee, notification_data).deliver_now 
        end
    
        # Deliver the notification
        CashAdvNotification.with(notification_data).deliver(employee)
    
        redirect_to admin_cash_adv_requests_path, notice: "Cash advance request updated successfully."
      else
        flash[:alert] = "Failed to update cash advance request."
        render :edit, status: :unprocessable_entity
      end
    end
    

    def show
      @cash_adv_request = CashAdvRequest.includes(:employee, :approver, :repayment_schedules).find(params[:id])
      @approver = User.find_by(employee_id: @cash_adv_request.approver_id)
    end

    def destroy
      @cash_adv_request = CashAdvRequest.find(params[:id])
    
      # Delete associated attachments (if any)
      @cash_adv_request.attachments.each do |attachment|
        attachment.purge
      end
    
      # Destroy the cash advance request itself
      if @cash_adv_request.destroy
        redirect_to admin_cash_adv_requests_path, notice: "Cash Advance Request deleted successfully."
      else
        redirect_to admin_cash_adv_requests_path, alert: "Failed to delete cash advance request."
      end
    end

    def pdf_file
      pdfgenerator = Pdf::CashAdvRequestPdfGenerator.new(params)
    
      if pdfgenerator.empty?
        flash[:alert] = "No cash advance found"
        redirect_to admin_cash_adv_requests_path
        return
      end
    
      send_data pdfgenerator.generate, filename: "Cash Advance List (#{Time.current.strftime('%B %-d, %Y - %I:%M %p')}).pdf", type: 'application/pdf',disposition: 'attachment'
    end
  
    def excel_file
      excel_generator = Excel::CashAdvRequestExcelGenerator.new(params)
    
      if excel_generator.empty?
        flash[:alert] = "No cash advance found"
        redirect_to admin_cash_adv_requests_path
        return
      end
      
      send_data excel_generator.generate, filename: "Cash Advance List (#{Time.current.strftime('%B %-d, %Y - %I:%M %p')}).xlsx", type: "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet"
    end

    private

    def cash_adv_request_params
      permitted_params = [ :request_reason, :amount, :cut_off, :interest_amount, :repayment_months, :monthly_cost, :status, attachments: [] ]
      
      # Ensure :approver_reason is added only if it's present in params
      permitted_params += [:approver_reason] if params.dig(:cash_adv_request, :approver_reason).present?
      
      params.require(:cash_adv_request).permit(permitted_params)
    end
    
end
