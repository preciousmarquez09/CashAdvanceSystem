class GeneratePayroll
    def self.perform
      today = Date.today
      return unless [15, 30].include?(today.day) #today.day == #change return to day today to test
  
      is_first_cutoff = today.day == 15
      description_date = today.strftime('%B %d, %Y')
  
      User.find_each do |user|
        salary = user.salary || 0
        basic = (salary / 2.0).round(2)
  
        cash_advance_deduction = RepaymentSchedule.joins(:cash_adv_request)
        .where(cash_adv_requests: { employee_id: user.employee_id }, 
               due_date: today, 
               status: 'pending')
        .sum(:amount)

        is_first_cutoff = today.day == 15
        description_date = today.strftime('%B %d, %Y')
        
        # Check for duplicate
        next if Payroll.exists?(user_id: user.id, description: "Payroll for #{description_date}")
  
        # Deducting the cash advance amount
        if is_first_cutoff
          sss = 0
          philhealth = 0
          pagibig = 0
          net_amount = (basic - cash_advance_deduction).round(2)
        else
          contributions = User.gov_contribution(salary)
          sss = contributions[:sss]
          philhealth = contributions[:philhealth].round(2)
          pagibig = contributions[:pagibig]

          net_amount = (basic - (sss + philhealth + pagibig + cash_advance_deduction)).round(2)
        end
  
        # Create the payroll entry 
        Payroll.create!(
          user_id: user.id,  
          description: "Payroll for #{description_date}",
          basic: basic,
          sss: sss,
          philhealth: philhealth,
          pagibig: pagibig,
          net_amount: net_amount,
          cashadv: cash_advance_deduction
        )
      end
  end
end
