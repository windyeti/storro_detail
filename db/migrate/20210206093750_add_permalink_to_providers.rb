class AddPermalinkToProviders < ActiveRecord::Migration[5.0]
  def change
    add_column :providers, :permalink, :string
  end
end
