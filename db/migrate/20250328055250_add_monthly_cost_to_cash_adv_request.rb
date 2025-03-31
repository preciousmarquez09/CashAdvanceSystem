class AddMonthlyCostToCashAdvRequest < ActiveRecord::Migration[6.0]
  def change
    add_column :cash_adv_requests, :monthly_cost, :decimal, precision: 10, scale: 2
  end
end
