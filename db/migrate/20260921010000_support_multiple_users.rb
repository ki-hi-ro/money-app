class SupportMultipleUsers < ActiveRecord::Migration[7.0]
  def up
    add_column :users, :monthly_card_budget, :decimal, precision: 20, scale: 6, default: 0, null: false
    add_column :users, :monthly_living_budget, :bigint
    add_column :users, :confirmation_token, :string
    add_column :users, :confirmed_at, :datetime
    add_column :users, :confirmation_sent_at, :datetime
    add_column :users, :unconfirmed_email, :string
    add_column :users, :failed_attempts, :integer, default: 0, null: false
    add_column :users, :locked_at, :datetime
    add_index :users, :confirmation_token, unique: true
    # Existing accounts keep access. Budgets default to zero for a fresh installation.
    execute "UPDATE users SET confirmed_at = CURRENT_TIMESTAMP"
    create_table :payment_cards do |t|
      t.references :user, null: false, foreign_key: true
      t.string :name, null: false
      t.integer :closing_day, default: 27, null: false
      t.integer :payment_month_offset, default: 1, null: false
      t.timestamps
    end
    add_index :payment_cards, [:user_id, :name], unique: true
    add_reference :cash_entries, :payment_card, foreign_key: true
    add_column :cash_entries, :payment_type, :string, default: 'other', null: false
    # Retain the legacy text for audit/export; use typed fields for new calculations.
    execute <<~SQL
      INSERT INTO payment_cards (user_id, name, closing_day, payment_month_offset, created_at, updated_at)
      SELECT DISTINCT user_id, 'クレジットカード（引継ぎ）', 27, 1, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP
      FROM cash_entries WHERE payment_method = 'クレジットカード' OR (kind = '口座引き落とし' AND description = 'クレジットカード')
    SQL
    execute <<~SQL
      UPDATE cash_entries SET payment_type = 'card', payment_card_id = payment_cards.id
      FROM payment_cards WHERE cash_entries.user_id = payment_cards.user_id
      AND (cash_entries.payment_method = 'クレジットカード' OR (cash_entries.kind = '口座引き落とし' AND cash_entries.description = 'クレジットカード'))
    SQL
    add_reference :posts, :user, foreign_key: true
    add_reference :dialies, :user, foreign_key: true
    # Legacy records are assigned only when ownership is unambiguous.
    execute "UPDATE posts SET user_id = (SELECT MIN(id) FROM users) WHERE (SELECT COUNT(*) FROM users) = 1"
    execute "UPDATE dialies SET user_id = (SELECT MIN(id) FROM users) WHERE (SELECT COUNT(*) FROM users) = 1"
  end

  def down
    raise ActiveRecord::IrreversibleMigration, 'Restore the pre-migration backup to preserve ownership and card metadata.'
  end
end
