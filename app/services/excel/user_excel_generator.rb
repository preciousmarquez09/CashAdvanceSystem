
module Excel
    class UserExcelGenerator
      def initialize(params)
        @params = params
        @q = User.ransack(@params[:q])
        @users = @q.result
      end
  
      def empty?
        @users.empty?
      end
  
      def generate
        package = Axlsx::Package.new
        workbook = package.workbook
  
        header_style = workbook.styles.add_style(b: true, bg_color: 'CCCCCC', alignment: { horizontal: :center })
  
        workbook.add_worksheet(name: "Users List") do |sheet|
          # Add header row
          sheet.add_row [
            "EMPLOYEE ID", "NAME", "ROLE", "BIRTHDAY", "EMAIL", "CIVIL STATUS",
            "GENDER", "HIRE DATE", "SALARY", "JOB TITLE", "EMPLOYMENT STATUS", "OVERALL CASH ADVANCE"
          ], style: header_style
  
          # Add user rows
          @users.each do |user|
            full_name = "#{user.f_name} #{user.l_name}".capitalize
            cash_adv_count = CashAdvRequest.where(employee_id: user.employee_id).count
  
            sheet.add_row [
              user.employee_id || 'N/A',
              full_name,
              user.role&.capitalize || 'N/A',
              user.birthday&.strftime('%m/%d/%y') || 'N/A',
              user.email || 'N/A',
              user.civil_status&.upcase || 'N/A',
              user.gender&.upcase || 'N/A',
              user.hire_date&.strftime('%m/%d/%Y') || 'N/A',
              number_with_delimiter(user.salary || 0),
              user.job_title&.upcase || 'N/A',
              user.employment_status&.upcase || 'N/A',
              cash_adv_count > 0 ? cash_adv_count : 'N/A'
            ]
          end
        end
  
        package.to_stream.read
      end
  
      private
  
      def number_with_delimiter(number)
        number.to_s.reverse.gsub(/(\d{3})(?=\d)/, '\\1,').reverse
      end
    end
  end
  