class Admin::CashAdvRequestsController < ApplicationController
  load_and_authorize_resource
    def index
      @eligibility = Eligibility.first
      @eligible = current_user&.salary.to_f >= @eligibility&.min_net_salary.to_f
    
      # Convert params[:q] to an unsafe hash to avoid strong parameters filtering
      @q = CashAdvRequest.includes(:employee).ransack(params[:q]&.to_unsafe_h || {})
    
      # Get the status from params or default to 'all'
      @status = params[:status] || 'all'
    
      # Apply the search query but keep status count
      @filtered_results = @q.result(distinct: false)
    
      # Apply status filter only if not all
      @filtered_results = @filtered_results.where(status: @status) unless @status == 'all'
    
      @pagy, @cash_adv_requests = pagy(@filtered_results.order(created_at: :desc), items: 10)
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
          redirect_to admin_cash_adv_requests_path, notice: "Cash advance request submitted. Please wait for finance approval."
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
    
      if @cash_adv_request.update(cash_adv_request_params)
        if (@cash_adv_request.status == "approved" || @cash_adv_request.status == "declined") && @cash_adv_request.approver_id.nil?
          @cash_adv_request.update_column(:approver_id, current_user.employee_id)
        end      
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
      Rails.logger.info(params.inspect)
    
      @q = CashAdvRequest.ransack(params[:q])
      @cashadvreq = @q.result.order(created_at: :desc)
    
      if params[:status].present?
        @cashadvreq = @cashadvreq.where(status: params[:status])
      end
    
       if @cashadvreq.empty?
        
        flash[:alert] = "No cash advance found"
        redirect_to admin_cash_adv_requests_path
        return
      end
  
      title_status = params[:status].present? ? params[:status].titleize : "All"
    
      pdf = Prawn::Document.new(margin: 36)
    
      # Header
      pdf.text "CASH ADVANCE SYSTEM", size: 24, style: :bold, align: :center
      pdf.text "Generated: #{Date.today.strftime('%B %-d, %Y')}", size: 12, align: :center
      pdf.move_down 20
    
      pdf.text "CASH ADVANCE LIST – #{title_status}", size: 18, style: :bold, align: :center
      pdf.move_down 20
      previous_status = nil
    
      @cashadvreq.each do |cashadv|
        # Check if there's enough space
        needed_height = 200 # Base height for cash advance info
    
        if ['released', 'on-going', 'settled'].include?(cashadv.status) && cashadv.repayment_schedules.size >= 1
          # Add extra space for repayment table (header + rows * row_height)
          needed_height += 30 + (cashadv.repayment_schedules.size * 20)
        end
    
        if pdf.cursor < needed_height
          pdf.start_new_page
        end
    
        if cashadv.status != previous_status
          pdf.move_down 10
          pdf.text cashadv.status.upcase, size: 20, align: :center, style: :bold, color: '333399'
          pdf.move_down 5
          previous_status = cashadv.status
        end
    
        pdf.bounding_box([0, pdf.cursor], width: pdf.bounds.width) do
          y_position = pdf.cursor
    
          # Profile Picture
          if cashadv.employee&.profile_picture&.attached?
            image_io = StringIO.new(cashadv.employee.profile_picture.download)
            pdf.image image_io, at: [0, y_position], width: 50, height: 50
          else
            pdf.fill_color "cccccc"
            pdf.fill_rectangle [0, y_position], 50, 50
            pdf.fill_color "000000"
          end
    
          # Cash Advance Info
          pdf.bounding_box([60, y_position - 5], width: pdf.bounds.width - 60) do
            full_name = "#{cashadv.employee&.f_name} #{cashadv.employee&.m_name} #{cashadv.employee&.l_name}"
            pdf.text full_name.strip, style: :bold, size: 13
            pdf.text "Employee ID: #{cashadv.employee_id}", style: :italic, size: 11
            pdf.move_down 5
    
            pdf.text "Cash Advance Information:", style: :bold, size: 10
    
            data_reason_text = cashadv.request_reason.presence || "N/A"
            request_reason = [
              [{ content: "Reason:", borders: [], padding: [2, 5], size: 10 }],
              [{ content: data_reason_text, borders: [], padding: [2, 30], size: 10 }]
            ]
            pdf.table(request_reason, cell_style: { borders: [], size: 10 }, width: pdf.bounds.width)
    
            total_amount = (cashadv.amount.to_f + cashadv.interest_amount.to_f).round(2)
            attachment_count = cashadv.attachments&.attached? ? cashadv.attachments.count : 0
            column_widths = [pdf.bounds.width / 4, pdf.bounds.width / 4, pdf.bounds.width / 3, pdf.bounds.width / 6]
            data = [
              ["Amount:", cashadv.amount || "N/A", "Interest Amount:", cashadv.interest_amount || "N/A"],
              ["Monthly Amount:", cashadv.monthly_cost || "N/A", "Total Amount w/ Interest:", total_amount > 0 ? total_amount : "N/A"],
              ["Monthly Terms:", cashadv.repayment_months || "N/A", "Payment Every:", cashadv.cut_off.capitalize || "N/A"],
              ["Status:", cashadv.status.capitalize || "N/A", "No. of Attachment:", attachment_count],
            ]
    
            pdf.table(data, width: pdf.bounds.width, column_widths: column_widths, cell_style: { borders: [], padding: [2, 2], size: 10, overflow: :shrink_to_fit })
    
            approver_status = ['approved', 'declined', 'released', 'on-going', 'settled']
    
            if approver_status.include?(cashadv.status)
              dataApprover = [
                ["Approver:", (cashadv.approver&.f_name.to_s + " " + cashadv.approver&.l_name.to_s).presence || "N/A", "Updated At:", cashadv.updated_at.strftime('%B %-d, %Y') || "N/A"]
              ]
              pdf.table(dataApprover, width: pdf.bounds.width, column_widths: column_widths, cell_style: { borders: [], padding: [2, 2], size: 10, overflow: :shrink_to_fit })
              
              if cashadv.status == 'declined'
                approver_reason_text = cashadv.approver_reason.presence || "N/A"
                approver_reason = [
                  [{ content: "Approver Reason:", borders: [], padding: [2, 2], size: 10 }],
                  [{ content: approver_reason_text, borders: [], padding: [2, 30], size: 10 }]
                ]
                pdf.table(approver_reason, cell_style: { borders: [], size: 10 }, width: pdf.bounds.width)
              elsif ['released', 'on-going', 'settled'].include?(cashadv.status)
                if cashadv.repayment_schedules.size >= 1
                  pdf.move_down 10
                  pdf.text "Repayment Schedule:", style: :bold, size: 10
                  pdf.move_down 10
                  repayments = [["Due Date", "Amount", "Status"]] +
                              cashadv.repayment_schedules.uniq.map do |schedule|
                                [
                                  schedule.due_date.strftime('%B %-d, %Y') || "N/A",
                                  schedule.amount.to_s || "N/A",
                                  schedule.status.capitalize || "N/A"
                                ]
                              end
    
                  pdf.table(repayments, width: pdf.bounds.width, cell_style: { borders: [:bottom, :top, :left, :right], padding: [5, 10], size: 10, border_color: '000000', align: :center })
                end
              end
            end
          end
          pdf.move_down 30
          pdf.stroke_color "cccccc"
          pdf.stroke_horizontal_rule
          pdf.move_down 30
        end
      end
    
      send_data pdf.render, filename: 'cashadvs_list.pdf', type: 'application/pdf', disposition: 'attachment' #params[:file_action] == 'download' ? 'attachment' : 'inline'
    end
    
    

    private

    def cash_adv_request_params
      permitted_params = [ :request_reason, :amount, :cut_off, :interest_amount, :repayment_months, :monthly_cost, :status, attachments: [] ]
      
      # Ensure :approver_reason is added only if it's present in params
      permitted_params += [:approver_reason] if params.dig(:cash_adv_request, :approver_reason).present?
      
      params.require(:cash_adv_request).permit(permitted_params)
    end
    
end
