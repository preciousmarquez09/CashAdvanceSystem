class ChangeCutOffToString < ActiveRecord::Migration[6.0]
  def up
    change_column :cash_adv_requests, :cut_off, :string
  end

  def down
    change_column :cash_adv_requests, :integer
  end
end
