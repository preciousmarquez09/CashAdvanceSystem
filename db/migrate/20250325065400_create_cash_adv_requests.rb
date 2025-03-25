class CreateCashAdvRequests < ActiveRecord::Migration[6.0]
  def change
    create_table :cash_adv_requests do |t|
      t.integer :employee_id
      t.integer :amount
      t.text :reason
      t.binary :supporting_docs
      t.integer :repayment_months
      t.integer :cut_off
      t.string :status
      t.integer :approver_id

      t.timestamps
    end
    add_foreign_key :cash_adv_requests, :users, column: :employee_id, primary_key: :employee_id
    add_foreign_key :cash_adv_requests, :users, column: :approver_id, primary_key: :employee_id
  end
end
