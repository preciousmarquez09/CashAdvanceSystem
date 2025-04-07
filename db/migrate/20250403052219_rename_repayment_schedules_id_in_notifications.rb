class RenameRepaymentSchedulesIdInNotifications < ActiveRecord::Migration[6.0]
  def change
    rename_column :notifications, :repayment_schedules_id, :repayment_schedule_id
  end
end
