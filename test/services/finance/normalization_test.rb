require "test_helper"

class Finance::NormalizationTest < ActiveSupport::TestCase
  test "import turns a text date into a real date included in card totals" do
    user = User.create!(confirmed_at: Time.current, email: "normalization@example.test", password: "password12345")
    data = { "version" => 1, "assets" => [["資産"]], "history" => [["年月", "合計"]], "tasks" => [["項目"]], "entries" => [["日付"], ["2026/09/20", "日", "支出", "¥310", "娯楽", "利用明細", "クレジットカード", "完了"]] }
    Finance::SheetImporter.new(user, data).import!
    debit = CashEntry.new(payment_type: "card", payment_card: user.payment_cards.first, date: Date.new(2026, 10, 27), kind: "口座引き落とし", description: "クレジットカード", status: "未確定", card_confirmed_amount: 0)
    assert_equal 310, Finance::Ledger.new(user.cash_entries).amount(debit)
  end
end
