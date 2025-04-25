class GeneratePayroll
  def self.perform
    today = Date.today
    return unless today.day == 15 #[15, 30].include?(today.day) #change return to day today to test

    is_first_cutoff = today.day == 15
    description_date = today.strftime('%B %d, %Y')

    User.find_each do |user|
      salary = user.salary || 0
      basic = is_first_cutoff ? ((user.salary / 2) || 0) : ((user.net_salary / 2) || 0)

      cash_advance_deduction = RepaymentSchedule.joins(:cash_adv_request)
      .where(cash_adv_requests: { employee_id: user.employee_id }, 
             due_date: today, 
             status: 'pending')
      .sum(:amount)

      # Check for duplicate
      next if Payroll.exists?(user_id: user.id, description: "Payroll for #{description_date}")
      sss = 0
      philhealth = 0
      pagibig = 0
      net_amount = (basic - cash_advance_deduction)
      
      # Deducting the cash advance amount
      if !is_first_cutoff
        contributions = User.gov_contribution(salary)
        sss = contributions[:sss] || 0
        philhealth = contributions[:philhealth] || 0
        pagibig = contributions[:pagibig] || 0
      end

      # Create the payroll entry 
      Payroll.create!(
        user_id: user.id,  
        description: "Payroll for #{description_date}",
        basic: salary / 2,
        sss: sss,
        philhealth: philhealth,
        pagibig: pagibig,
        net_amount: net_amount,
        cashadv: cash_advance_deduction
      )
    end

   
  end
end
