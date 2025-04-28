class Admin::DashboardController < ApplicationController
  include Pagy::Backend
  before_action :authenticate_user!
  before_action :authorize_admin!
  

  def index
    authorize! :read, :dashboard
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
   
    @q = AuditLog.ransack(params[:q])
    @pagy_audit_logs, @audit_logs = pagy(@q.result.order(created_at: :desc), items: 10)
  end

  private

  def authorize_dashboard
    unless can?(:read, :dashboard)
      redirect_to root_path, alert: "You are not authorized to view this page."
    end
  end

end
