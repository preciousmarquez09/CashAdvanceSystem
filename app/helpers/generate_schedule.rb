class GenerateSchedule
    def initialize(cash_adv_request)
      @cash_adv_request = cash_adv_request
    end
  
    def perform

      #March 12
      #start_date = Date.new(Date.today.year, 3, 12).next_month 
      start_date = Date.today.next_month

      # Determine due date based on the start date's day
      if start_date.day >= 1 && start_date.day <= 15
        due_date = start_date.change(day: 15)
      else
        due_date = start_date.change(day: 30)
      end

      if @cash_adv_request.cut_off == "monthly"
        @cash_adv_request.repayment_months.times do |i|
          current_due_date = due_date.next_month(i)  

          RepaymentSchedule.create!(
            cash_adv_request_id: @cash_adv_request.id,
            amount: @cash_adv_request.monthly_cost,
            due_date: Date.new(Date.today.year, 4, 15)  , #change Date.today for testing (paid all - settled), Date.todaynext_month(i) (on-going 1 - 1 paid)
            status: "pending"
          )
        end
      else
        @cash_adv_request.repayment_months.times do |i|
          date_15 = due_date.next_month(i).change(day: 15)
          date_30 = due_date.next_month(i).change(day: 30)
        
          RepaymentSchedule.create!(
            cash_adv_request_id: @cash_adv_request.id,
            amount: @cash_adv_request.monthly_cost,
            due_date: date_15 ,
            status: "pending"
          )
        
          RepaymentSchedule.create!(
            cash_adv_request_id: @cash_adv_request.id,
            amount: @cash_adv_request.monthly_cost,
            due_date: date_30 ,
            status: "pending"
          )
        end
        
      end
    end
end