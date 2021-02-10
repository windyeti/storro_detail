class AddCheckToMbs < ActiveRecord::Migration[5.0]
  def change
    add_column :mbs, :check, :boolean, default: false
  end
end
