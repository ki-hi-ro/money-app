class AddColumnsToPosts < ActiveRecord::Migration[7.0]
  def change
    add_column :posts, :date, :date
    add_column :posts, :price, :integer
  end
end
