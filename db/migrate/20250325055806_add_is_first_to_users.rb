class AddIsFirstToUsers < ActiveRecord::Migration[6.0]
  def change
    add_column :users, :is_first, :boolean, default: false
  end
end
