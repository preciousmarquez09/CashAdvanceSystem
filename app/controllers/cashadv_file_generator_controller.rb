class CashadvFileGeneratorController < ApplicationController

    def select_type
      if params[:file_type].blank? || params[:status].blank?
        flash[:error] = "File type and status cannot be blank"
        redirect_to cashadv_file_generator_index_path and return
      end
      case params[:file_type]
      when "pdf"
        if params[:file_action].blank?
          flash[:error] = "Action cannot be blank"
          redirect_to cashadv_file_generator_index_path and return
        else
          pdf_file
        end
      when "excel"
        excel_file
      else
        flash[:error] = "Invalid file type"
        redirect_to cashadv_file_generator_index_path and return
      end
    end
  

    def pdf_file
      Rails.logger.info(params.inspect)
    
      if params[:status].include?("all")
      @cashadvreq = CashAdvRequest.includes(:employee, :approver, :repayment_schedules).order(Arel.sql(
                        "CASE status 
                          WHEN 'pending' THEN 1
                          WHEN 'approved' THEN 2
                          WHEN 'released' THEN 3
                          WHEN 'on-going' THEN 4
                          WHEN 'settled' THEN 5
                          WHEN 'declined' THEN 6
                          ELSE 7 END"
                      ),created_at: :desc)
      else
      @cashadvreq =   CashAdvRequest.includes(:employee, :approver, :repayment_schedules).where(status: [params[:status]]).order(created_at: :desc)
                      if @cashadvreq.empty?
                        flash[:error] = "No cash advance has a status of: #{params[:status].join(', ').capitalize}"
                        redirect_to cashadv_file_generator_index_path and return
                      end
      end
    
      pdf = Prawn::Document.new( margin: 36)
    
      # Header
      pdf.text "CASH ADVANCE SYSTEM", size: 24, style: :bold, align: :center
      pdf.text "Generated: #{Date.today.strftime('%B %-d, %Y')}", size: 12, align: :center
      pdf.move_down 20
    
      pdf.text "CASH ADVANCE LIST", size: 18, style: :bold, align: :center
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
    
            pdf.table(data, width: pdf.bounds.width,column_widths: column_widths, cell_style: {borders: [], padding: [2, 2], size: 10, overflow: :shrink_to_fit})
            

            approver_status = ['approved', 'declined', 'released', 'on-going', 'settled']

            if approver_status.include?(cashadv.status)
              dataApprover = [
                ["Approver:",  (cashadv.approver&.f_name.to_s + " " + cashadv.approver&.l_name.to_s).presence || "N/A", "Updated At:", cashadv.updated_at.strftime('%B %-d, %Y')  || "N/A"]
              ]
              pdf.table(dataApprover, width: pdf.bounds.width, column_widths: column_widths,cell_style: {borders: [], padding: [2, 2], size: 10, overflow: :shrink_to_fit}) 
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
                
                  pdf.table(repayments, width: pdf.bounds.width, cell_style: { borders: [:bottom, :top, :left, :right], padding: [5, 10], size: 10, border_color: '000000', align: :center}) 
                   
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
    
      send_data pdf.render, filename: 'cashadvs_list.pdf', type: 'application/pdf', disposition: params[:file_action] == 'download' ? 'attachment' : 'inline'
     
    end
    

    def excel_file
       
    end

    private
    def number_with_delimiter(number)
        number.to_s.reverse.gsub(/(\d{3})(?=\d)/, '\\1,').reverse
      end
    def cash_adv_params
        params.require(:cash_adv_file_generator).permit(:status, :file_type)
    end
end
