class RepaymentSchedule < ApplicationRecord
  belongs_to :cash_adv_request

  validates :cash_adv_request_id, :amount, :due_date, :status, presence: true
end
