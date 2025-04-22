module Pdf
    class AuditLogPdfGenerator

      def initialize(params)
        @params = params
        @q = AuditLog.ransack(@params[:q])
        @audit_logs1 = @q.result.order(created_at: :desc)
      end

      def empty?
        @audit_logs1.empty?
      end
      
      def generate
        pdf = Prawn::Document.new
      
        pdf.text "CASH ADVANCE SYSTEM", size: 24, style: :bold, align: :center
        pdf.text "Generated on: #{Time.current.strftime('%B %-d, %Y - %I:%M %p')}", size: 12, align: :center
        pdf.move_down 20
    
        pdf.text "AUDIT LOGS", size: 18, style: :bold, align: :center
        pdf.move_down 20
      
      
        pdf.move_down 10
        table_data = [
          ['Date', 'Name', 'Action']
        ]
      
        @audit_logs1.each do |log|
          table_data << [
            log.created_at.strftime("%Y-%m-%d %I:%M %p"),
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
        )do
          row(0).background_color = 'DDDDDD' 
          row(0).font_style = :bold          
        end
        
        pdf.render
      end
  end
end