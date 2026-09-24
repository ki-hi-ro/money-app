class CreateFinanceWorkspace < ActiveRecord::Migration[7.0]
  def change
    create_table :asset_accounts do |t|
      t.references :user, null: false, foreign_key: true
      t.string :name, null: false
      t.bigint :balance, null: false, default: 0
      t.date :balance_on, null: false
      t.string :unit, null: false, default: "円"
      t.integer :position, null: false, default: 0
      t.timestamps
    end
    add_index :asset_accounts, [:user_id, :name], unique: true
    create_table :cash_entries do |t|
      t.references :user, null: false, foreign_key: true
      t.date :date
      t.string :kind, null: false
      t.bigint :amount
      t.string :category
      t.string :description, null: false
      t.string :payment_method
      t.string :status, null: false, default: "完了"
      t.text :notes
      t.bigint :card_confirmed_amount
      t.string :source_key
      t.timestamps
    end
    add_index :cash_entries, [:user_id, :date]
    add_index :cash_entries, [:user_id, :source_key], unique: true
    create_table :money_tasks do |t|
      t.references :user, null: false, foreign_key: true
      t.string :title, null: false
      t.date :due_on
      t.time :due_time
      t.boolean :completed, null: false, default: false
      t.string :source_key
      t.timestamps
    end
    add_index :money_tasks, [:user_id, :source_key], unique: true
    create_table :asset_snapshots do |t|
      t.references :user, null: false, foreign_key: true
      t.date :month, null: false
      t.jsonb :balances, null: false, default: {}
      t.timestamps
    end
    add_index :asset_snapshots, [:user_id, :month], unique: true
  end
end
