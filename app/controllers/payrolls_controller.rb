class PayrollsController < ApplicationController
    include ActionView::Helpers::NumberHelper  # Make sure this line is included
    load_and_authorize_resource
  
    def preview
      @payroll = Payroll.find(params[:id])
      @user = @payroll.user  
  
      pdf = Prawn::Document.new
  
      # Employee details
      pdf.text "Payslip", size: 24, style: :bold, align: :center
      pdf.move_down 20
  
      pdf.text "Employee Details", style: :bold
      pdf.text "Name: #{@user.f_name} #{@user.m_name} #{@user.l_name}"
      pdf.text "Employee ID: #{@user.employee_id}"
      pdf.text "Job Title: #{@user.job_title || 'N/A'}"
      pdf.text "Hire Date: #{@user.hire_date&.strftime('%B %d, %Y') || 'N/A'}"
      pdf.text "Pay Period: #{@payroll.description }"
      pdf.move_down 10
  
      # Earnings section
      pdf.text "Earnings", style: :bold
      pdf.table([
        ["Description", "Amount"],
        ["Basic Salary", number_to_currency(@payroll.basic, precision: 2, delimiter: ',', unit: '')],
        ["Allowances", number_to_currency(0, precision: 2, delimiter: ',', unit: '')],
        ["Overtime", number_to_currency(0, precision: 2, delimiter: ',', unit: '')]
      ], header: true, width: pdf.bounds.width)
      pdf.move_down 10
  
      # Deductions section
      pdf.text "Deductions", style: :bold
      pdf.table([
        ["Description", "Amount"],
        ["SSS", number_to_currency(@payroll.sss, precision: 2, delimiter: ',', unit: '')],
        ["PhilHealth", number_to_currency(@payroll.philhealth, precision: 2, delimiter: ',', unit: '')],
        ["PAGIBIG", number_to_currency(@payroll.pagibig, precision: 2, delimiter: ',', unit: '')],
        ["Cash Advance", number_to_currency(@payroll.cashadv, precision: 2, delimiter: ',', unit: '')]
      ], header: true, width: pdf.bounds.width)
      pdf.move_down 10
  
      # Summary section
      total_earnings = (@payroll.basic || 0)
      total_deductions = (@payroll.sss || 0) + (@payroll.philhealth || 0) + (@payroll.pagibig || 0) + (@payroll.cashadv || 0)
      net_pay = total_earnings - total_deductions
  
      pdf.text "Summary", style: :bold
      pdf.table([
        ["Total Earnings", number_to_currency(total_earnings, precision: 2, delimiter: ',', unit: '')],
        ["Total Deductions", number_to_currency(total_deductions, precision: 2, delimiter: ',', unit: '')],
        ["Net Pay", number_to_currency(net_pay, precision: 2, delimiter: ',', unit: '')]
      ], width: pdf.bounds.width)
      pdf.move_down 20
  
      # Footer note
      pdf.text "This is a system-generated payslip.", size: 10, align: :center, style: :italic
      pdf.text "Contact finance if you have any questions or disputes regarding your payslip.", size: 10, align: :center, style: :italic
  
      # Sending the PDF
      send_data pdf.render,
                filename: "payroll_#{@payroll.id}.pdf",
                type: 'application/pdf',
                disposition: 'inline',
                stream: true
    end
  end
  