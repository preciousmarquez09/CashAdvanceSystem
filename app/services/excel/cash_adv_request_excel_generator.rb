module Excel
  class CashAdvRequestExcelGenerator
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
      package = Axlsx::Package.new
      workbook = package.workbook

      header_style = workbook.styles.add_style(b: true, bg_color: 'CCCCCC', alignment: { horizontal: :center })
      left_align_style = workbook.styles.add_style(alignment: { horizontal: :left })

      # Main sheet for cash advance list
      main_sheet = workbook.add_worksheet(name: "Cash Advance List")
      main_sheet.add_row [
        "EMPLOYEE ID", "NAME", "REASON", "AMOUNT", "INTEREST AMOUNT", "MONTHLY AMOUNT", "TOTAL AMOUNT W/ INTEREST", "MONTHLY TERMS", 
        "PAYMENT EVERY", "STATUS", "NO. OF ATTACHMENT", "APPROVER", "APPROVER REASON"
      ], style: header_style

      repayment_status = ['released', 'on-going', 'settled']
      repayment_sheet = nil

      create_repayment_sheet = @cashadvreq.any? { |req| repayment_status.include?(req.status) && req.repayment_schedules.any? }

      if create_repayment_sheet
        repayment_sheet = workbook.add_worksheet(name: "Repayment Schedules")
        repayment_sheet.add_row [
          "EMPLOYEE ID", "NAME", "DUE DATE", "AMOUNT", "STATUS"
        ], style: header_style
      end

      approver_status = ['approved', 'declined', 'released', 'on-going', 'settled']

      @cashadvreq.each do |cashadv|
        full_name = "#{cashadv.employee.f_name} #{cashadv.employee.l_name}".capitalize
        approver_name = 'N/A'
        approver_reason = 'N/A'

        row = [
          cashadv.employee_id || 'N/A',
          full_name,
          cashadv.request_reason&.capitalize || 'N/A',
          number_with_delimiter(cashadv.amount || 0),
          number_with_delimiter(cashadv.interest_amount || 0),
          number_with_delimiter(cashadv.monthly_cost || 0),
          number_with_delimiter((cashadv.amount || 0) + (cashadv.interest_amount || 0)),
          cashadv.repayment_months || 'N/A',
          cashadv.cut_off&.capitalize || 'N/A',
          cashadv.status&.capitalize || 'N/A',
          cashadv.attachments.count || 0,
        ]

        if approver_status.include?(cashadv.status)
          approver_name = [cashadv.approver&.f_name, cashadv.approver&.l_name].compact.join(' ').presence || 'N/A'
          row << approver_name

          if cashadv.status == 'declined'
            approver_reason = cashadv.approver_reason.presence || 'N/A'
            row << approver_reason
          else
            row << ''
          end
        else
          row << '' << ''
        end

        main_sheet.add_row row, style: [left_align_style] * row.length

        if repayment_sheet && repayment_status.include?(cashadv.status) && cashadv.repayment_schedules.any?
          cashadv.repayment_schedules.uniq.each do |schedule|
            repayment_sheet.add_row [
              cashadv.employee_id || 'N/A',
              full_name,
              schedule.due_date&.strftime('%B %-d, %Y') || 'N/A',
              number_with_delimiter(schedule.amount || 0),
              schedule.status&.capitalize || 'N/A'
            ], style: [left_align_style] * 5
          end
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
