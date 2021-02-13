class AddProductidProductToMbs < ActiveRecord::Migration[5.0]
  def change
    add_column :mbs, :productid_product, :bigint
  end
end
