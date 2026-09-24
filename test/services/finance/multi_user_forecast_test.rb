require "test_helper"

class Finance::MultiUserForecastTest < ActiveSupport::TestCase
  def entry(**attributes)
    CashEntry.new({ kind: "支出", status: "確定", date: Date.new(2026, 9, 25), amount: 0, description: "予定" }.merge(attributes))
  end

  def forecast(entries = [], user: User.new, accounts: nil)
    Finance::Forecast.new(user: user, accounts: accounts || [AssetAccount.new(balance: 100000, balance_on: "2026-09-19")], entries: entries)
  end

  test "new users have no personal fixed card estimate" do
    assert_equal [100000, 100000, 100000], forecast.rows.map { |r| r[:expected] }
    assert_equal 90000, forecast(user: User.new(monthly_card_budget: 10000)).rows.first[:expected]
  end

  test "planned ordinary and special expenses are included without counting living budget twice" do
    result = forecast([entry(amount: 10000), entry(amount: 30000, category: "旅行・臨時")], user: User.new(monthly_living_budget: 20000))
    assert_equal 50000, result.rows.first[:expected]
    assert_equal 0, forecast([entry(amount: 100000)], user: User.new(monthly_living_budget: 20000)).rows.first[:expected]
  end

  test "past pending expenses do not inflate living estimate and mixed balance dates stop forecast" do
    result = forecast([entry(date: Date.new(2026, 9, 18), amount: 10000, status: "未確定")])
    assert_equal 0, result.living_monthly
    result = forecast(accounts: [AssetAccount.new(balance: 10, balance_on: "2026-09-19"), AssetAccount.new(balance: 20, balance_on: "2026-09-18")])
    assert result.mixed_dates
    assert_equal 30, result.total
    assert_empty result.rows
  end

  test "card statements isolate cards and handle leap year month ends" do
    user = users(:one)
    card = user.payment_cards.create!(name: "A", closing_day: 31, payment_month_offset: 1)
    other = user.payment_cards.create!(name: "B", closing_day: 15, payment_month_offset: 1)
    debit = entry(payment_type: "card", payment_card: card, date: Date.new(2024, 3, 27), kind: "口座引き落とし", status: "未確定", card_confirmed_amount: 0)
    entries = [entry(payment_type: "card", payment_card: card, date: Date.new(2024, 2, 29), amount: 200, status: "完了"),
      entry(payment_type: "card", payment_card: other, date: Date.new(2024, 2, 29), amount: 999, status: "完了"),
      entry(payment_type: "card", payment_card: card, date: Date.new(2024, 3, 1), amount: 999, status: "完了")]
    ledger = Finance::Ledger.new(entries)
    assert_equal Date.new(2024, 2, 1)..Date.new(2024, 2, 29), ledger.card_period(debit)
    assert_equal 200, ledger.amount(debit)
  end
  test "explicit statement periods preserve imported windows and reject incomplete ranges" do
    user = users(:one)
    card = user.payment_cards.create!(name: "明細カード", closing_day: 15)
    debit = entry(user: user, payment_type: "card", payment_card: card, kind: "口座引き落とし",
      date: Date.new(2026, 10, 30), statement_start_on: Date.new(2026, 8, 31), statement_end_on: Date.new(2026, 9, 30))
    assert debit.valid?
    assert_equal Date.new(2026, 8, 31)..Date.new(2026, 9, 30), Finance::Ledger.new([]).card_period(debit)
    debit.statement_end_on = nil
    assert_not debit.valid?
  end

  test "statement closing after the payment date is rejected" do
    user = users(:one)
    card = user.payment_cards.create!(name: "当月カード", closing_day: 31, payment_month_offset: 0)
    debit = entry(user: user, payment_type: "card", payment_card: card, kind: "口座引き落とし", date: Date.new(2026, 9, 20))
    assert_not debit.valid?
    assert debit.errors[:payment_card].any?
  end

end
