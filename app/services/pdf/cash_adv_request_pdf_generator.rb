module Pdf
  class CashAdvRequestPdfGenerator
    def initialize(params)
      @params = params
      @q = CashAdvRequest.ransack(@params[:q])
      @cashadvreq = @q.result
    
      @cashadvreq = @cashadvreq.order(Arel.sql(<<~SQL.squish))
        CASE status
          WHEN 'pending' THEN 1
          WHEN 'approved' THEN 2
          WHEN 'released' THEN 3
          WHEN 'on-going' THEN 4
          WHEN 'settled' THEN 5
          WHEN 'declined' THEN 6
          ELSE 7
        END, created_at DESC
      SQL
    
      # If no status then make it all
      if @params[:status].blank? || @params[:status] == 'all'
        # No additional filtering
      else
        @cashadvreq = @cashadvreq.where(status: @params[:status])
      end
    end
    
      def empty?
        @cashadvreq.empty?
      end
    
      def generate
        title_status = @params[:status].present? ? @params[:status].titleize : "All"
        pdf = Prawn::Document.new(margin: 36)
    
        pdf.text "CASH ADVANCE SYSTEM", size: 24, style: :bold, align: :center
        pdf.text "Generated on: #{Time.current.strftime('%B %-d, %Y - %I:%M %p')}", size: 12, align: :center
        pdf.move_down 10
    
        previous_status = nil
    
        @cashadvreq.each do |cashadv|
          needed_height = 200
    
          if ['released', 'on-going', 'settled'].include?(cashadv.status) && cashadv.repayment_schedules.size >= 1
            needed_height += 30 + (cashadv.repayment_schedules.size * 20)
          end
    
          pdf.start_new_page if pdf.cursor < needed_height
    
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
                approver_name = [cashadv.approver&.f_name, cashadv.approver&.l_name].compact.join(' ').presence || "N/A"

                pdf.table([["Approver:", { content: approver_name, colspan: 3 }]], width: pdf.bounds.width, column_widths: column_widths, cell_style: { borders: [], size: 10, padding: [2, 2], overflow: :shrink_to_fit })
    
                if cashadv.status == 'declined'
                  approver_reason_text = cashadv.approver_reason.presence || "N/A"
                  approver_reason = [
                    [{ content: "Approver Reason:", borders: [], padding: [2, 2], size: 10 }],
                    [{ content: approver_reason_text, borders: [], padding: [2, 30], size: 10 }]
                  ]
                  pdf.table(approver_reason, cell_style: { borders: [], size: 10 }, width: pdf.bounds.width)
                elsif ['released', 'on-going', 'settled'].include?(cashadv.status) && cashadv.repayment_schedules.size >= 1
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
    
                  pdf.table(repayments, width: pdf.bounds.width, cell_style: { borders: [:bottom, :top, :left, :right], padding: [5, 10], size: 10, border_color: '000000', align: :center })do
                    row(0).background_color = 'CCCCCC'
                    row(0).font_style = :bold
                  end
                end
              end
            end
    
            pdf.move_down 20
            pdf.stroke_color "cccccc"
            pdf.stroke_horizontal_rule
            pdf.move_down 20
          end
        end
    
        pdf.render
      end
  end
end