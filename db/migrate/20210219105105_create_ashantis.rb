class CreateAshantis < ActiveRecord::Migration[5.0]
  def change
    create_table :ashantis do |t|
      t.string :barcode
      t.string :vendorcode
      t.string :images
      t.string :title
      t.string :weight
      t.string :use_until
      t.string :price
      t.integer :quantity
      t.string :desc
      t.bigint :productid_product
      t.boolean :check

      t.timestamps
    end
  end
end
