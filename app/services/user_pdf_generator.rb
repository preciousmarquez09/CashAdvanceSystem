class UserPdfGenerator
    def initialize(params)
        @params = params
        @q = User.ransack(@params[:q])
        @users = @q.result
    end

    def empty?
      @users.empty?
    end

    def generate
        pdf = Prawn::Document.new(margin: 36)
        # Header
        pdf.text "CASH ADVANCE SYSTEM", size: 24, style: :bold, align: :center
        pdf.text "Generated: #{Date.today.strftime('%B %-d, %Y')}", size: 12, align: :center
        pdf.move_down 20

        pdf.text "USERS LIST", size: 18, style: :bold, align: :center
        pdf.move_down 20

        @users.each do |user|
            # Check if there's enough space on the current page
            if pdf.cursor < 150
                pdf.start_new_page
            end

            pdf.bounding_box([0, pdf.cursor], width: pdf.bounds.width) do
                y_position = pdf.cursor

                # Profile Picture
                if user.profile_picture.attached?
                    image_io = StringIO.new(user.profile_picture.download)
                    pdf.image image_io, at: [0, y_position], width: 50, height: 50
                else
                    pdf.fill_color "cccccc"
                    pdf.fill_rectangle [0, y_position], 50, 50
                    pdf.fill_color "000000"
                end

                # User information
                pdf.bounding_box([60, y_position - 5], width: pdf.bounds.width - 60) do
                pdf.text "#{user.f_name} #{user.m_name} #{user.l_name}", style: :bold, size: 13
                pdf.text "#{user.role.capitalize}", style: :italic, size: 11
                pdf.move_down 5

                pdf.text "Personal Information:", style: :bold, size: 10

                data = [
                    ["Birthday:", "#{user.birthday&.strftime('%B %-d, %Y') || 'N/A'}", "Civil Status:", "#{user.civil_status&.capitalize || 'N/A'}"],
                    ["Email:", "#{user.email || 'N/A'}", "Gender:", "#{user.gender&.capitalize || 'N/A'}"]
                ]

                pdf.table(data, width: pdf.bounds.width, cell_style: { borders: [], padding: [2, 5], size: 10 }) do |t|
                    t.column(0).width = 90
                    t.column(1).width = 170
                    t.column(2).width = 120
                    t.column(3).width = 100
                end

                pdf.move_down 10

                pdf.text "Work Information:", style: :bold, size: 10

                cash_adv_count = CashAdvRequest.where(employee_id: user.employee_id).count
                work_data = [
                    ["Employee ID:", "#{user.employee_id || 'N/A'}", "Hire Date:", "#{user.hire_date&.strftime('%B %-d, %Y') || 'N/A'}"],
                    ["Job Title:", "#{user.job_title&.capitalize || 'N/A'}", "Employment Status:", "#{user.employment_status&.capitalize || 'N/A'}"],
                    ["Salary:", " #{number_with_delimiter(user.salary || 'N/A')}", "No. of Cash Advance:", " #{cash_adv_count >= 1 ? cash_adv_count : 'N/A'}"]
                ]

                pdf.table(work_data, width: pdf.bounds.width, cell_style: { borders: [], padding: [2, 5], size: 10 }) do |t|
                    t.column(0).width = 90
                    t.column(1).width = 170
                    t.column(2).width = 120
                    t.column(3).width = 100
                end
            end

            pdf.move_down 15
            pdf.stroke_horizontal_rule
            pdf.move_down 15
        end
        end
     pdf.render
    end

    private

    def number_with_delimiter(number)
        number.to_s.reverse.gsub(/(\d{3})(?=\d)/, '\\1,').reverse
    end
    
end
