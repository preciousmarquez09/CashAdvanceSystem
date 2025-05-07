class Admin::DashboardController < ApplicationController
  
  include Pagy::Backend
  include RestrictPages
  before_action :authorize_admin!
  before_action :authenticate_user!
  
  def index
    @total_pending_requests = CashAdvRequest.where(status: "pending").count
    @total_released_requests = CashAdvRequest.where(status: ['released', 'on-going', 'settled']).count
    @total_ongoing_cash_advances = CashAdvRequest.where(status: "ongoing").count
    @total_cash_advances_year = CashAdvRequest
    .where("created_at >= ? AND status = ?", Time.current.beginning_of_year, "released")
    .sum("amount + interest_amount")

    @total_interest_earned_year = CashAdvRequest
    .where("created_at >= ?", Time.current.beginning_of_year)
    .where(status: ['released', 'on-going', 'settled'])
    .sum(:interest_amount)
   
    if params.dig(:q, :created_at_lteq).present?
      params[:q][:created_at_lteq] = Date.parse(params[:q][:created_at_lteq]).end_of_day
    end
    @q = AuditLog.ransack(params[:q])
    @pagy_audit_logs, @audit_logs = pagy(@q.result.order(created_at: :desc), items: 10)
  end


end
