class GenerateSchedule
    def initialize(cash_adv_request)
      @cash_adv_request = cash_adv_request
    end
  
    def perform
      #March 12
      #start_date = Date.new(Date.today.year, 4, 15).next_month 
      start_date = Date.today

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
            due_date: current_due_date, #change Date.today for testing (paid all - settled), Date.todaynext_month(i) (on-going 1 - 1 paid)
            status: "pending"
          )
        end
      else
        (@cash_adv_request.repayment_months * 2).times do
          RepaymentSchedule.create!(
            cash_adv_request_id: @cash_adv_request.id,
            amount: @cash_adv_request.monthly_cost,
            due_date: due_date,
            status: "pending"
          )
          # Change between 15 and 30
          if due_date.day == 15
            due_date = due_date.change(day: 30)
          else
            # If currently 30, go to 15 of next month
            due_date = due_date.next_month.change(day: 15)
          end
        end

      end
    end
end