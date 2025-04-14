class Admin::AuditlogsController < ApplicationController
    include Pagy::Backend
    before_action :authenticate_user!
  
    def index
      @q = AuditLog.ransack(params[:q])
      @pagy_audit_logs1, @audit_logs1 = pagy(@q.result.order(created_at: :desc), items: 10)
    end
  
    def export_pdf
        @q = AuditLog.ransack(params[:q])
        @audit_logs1 = @q.result.order(created_at: :desc)
      
        
        pdf = Prawn::Document.new
      
        pdf.text "Audit Logs", align: :center, size: 18, style: :bold
        pdf.move_down 10
        pdf.text "Generated on: #{Time.current.strftime('%Y-%m-%d %H:%M:%S')}", align: :right, size: 10
      
       
        pdf.move_down 10
        table_data = [
          ['Date', 'User', 'Action']
        ]
      
        @audit_logs1.each do |log|
          table_data << [
            log.created_at.strftime("%Y-%m-%d %H:%M:%S"),
            "#{log.user.f_name} #{log.user.l_name}",
            log.action
          ]
        end
      
        
        Rails.logger.debug "Table Data: #{table_data.inspect}"
      
        table_width = pdf.bounds.width

        pdf.table(
          table_data,
          header: true,
          cell_style: { padding: 5, align: :center },
          column_widths: [table_width * 0.3, table_width * 0.35, table_width * 0.35]
        )
      
       
        send_data pdf.render, filename: "audit_logs_#{Time.current.strftime('%Y%m%d%H%M%S')}.pdf", type: 'application/pdf', disposition: 'inline'
      end
  end
  