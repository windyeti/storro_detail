class AddProviderPriceToProducts < ActiveRecord::Migration[5.0]
  def change
    add_column :products, :provider_price, :decimal
    add_column :products, :productid_insales, :bigint
    add_column :products, :productid_var_insales, :bigint
    add_column :products, :product_sku_provider, :string
    add_column :products, :sku_var, :string
    add_reference :products, :provider, foreign_keys: true
  end
end
