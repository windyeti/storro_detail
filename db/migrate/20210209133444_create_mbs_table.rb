class CreateMbsTable < ActiveRecord::Migration[5.0]
  def change
    create_table :mbs do |t|
      t.string :fid
      t.boolean :available
      t.integer :quantity
      t.string :link
      t.string :pict
      t.string :price
      t.string :currencyid
      t.string :cat
      t.string :title
      t.string :desc
      t.string :vendorcode
      t.string :barcode
      t.string :country
      t.string :brend
      t.string :param

      t.timestamps
    end
  end
end
