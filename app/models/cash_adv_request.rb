class CashAdvRequest < ApplicationRecord
  has_many_attached :attachments
  has_many :repayment_schedules, dependent: :destroy
  has_many :notifications, dependent: :destroy
  
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
  scope :released, -> { where(status: 'released') }

  after_create :log_creation
  after_update :log_status_change, if: :saved_change_to_status?

  def self.ransackable_attributes(auth_object = nil)
    super + ["employee_id", "status", "cut_off"]
  end

  def self.ransackable_associations(auth_object = nil)
    super + ["employee"]
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
    approver_user = User.find_by(employee_id: approver_id)
    requester_user = employee 
  
    
    action_text = "Updated the status of #{requester_user.f_name} #{requester_user.l_name}’s cash advance request to #{status}"

  
    AuditLog.create!(
      user_id: approver_user&.id || requester_user.id,
      action: action_text
    )
  end
end
