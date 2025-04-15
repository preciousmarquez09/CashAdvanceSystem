class RenameEmployeeIdToUserId < ActiveRecord::Migration[6.0]
  def change
    rename_column :payrolls, :employee_id, :user_id
  end
end


