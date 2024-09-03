class CreateDialies < ActiveRecord::Migration[7.0]
  def change
    create_table :dialies do |t|
      t.date :date
      t.string :title
      t.text :text

      t.timestamps
    end
  end
end