class RenameCarttitleToCattitle < ActiveRecord::Migration[5.0]
  def change
    rename_column :products, :carttitle, :cattitle
  end
end
