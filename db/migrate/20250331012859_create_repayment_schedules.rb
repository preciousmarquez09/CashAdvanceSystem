class CreateRepaymentSchedules < ActiveRecord::Migration[6.0]
  def change
    create_table :repayment_schedules do |t|
      t.references :cash_adv_request, null: false, foreign_key: true
      t.decimal :amount, precision: 10, scale: 2
      t.date :due_date
      t.string :status

      t.timestamps
    end
  end
end
