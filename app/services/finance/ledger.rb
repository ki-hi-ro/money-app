module Finance
  class Ledger
    attr_reader :entries

    def initialize(entries)
      @entries = entries.to_a
    end

    # Prefer the actual statement window; otherwise derive it from the card settings.
    def card_period(entry)
      if entry.statement_start_on && entry.statement_end_on
        entry.statement_start_on..entry.statement_end_on
      else
        entry.payment_card.period_for(entry.date)
      end
    end

    def recorded_card_total(entry)
      return 0 unless entry.date
      period = card_period(entry)
      entries.select { |item| item.date && period.cover?(item.date) && item.kind == "支出" && item.card_payment? && item.payment_card_id == entry.payment_card_id && item.status == "完了" }.sum { |item| item.amount.to_i }
    end

    def amount(entry)
      return entry.amount.to_i unless entry.card_debit? && !entry.card_confirmed_amount.nil? && entry.date
      return entry.card_confirmed_amount unless entry.status == "未確定"
      [entry.card_confirmed_amount, recorded_card_total(entry)].max
    end
  end
end
