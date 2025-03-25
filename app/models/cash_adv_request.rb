class CashAdvRequest < ApplicationRecord
    belongs_to :employee, class_name: "User", foreign_key: "employee_id", primary_key: "employee_id"
    belongs_to :approver, class_name: "User", foreign_key: "approver_id", primary_key: "employee_id", optional: true
  
    validates :amount, :repayment_months, :cut_off, :status, presence: true
  
    after_create :log_creation
    after_update :log_status_change, if: :saved_change_to_status?
  
    private
  
    def log_creation
     
  
      AuditLog.create!(
        user_id: employee.id, 
        action: "Request Cash Advance"
      )
    end
  
    def log_status_change
     
  
      AuditLog.create!(
        user_id: approver&.id || employee.id, 
        action: status 
      )
    end
  end
  