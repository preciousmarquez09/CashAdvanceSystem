
class Finance::DashboardController < ApplicationController
    
  
    def index
      @total_pending_requests = CashAdvRequest.where(status: 'pending').count
      @total_approved_requests = CashAdvRequest.where(status: 'approved').count
      @total_ongoing_cash_advances = CashAdvRequest.where(status: 'ongoing').count
      @total_cash_advances_year = CashAdvRequest.where("created_at >= ?", Time.current.beginning_of_year).sum(:amount)
      @due_next_payroll = CashAdvRequest.where("cut_off <= ?", Time.current.end_of_month)
    end
  end
  