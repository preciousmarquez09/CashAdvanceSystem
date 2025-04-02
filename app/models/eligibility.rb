class Eligibility < ApplicationRecord

    validates :percentage_cash_limit, presence: true, numericality: { greater_than_or_equal_to: 0, less_than_or_equal_to: 50 }
    validates :interest_rate, presence: true, numericality: { greater_than_or_equal_to: 0, less_than_or_equal_to: 30 }
    validates :min_net_salary, presence: true, numericality: { greater_than_or_equal_to: 1000 }
    validates :req_decline_days, :req_approve_days, presence: true, numericality: { greater_than_or_equal_to: 0, less_than_or_equal_to: 31 }
    
end
