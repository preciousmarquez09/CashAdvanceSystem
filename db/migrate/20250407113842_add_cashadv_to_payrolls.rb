class AddCashadvToPayrolls < ActiveRecord::Migration[6.0]
  def change
    add_column :payrolls, :cashadv, :decimal
  end
end
