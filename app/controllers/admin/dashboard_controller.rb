class Admin::DashboardController < ApplicationController
    def index
      @pending_requests = CashAdvRequest.where(status: "pending").count
      @approved_requests = CashAdvRequest.where(status: "approved").count
      @ongoing_cash_advances = CashAdvRequest.where(status: "ongoing").count
      @total_cash_advances = CashAdvRequest.where("created_at >= ?", Time.current.beginning_of_year).sum(:amount)
      @audit_logs = AuditLog.order(created_at: :desc).limit(10)
    end
  end
  