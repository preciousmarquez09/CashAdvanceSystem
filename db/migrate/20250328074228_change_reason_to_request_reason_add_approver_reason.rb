class ChangeReasonToRequestReasonAddApproverReason < ActiveRecord::Migration[6.0]
  def change
    rename_column :cash_adv_requests, :reason, :request_reason
    add_column :cash_adv_requests, :approver_reason, :string
  end
end
