require "bigdecimal"

module Finance
  class Forecast
    attr_reader :base_date, :total, :living_monthly, :living_entries, :ledger, :card_monthly, :mixed_dates, :living_automatic

    def initialize(accounts:, entries:, user: nil)
      accounts = accounts.to_a
      dates = accounts.map(&:balance_on).compact.uniq
      @mixed_dates = dates.length > 1
      @base_date = dates.one? ? dates.first : nil
      @total = accounts.sum(&:balance)
      @card_monthly = user&.monthly_card_budget || 0
      @ledger = Ledger.new(entries)
      @living_entries = base_date ? ledger.entries.select { |e|
        e.date && e.date > base_date - 30 && e.date <= base_date && e.kind == "支出" && e.status == "完了" &&
          !e.card_payment? && e.category != "旅行・臨時"
      }.sort_by { |e| [e.date, e.id || 0] } : []
      @living_automatic = user&.monthly_living_budget.nil?
      @living_monthly = living_automatic ? living_entries.sum { |e| ledger.amount(e) } : user.monthly_living_budget
    end

    def rows
      return [] unless base_date
      [30, 60, 90].map do |days|
        months = days / 30
        future = ledger.entries.select { |e| e.date && e.date > base_date && e.date <= base_date + days }
        confirmed = calculate(future, ["確定"], months)
        expected = calculate(future, ["確定", "未確定"], months)
        { days: days, date: base_date + days, confirmed: confirmed[:balance], expected: expected[:balance],
          breakdown: { confirmed: confirmed, expected: expected } }
      end
    end

    private

    def calculate(entries, statuses, months)
      selected = entries.select { |e| statuses.include?(e.status) }.sort_by { |e| [e.date, e.id || 0] }
      income_entries = selected.select { |e| e.kind == "収入" }
      income = income_entries.sum { |e| ledger.amount(e) }
      debits = selected.select { |e| e.kind == "口座引き落とし" }
      card_entries = debits.select(&:card_debit?)
      card = card_entries.sum { |e| ledger.amount(e) }
      other_entries = debits.reject(&:card_debit?)
      # Card purchases are accounted for at payment time, not again on purchase day.
      expenses = selected.select { |e| e.kind == "支出" && !e.card_payment? }
      extra_entries = expenses.select { |e| e.category == "旅行・臨時" }
      other_entries += extra_entries
      other = other_entries.sum { |e| ledger.amount(e) }
      planned_living = (expenses - extra_entries).sum { |e| ledger.amount(e) }
      card_baseline = card_monthly * months
      card_cost = [card_baseline, card].max
      living_baseline = living_monthly * months
      living_cost = [living_baseline, planned_living].max
      { starting_balance: total, income: income, income_entries: income_entries, other_debits: other,
        card_baseline: card_baseline, card_debits: card, card_cost: card_cost,
        card_entries: card_entries, other_debit_entries: other_entries,
        planned_living: planned_living, planned_living_entries: expenses - extra_entries, living_baseline: living_baseline,
        living_cost: living_cost, balance: total + income - other - card_cost - living_cost }
    end
  end
end
