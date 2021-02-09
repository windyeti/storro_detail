class DropMbsTable < ActiveRecord::Migration[5.0]
  def change
    drop_table :mbs
  end
end
