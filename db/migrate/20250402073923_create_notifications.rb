class CreateNotifications < ActiveRecord::Migration[6.0]
  def change
    create_table :notifications do |t|
      t.references :recipient, polymorphic: true, null: false
      t.string :type, null: false
      t.json :params
      t.datetime :read_at
      t.integer :employee_id
      t.string :action
      t.references :cash_adv_request, null: true, foreign_key: true
      t.references :repayment_schedules, null: true, foreign_key: true
      t.timestamps
    end
    add_index :notifications, :read_at
    add_foreign_key :cash_adv_requests, :users, column: :employee_id, primary_key: :employee_id
  end
end
