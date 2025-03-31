class Admin::CashAdvRequestsController < ApplicationController

    def index
        @eligibility = Eligibility.first
        @eligible = current_user&.salary.to_f >= @eligibility&.min_net_salary.to_f

        @user = User.find_by(employee_id: current_user.employee_id)
        @current_cash_adv_request = @user&.cash_adv_requests 
        @q = CashAdvRequest.includes(:employee).ransack(params[:q])
        @pagy, @cash_adv_requests = pagy(@q.result(distinct: false).order(created_at: :desc), items: 10)
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
            redirect_to admin_cash_adv_requests_path, notice: "Cash advance request submitted. Please wait for finance approval."
        else
        @user = current_user
        @eligibility = Eligibility.first
            flash[:alert] = "Failed to submit request."
            logger.error "Cash Advance Request Errors: #{@cash_adv_request.errors.full_messages.join(', ')}"
            render :new, status: :unprocessable_entity
        end
    end

    def edit
      @cash_adv_request = CashAdvRequest.includes(:employee).find(params[:id])
    end

    def update
      @cash_adv_request = CashAdvRequest.find(params[:id])

      if @cash_adv_request.update(cash_adv_request_params)
        if @cash_adv_request.status == "approved" && @cash_adv_request.approver_id.nil?
          @cash_adv_request.update_column(:approver_id, current_user.employee_id)
        end        
        GenerateSchedule.new(@cash_adv_request).perform if @cash_adv_request.status == "released"

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
      
        if @cash_adv_request.destroy
          redirect_to admin_cash_adv_requests_path,  notice: "Cash Advance Request deleted successfully."
        else
          redirect_to admin_cash_adv_requests_path, alert: "Failed to delete cash advance request."
        end
    end

    private

    def cash_adv_request_params
      permitted_params = [ :request_reason, :amount, :cut_off, :interest_amount, :repayment_months, :monthly_cost, :status, attachments: [] ]
    
      permitted_params << :approver_reason if params[:cash_adv_request][:approver_reason].present?
      params.require(:cash_adv_request).permit(permitted_params)
    end
      
end
