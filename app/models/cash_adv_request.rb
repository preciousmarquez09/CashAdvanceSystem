class CashAdvRequest < ApplicationRecord
  has_many_attached :attachments
  has_many :repayment_schedules, dependent: :destroy
  # Associate employee_id with User, because the `users` table contains employee_id
  belongs_to :employee, class_name: "User", foreign_key: "employee_id", primary_key: "employee_id"

  # Associate approver with User model
  belongs_to :approver, class_name: "User", foreign_key: "approver_id", primary_key: "employee_id", optional: true

  validates :request_reason, :amount, :repayment_months, :cut_off, :interest_amount, :monthly_cost, presence: true
  validates :amount,  numericality: { greater_than_or_equal_to: 1000 }
  validates :approver_reason, presence: true, length: { minimum: 20 }, if: -> { status == "declined" }


  validate :check_status

  scope :pending, -> { where(status: 'pending') }
  scope :approved, -> { where(status: 'approved') }

  after_create :log_creation
  after_update :log_status_change, if: :saved_change_to_status?

  def self.ransackable_attributes(auth_object = nil)
    super + ["employee_id", "status", "cut_off"]
  end

  def self.ransackable_associations(auth_object = nil)
    super + ["employee"]
  end

  def status_class
    case status
    when 'pending' then 'bg-yellow-200 text-yellow-600 px-2 py-1 text-sm font-semibold rounded capitalize'
    when 'declined' then 'bg-red-200 text-red-600 px-2 py-1 text-sm font-semibold rounded capitalize'
    when 'approved' then 'bg-green-200 text-green-600 px-2 py-1 text-sm font-semibold rounded capitalize'
    when 'released' then 'bg-blue-200 text-blue-600 px-2 py-1 text-sm font-semibold rounded capitalize'
    when 'on-going' then 'bg-orange-200 text-orange-600 px-2 py-1 text-sm font-semibold rounded capitalize'
    when 'settled' then 'bg-purple-200 text-purple-600 px-2 py-1 text-sm font-semibold rounded capitalize'
    else 'bg-gray-300' # Default color
    end
  end


  

  private
  def check_status
    return if status.blank?

    if status == status_was
      errors.add(:status, "is already set to #{status}. ")
      return
    end

    invalid_transitions = {
      "pending" => ["pending", "released", "on-going", "settled"],
      "approved" => ["pending", "declined"],
      "released" => ["pending", "declined", ],
      "on-going" => ["pending", "declined", "approved", "released", "declined"],
      "settled" => ["pending", "declined", "approved", "released", "on-going", "declined"],
      "declined" => ["pending", "declined", "approved", "released", "on-going", "settled"]
    }

    if invalid_transitions.key?(status_was) && invalid_transitions[status_was].include?(status)
      errors.add(:status, "cannot be changed from #{status_was} to #{status}.")
    end
  end

  def log_creation
    AuditLog.create!(user_id: employee.id, action: "Request Cash Advance")
  end

  def log_status_change
    AuditLog.create!(user_id: approver&.id || employee.id, action: status)
  end
end
