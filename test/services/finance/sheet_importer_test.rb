require "test_helper"

class Finance::SheetImporterTest < ActiveSupport::TestCase
  setup do
    @user = User.create!(confirmed_at: Time.current, email: "import-test@example.test", password: "password12345")
    @data = { "version" => 1,
      "assets" => [["資産", "残高", "更新日"], ["銀行", "¥1,000", "2026/09/19"], ["ポイント", "10pt", "2026/09/19"], ["合計", "¥1,010"]],
      "entries" => [["日付"], [nil, nil, "収入", nil, nil, "未定の収入", nil, "未確定"]],
      "tasks" => [["項目"], ["残高確認", "2026/09/20", nil, "TRUE"]],
      "history" => [["年月", "銀行", "ポイント", "合計"], ["2026年8月", "¥2,000", "-", "¥2,000"]] }
  end

  test "import preserves pending blanks, points and is repeatable" do
    importer = Finance::SheetImporter.new(@user, @data)
    2.times { importer.import! }
    assert_equal 2, @user.asset_accounts.count
    assert_equal 1, @user.cash_entries.count
    assert_nil @user.cash_entries.first.amount
    assert @user.money_tasks.first.completed
    assert_equal 2000, @user.asset_snapshots.first.total
    assert_nil @user.asset_snapshots.first.balances["ポイント"]
  end

  test "inconsistent totals roll back the entire import" do
    @data["history"][1][3] = "999"
    assert_raises(ArgumentError) { Finance::SheetImporter.new(@user, @data).import! }
    assert_equal 0, @user.asset_accounts.count
    assert_equal 0, @user.cash_entries.count
  end
end
