module Excel
    class AuditLogExcelGenerator

      def initialize(params)
        @params = params
        @q = AuditLog.ransack(@params[:q])
        @audit_logs1 = @q.result.order(created_at: :desc)
      end

      def empty?
        @audit_logs1.empty?
      end

    def generate
        package = Axlsx::Package.new
        workbook = package.workbook
  
        header_style = workbook.styles.add_style(b: true, bg_color: 'CCCCCC', alignment: { horizontal: :center })

        workbook.add_worksheet(name: "Audit Logs") do |sheet|
            # Add header row
            sheet.add_row [
              "DATE", "NAME", "ACTION"
            ], style: header_style
    
            # Add user rows
            @audit_logs1.each do |log|
              full_name = "#{log.user.f_name} #{log.user.l_name}".capitalize
    
              sheet.add_row [
                log.created_at.strftime("%Y-%m-%d %I:%M %p"),
                full_name,
                log.action&.capitalize || 'N/A'
              ]
            end
        end
    
        package.to_stream.read
        end
    end
end