class ChangeInterestRateScaleAgain < ActiveRecord::Migration[6.0]
  def change
    change_column :eligibilities, :interest_rate, :decimal, precision: 10, scale: 4
  end
end
