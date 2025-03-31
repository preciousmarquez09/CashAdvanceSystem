class RepaymentSchedulesController < ApplicationController
  def index
    @repayment_schedules = RepaymentSchedule.find(params[:cash_adv_request_id])
  end
end
