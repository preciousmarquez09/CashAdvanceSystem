class ChangePayrollAmountsToDecimalWithScale < ActiveRecord::Migration[6.0]
  def change
    change_column :payrolls, :basic, :decimal, precision: 10, scale: 2
    change_column :payrolls, :sss, :decimal, precision: 10, scale: 2
    change_column :payrolls, :philhealth, :decimal, precision: 10, scale: 2
    change_column :payrolls, :pagibig, :decimal, precision: 10, scale: 2
    change_column :payrolls, :cashadv, :decimal, precision: 10, scale: 2
    change_column :payrolls, :net_amount, :decimal, precision: 10, scale: 2
  end
end
