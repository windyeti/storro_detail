class AddAmountToProducts < ActiveRecord::Migration[5.0]
  def change
    add_column :products, :komplekt, :decimal
  end
end
