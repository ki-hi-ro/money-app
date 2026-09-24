require "test_helper"

class Finance::ForecastTest < ActiveSupport::TestCase
  setup do
    @card = users(:one).payment_cards.create!(name: "テストカード", closing_day: 27)
  end

  def entry(**attrs)
    if attrs[:payment_method] == "クレジットカード" || attrs[:description] == "クレジットカード"
      attrs.merge!(payment_type: "card", payment_card: @card)
    end
    CashEntry.new({ date: Date.new(2026, 9, 20), kind: "支出", status: "完了", amount: 0, description: "買い物" }.merge(attrs))
  end

  def forecast(entries)
    Finance::Forecast.new(accounts: [AssetAccount.new(balance: 1_000_000, balance_on: Date.new(2026, 9, 19))], entries: entries, user: User.new(monthly_card_budget: BigDecimal("160000")))
  end

  test "forecast follows source date boundaries, statuses and transfer exclusions" do
    entries = [
      entry(date: Date.new(2026, 9, 19), kind: "収入", status: "確定", amount: 999999),
      entry(date: Date.new(2026, 10, 19), kind: "収入", status: "確定", amount: 100000),
      entry(date: Date.new(2026, 10, 20), kind: "収入", status: "確定", amount: 999999),
      entry(kind: "収入", status: "未確定", amount: 50000),
      entry(kind: "収入", status: "完了", amount: 999999),
      entry(kind: "振替", status: "確定", amount: 999999),
      entry(date: nil, kind: "収入", status: "未確定", amount: nil),
      entry(date: Date.new(2026, 8, 20), amount: 999999),
      entry(date: Date.new(2026, 8, 21), amount: 1000),
      entry(date: Date.new(2026, 9, 19), amount: 2000),
      entry(date: Date.new(2026, 9, 19), category: "旅行・臨時", amount: 999999),
      entry(date: Date.new(2026, 9, 19), payment_method: "クレジットカード", amount: 999999)
    ]
    result = forecast(entries)
    assert_equal 3000, result.living_monthly
    row = result.rows.first
    assert_equal [100000], row[:breakdown][:confirmed][:income_entries].map(&:amount)
    assert_equal [50000, 100000], row[:breakdown][:expected][:income_entries].map(&:amount)
    assert_equal row[:breakdown][:expected][:income], row[:breakdown][:expected][:income_entries].sum(&:amount)
    assert_equal 937000, row[:confirmed].round
    assert_equal 987000, row[:expected].round
  end

  test "card baseline and pending debit use maximum without double counting" do
    entries = [entry(kind: "口座引き落とし", description: "クレジットカード", status: "確定", amount: 200000), entry(kind: "口座引き落とし", description: "クレジットカード", status: "未確定", amount: 10000), entry(kind: "口座引き落とし", description: "家賃", status: "未確定", amount: 50000)]
    row = forecast(entries).rows.first
    assert_equal 800000, row[:confirmed]
    assert_equal 740000, row[:expected]
  end

  test "breakdown reconciles both scenarios over every forecast period" do
    result = forecast([
      entry(kind: "収入", status: "確定", amount: 100000),
      entry(kind: "口座引き落とし", description: "家賃", status: "未確定", amount: 50000),
      entry(kind: "口座引き落とし", description: "クレジットカード", status: "確定", amount: 200000),
      entry(date: Date.new(2026, 9, 19), amount: 3000)
    ])
    result.rows.each do |row|
      row[:breakdown].each do |scenario, parts|
        assert_equal 100000, parts[:income]
        assert_equal(scenario == :confirmed ? 0 : 50000, parts[:other_debits])
        assert_equal 200000, parts[:card_debits]
        assert_equal 3000 * row[:days] / 30, parts[:living_cost]
        assert_equal [parts[:card_baseline], 200000].max, parts[:card_cost]
        assert_equal row[scenario], parts[:starting_balance] + parts[:income] - parts[:other_debits] - parts[:card_cost] - parts[:living_cost]
        assert_equal row[scenario], parts[:balance]
      end
    end
  end

  test "empty accounts produce no forecast" do
    assert_empty Finance::Forecast.new(accounts: [], entries: []).rows
  end

  test "card reconciliation excludes transfers, uses inclusive shifted months and freezes confirmed amount" do
    debit = entry(date: Date.new(2026, 10, 27), kind: "口座引き落とし", description: "クレジットカード", status: "未確定", card_confirmed_amount: 1500)
    entries = [debit, entry(date: Date.new(2026, 8, 28), amount: 1000, payment_method: "クレジットカード"), entry(date: Date.new(2026, 9, 27), amount: 2000, payment_method: "クレジットカード"), entry(date: Date.new(2026, 8, 27), amount: 99999, payment_method: "クレジットカード"), entry(kind: "振替", amount: 99999, payment_method: "クレジットカード"), entry(status: "確定", amount: 99999, payment_method: "クレジットカード")]
    ledger = Finance::Ledger.new(entries)
    assert_equal 3000, ledger.recorded_card_total(debit)
    assert_equal 3000, ledger.amount(debit)
    debit.status = "確定"
    assert_equal 1500, ledger.amount(debit)
    debit.card_confirmed_amount = nil
    debit.amount = 4000
    assert_equal 4000, ledger.amount(debit)
  end
end
