class CreateProperties < ActiveRecord::Migration[5.0]
  def change
    create_table :properties do |t|
      t.boolean :status
      t.string :title

      t.timestamps
    end
  end
end
