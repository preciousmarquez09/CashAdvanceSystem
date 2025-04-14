class Notification < ApplicationRecord
  include Noticed::Model

  belongs_to :recipient, polymorphic: true, optional: true
  belongs_to :user, optional: true  
  belongs_to :cash_adv_request, optional: true
  belongs_to :repayment_schedule, optional: true
  # after saving in the database call the method
  after_create_commit :update_notif  
  #find the unread notification (it has a null value)
  scope :unread, -> { where(read_at: nil) }

  private

  def mark_as_read
    update(read: true)
  end
  def update_notif
    return unless params.present?
    
    # Prepare the attributes to update
    attributes = {
      employee_id: params[:employee_id],
      cash_adv_request_id: params[:cash_adv_request_id],
      action: params[:action]
    }
  
    # Conditionally add repayment_schedule_id if present
    attributes[:repayment_schedule_id] = params[:repayment_schedule_id] if params[:repayment_schedule_id].present?
    attributes[:message] = params[:message] if params[:message].present?
  
    # Update the columns with the prepared attributes
    update_columns(attributes)
  end
  
end
