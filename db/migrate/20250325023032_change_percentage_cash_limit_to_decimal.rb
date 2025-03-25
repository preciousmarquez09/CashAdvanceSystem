class ChangePercentageCashLimitToDecimal < ActiveRecord::Migration[6.0]
  def change
    change_column :eligibilities, :percentage_cash_limit, :decimal, precision: 5, scale: 2
  end
end
