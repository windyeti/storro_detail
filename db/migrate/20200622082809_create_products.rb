class CreateProducts < ActiveRecord::Migration[5.0]
  def change
    create_table :products do |t|
      t.string :sku
      t.string :skubrand
      t.string :barcode
      t.string :title
      t.string :sdesc
      t.string :desc
      t.string :cat
      t.string :catins
      t.decimal :costprice
      t.decimal :price
      t.string :quantity
      t.string :image
      t.string :weight
      t.string :url

      t.timestamps
    end
  end
end
