class RepaymentSchedulesController < ApplicationController
  before_action :authenticate_user!
  def index
    @repayment_schedules = RepaymentSchedule.find(params[:cash_adv_request_id])
  end
end
