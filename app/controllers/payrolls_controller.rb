    class PayrollsController < ApplicationController
        def preview
        @payroll = Payroll.find(params[:id])
        @user = @payroll.user  
    
        pdf = Prawn::Document.new
    
        
        pdf.text "Payslip", size: 24, style: :bold, align: :center
        pdf.move_down 20
    
        
        pdf.text "Employee Details", style: :bold
        pdf.text "Name: #{@user.f_name} #{@user.m_name} #{@user.l_name}"
        pdf.text "Employee ID: #{@user.employee_id}"
        pdf.text "Job Title: #{@user.job_title || 'N/A'}"
        pdf.text "Hire Date: #{@user.hire_date&.strftime('%B %d, %Y') || 'N/A'}"
        pdf.text "Pay Period: #{@payroll.description }"
        pdf.move_down 10
    
        
        pdf.text "Earnings", style: :bold
        pdf.table([
            ["Description", "Amount"],
            ["Basic Salary", @payroll.basic || 0],
            ["Allowances", 0],
            ["Overtime", 0]
        ], header: true, width: pdf.bounds.width)
        pdf.move_down 10
    
        
        pdf.text "Deductions", style: :bold
        pdf.table([
            ["Description", "Amount"],
            ["SSS", @payroll.sss || 0],
            ["PhilHealth", @payroll.philhealth || 0],
            ["PAGIBIG", @payroll.pagibig || 0],
            ["Cash Advance", @payroll.cashadv || 0]
        ], header: true, width: pdf.bounds.width)
        pdf.move_down 10
    
        
        total_earnings = (@payroll.basic || 0)
        total_deductions = (@payroll.sss || 0) + (@payroll.philhealth || 0) + (@payroll.pagibig || 0) + (@payroll.cashadv || 0)
        net_pay = total_earnings - total_deductions
    
        pdf.text "Summary", style: :bold
        pdf.table([
            ["Total Earnings", "PHP #{'%.2f' % total_earnings}"],
            ["Total Deductions", "PHP #{'%.2f' % total_deductions}"],
            ["Net Pay", "PHP #{'%.2f' % net_pay}"]
        ], width: pdf.bounds.width)
        pdf.move_down 20
    
        
        pdf.text "This is a system-generated payslip.", size: 10, align: :center
        pdf.text "Contact finance if you have any questions or dispute regarding your payslip.", size: 10, align: :center
    
        
        send_data pdf.render,
                    filename: "payroll_#{@payroll.id}.pdf",
                    type: 'application/pdf',
                    disposition: 'inline',
                    stream: true
        end
    end
    