class AddInterestAmountToCashAdvRequest < ActiveRecord::Migration[6.0]
  def change
    add_column :cash_adv_requests, :interest_amount, :decimal, precision: 5, scale: 2
  end
end
