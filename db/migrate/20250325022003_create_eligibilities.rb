class CreateEligibilities < ActiveRecord::Migration[6.0]
  def change
    create_table :eligibilities do |t|
      t.integer :percentage_cash_limit
      t.integer :min_net_salary
      t.integer :req_decline_days
      t.integer :req_approve_days
      t.decimal :interest_rate

      t.timestamps
    end
  end
end
