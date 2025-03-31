class ChangePercentageAndInterestToInteger < ActiveRecord::Migration[6.0]
  def change
    change_column :eligibilities, :percentage_cash_limit, :integer
    change_column :eligibilities, :interest_rate, :integer
  end
end
