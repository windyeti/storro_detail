class CreateVls < ActiveRecord::Migration[5.0]
  def change
    create_table :vls do |t|
      t.string :code
      t.string :title
      t.integer :quantity
      t.bigint :productid_product
      t.string :vendor
      t.boolean :check
      t.string :price
      t.string :barcode
      t.string :image

      t.timestamps
    end
  end
end
