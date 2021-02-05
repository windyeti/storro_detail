class CreateProviders < ActiveRecord::Migration[5.0]
  def change
    create_table :providers do |t|
      t.string :name
      t.string :prefix
      t.string :link

      t.timestamps
    end
  end
end
