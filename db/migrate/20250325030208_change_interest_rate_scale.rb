class ChangeInterestRateScale < ActiveRecord::Migration[6.0]
  def change
    change_column :eligibilities, :interest_rate, :decimal, precision: 5, scale: 2
  end
end
