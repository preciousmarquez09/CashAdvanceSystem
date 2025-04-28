class Admin::DashboardController < ApplicationController
  
  include Pagy::Backend
  include RestrictPages
  
  before_action :authorize_admin!
  before_action :authenticate_user!
  
  def index
    @pending_requests = CashAdvRequest.where(status: "pending").count
    @released_requests = CashAdvRequest.where(status: 'released').count
    @ongoing_cash_advances = CashAdvRequest.where(status: "ongoing").count
    @total_cash_advances = CashAdvRequest
    .where("created_at >= ? AND status = ?", Time.current.beginning_of_year, "released")
    .sum(:amount)
   
    @q = AuditLog.ransack(params[:q])
    @pagy_audit_logs, @audit_logs = pagy(@q.result.order(created_at: :desc), items: 10)
  end
end
