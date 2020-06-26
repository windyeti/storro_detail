class RenameCatinsToCharact < ActiveRecord::Migration[5.0]
  def change
   rename_column :products, :catins, :charact
  end
end
