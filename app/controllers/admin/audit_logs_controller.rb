class Admin::AuditLogsController < ApplicationController
    load_and_authorize_resource
    include Pagy::Backend
    before_action :authenticate_user!
  
    def index
      if params.dig(:q, :created_at_lteq).present?
        params[:q][:created_at_lteq] = Date.parse(params[:q][:created_at_lteq]).end_of_day
      end

      @q = AuditLog.ransack(params[:q])
      @pagy_audit_logs1, @audit_logs1 = pagy(@q.result.order(created_at: :desc), items: 10)
    end

    def pdf_file
      pdfgenerator = Pdf::AuditLogPdfGenerator.new(params)
    
      if pdfgenerator.empty?
        flash[:alert] = "No audit logs found"
        redirect_to admin_auditlogs_path
        return
      end
    
      send_data pdfgenerator.generate, filename: "Audit Logs (#{Time.current.strftime('%B %-d, %Y - %I:%M %p')}).pdf", type: 'application/pdf', disposition: 'attachment'
    end

    def excel_file
      excel_generator = Excel::AuditLogExcelGenerator.new(params)
    
      if excel_generator.empty?
        flash[:alert] = "No audit logs found"
        redirect_to admin_auditlogs_path
        return
      end
      
      send_data excel_generator.generate, filename: "Audit Logs (#{Time.current.strftime('%B %-d, %Y - %I:%M %p')}).xlsx", type: "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet"
    end

  end
  