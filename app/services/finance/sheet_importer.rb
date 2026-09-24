module Finance
  class SheetImporter
    def initialize(user, data)
      @user, @data = user, data
    end

    def import!
      raise ArgumentError, "未対応の取り込み形式です" unless @data.fetch("version") == 1
      ApplicationRecord.transaction do
        import_accounts
        import_entries
        import_tasks
        import_history
      end
    end

    private

    def integer(value)
      return nil if value.nil? || value.to_s.strip.empty? || value == "-"
      Integer(value.to_s.gsub(/[¥￥,円\s]|pt/, ""), 10)
    end

    def date(value)
      value.present? ? Date.strptime(value, "%Y/%m/%d") : nil
    end

    def import_accounts
      @data.fetch("assets").drop(1).take_while { |row| row.first.present? && row.first != "合計" }.each_with_index do |row, i|
        @user.asset_accounts.find_or_initialize_by(name: row[0]).update!(balance: integer(row[1]), balance_on: date(row[2]), unit: row[1].to_s.include?("pt") ? "pt" : "円", position: i)
      end
    end

    def import_entries
      @data.fetch("entries").drop(1).each_with_index do |row, i|
        next if row.compact.all?(&:blank?)
        card_payment = row[6] == "クレジットカード" || (row[2] == "口座引き落とし" && row[5] == "クレジットカード")
        card = card_payment ? @user.payment_cards.find_or_create_by!(name: "クレジットカード（引継ぎ）") : nil
        payment_date = date(row[0])
        statement = card_payment && row[2] == "口座引き落とし" && payment_date
        @user.cash_entries.find_or_initialize_by(source_key: "sheet:entry:#{i + 2}").update!(
          statement_start_on: statement ? (payment_date << 2) + 1 : nil,
          statement_end_on: statement ? payment_date << 1 : nil,
          payment_type: card_payment ? "card" : "other", payment_card: card,
          date: payment_date, kind: row[2], amount: integer(row[3]), category: row[4],
          description: row[5], payment_method: row[6], status: row[7], notes: row[8],
          card_confirmed_amount: integer(row[9])
        )
      end
    end

    def import_tasks
      @data.fetch("tasks").drop(1).each_with_index do |row, i|
        next if row[0].blank?
        @user.money_tasks.find_or_initialize_by(source_key: "sheet:task:#{i + 2}").update!(title: row[0], due_on: date(row[1]), due_time: row[2], completed: row[3].to_s.upcase == "TRUE")
      end
    end

    def import_history
      table = @data.fetch("history")
      names = table.first[1...table.first.index("合計")]
      table.drop(1).each do |row|
        next if row[0].blank?
        month = Date.strptime(row[0], "%Y年%m月")
        balances = names.zip(row[1, names.size].map { |value| integer(value) }).to_h
        snapshot = @user.asset_snapshots.find_or_initialize_by(month: month)
        snapshot.update!(balances: balances)
        raise ArgumentError, "#{row[0]}の残高合計がシートと一致しません" unless snapshot.total == integer(row[names.size + 1])
      end
    end
  end
end
