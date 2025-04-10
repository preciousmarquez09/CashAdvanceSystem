class ReorderColumnsInPayrolls < ActiveRecord::Migration[6.0]
  def change
    # Remove the 'cashadv' column first
    remove_column :payrolls, :cashadv

    # Add 'cashadv' column again after 'pagibig'
    add_column :payrolls, :cashadv, :integer, after: :pagibig
  end
end