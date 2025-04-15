class CreatePayrolls < ActiveRecord::Migration[6.0]
  def change
    create_table :payrolls do |t|
      t.bigint :employee_id, null: false
      t.string :description
      t.decimal :basic
      t.decimal :sss
      t.decimal :philhealth
      t.decimal :pagibig
      t.decimal :net_amount
 

      t.timestamps
    end
    add_index :payrolls, :employee_id
    add_foreign_key :payrolls, :users, column: :employee_id
  end
end
