class AddColumnCarttitleAndPricePrToProducts < ActiveRecord::Migration[5.0]
  def change
    add_column :products, :carttitle, :string
    add_column :products, :pricepr, :integer
  end
end
