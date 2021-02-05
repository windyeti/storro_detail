class AddVisibleToProducts < ActiveRecord::Migration[5.0]
  def change
    add_column :products, :visible, :boolean, default: true
  end
end
