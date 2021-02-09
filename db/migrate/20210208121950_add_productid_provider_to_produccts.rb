class AddProductidProviderToProduccts < ActiveRecord::Migration[5.0]
  def change
    add_column :products, :productid_provider, :bigint
  end
end
