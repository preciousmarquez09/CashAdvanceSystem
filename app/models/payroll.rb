class Payroll < ApplicationRecord
    belongs_to :user, foreign_key: 'user_id'

  
    validates :user_id, presence: true
    validates :description, presence: true
    validates :basic, :sss, :philhealth, :pagibig, :net_amount, numericality: { greater_than_or_equal_to: 0 }
end
