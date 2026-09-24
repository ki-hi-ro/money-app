class PreserveStatementPeriods < ActiveRecord::Migration[7.0]
  def up
    add_column :cash_entries, :statement_start_on, :date
    add_column :cash_entries, :statement_end_on, :date
    # Preserve each imported statement's original date window, independent of card settings.
    execute <<~SQL
      UPDATE cash_entries SET statement_start_on = (date - INTERVAL '2 months')::date + 1,
        statement_end_on = (date - INTERVAL '1 month')::date
      WHERE kind = '口座引き落とし' AND payment_type = 'card' AND date IS NOT NULL
    SQL
  end

  def down
    remove_column :cash_entries, :statement_start_on
    remove_column :cash_entries, :statement_end_on
  end
end
