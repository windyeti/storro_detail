class AddRemoteStoreToProduct < ActiveRecord::Migration[5.0]
  def change
    add_column :products, :store, :integer
  end
end
