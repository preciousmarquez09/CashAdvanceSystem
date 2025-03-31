class GenerateSchedule
    def initialize(cash_adv_request)
      @cash_adv_request = cash_adv_request
    end
  
    def perform
      # Determine number of months based on cutoff frequency
      num_months = @cash_adv_request.cut_off == "monthly" ? @cash_adv_request.repayment_months : @cash_adv_request.repayment_months * 2
        
      #March 12
      #start_date = Date.new(Date.today.year, 3, 12).next_month 
      start_date = Date.today.next_month
      
      # Determine due date based on the start date's day
      if start_date.day >= 1 && start_date.day <= 15
        due_date = start_date.change(day: 15)
      else
        due_date = start_date.change(day: 30)
      end
      
      num_months.times do |i|
        current_due_date = due_date.next_month(i)  

        RepaymentSchedule.create!(
          cash_adv_request_id: @cash_adv_request.id,
          amount: @cash_adv_request.monthly_cost,
          due_date: current_due_date,
          status: "pending"
        )
      end
    end
end