class Admin::AuditlogsController < ApplicationController
    include Pagy::Backend
    before_action :authenticate_user!
  
    def index
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

  end
  