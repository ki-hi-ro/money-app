require "test_helper"

class FinanceTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  setup do
    @user = User.create!(confirmed_at: Time.current, email: "finance-test@example.test", password: "password12345")
  end

  test "financial pages require login" do
    get finance_root_path
    assert_redirected_to new_user_session_path
    follow_redirect!
    assert_select "h1", "ログイン"
  end

  test "owner can create records, view all screens and cannot edit another owner's record" do
    sign_in @user
    post finance_accounts_path, params: { asset_account: { name: "銀行", balance: 500000, balance_on: "2026-09-19", unit: "円" } }
    assert_redirected_to finance_accounts_path
    get finance_accounts_path
    assert_select "tbody td", text: "円"
    post finance_entries_path, params: { cash_entry: { date: "2026-09-23", kind: "収入", amount: 10000, description: "給与", status: "確定" } }
    assert_redirected_to finance_entries_path
    post finance_tasks_path, params: { money_task: { title: "残高確認", due_on: "2026-09-25" } }
    assert_redirected_to finance_tasks_path
    post finance_snapshots_path, params: { asset_snapshot: { month: "2026-08", balances: { "銀行" => "600000" } } }
    assert_redirected_to finance_snapshots_path
    [finance_root_path, finance_accounts_path, finance_entries_path, finance_tasks_path, finance_snapshots_path, new_finance_account_path, new_finance_entry_path, new_finance_task_path, new_finance_snapshot_path, edit_finance_snapshot_path(@user.asset_snapshots.first)].each do |url|
      get url
      assert_response :success, url
    end
    task = @user.money_tasks.first
    patch finance_task_path(task), params: { money_task: { completed: true } }
    assert task.reload.completed
    other = User.create!(confirmed_at: Time.current, email: "other-finance@example.test", password: "password12345")
    private_account = other.asset_accounts.create!(name: "別の口座", balance: 1, balance_on: Date.current)
    assert_raises(ActiveRecord::RecordNotFound) do
      patch finance_account_path(private_account), params: { asset_account: { balance: 123 } }
    end
    assert_equal 1, private_account.reload.balance
  end

  test "forecast shows changes from previous visit and retains them on refresh" do
    sign_in @user
    @user.asset_accounts.create!(name: "銀行", balance: 500000, balance_on: "2026-09-19", unit: "円")
    get finance_root_path
    assert_select ".forecast-change", count: 0
    @user.cash_entries.create!(date: "2026-09-30", kind: "収入", amount: 50000, description: "祖母から", status: "未確定")
    2.times do
      get finance_root_path
      assert_response :success
      assert_select ".forecast-change.increase strong", text: "前回から ＋50,000円", count: 3
    end
    @user.cash_entries.last.update!(amount: 30000)
    get finance_root_path
    assert_select ".forecast-change.decrease strong", text: "前回から −20,000円", count: 3
    @user.asset_accounts.first.update!(balance_on: "2026-09-20")
    get finance_root_path
    assert_select ".finance-notice", text: /予測の基準日が/
  end

  test "scenario shows cumulative impact without changing records" do
    sign_in @user
    @user.asset_accounts.create!(name: "銀行", balance: 1000000, balance_on: "2026-09-19", unit: "円")
    assert_no_difference ["CashEntry.count", "AssetSnapshot.count"] do
      get finance_root_path, params: { trial_kind: "expense", trial_amount: "10000", trial_frequency: "monthly" }
      assert_response :success
      ["−10,000円", "−20,000円", "−30,000円"].each do |amount|
        assert_select ".trial-results p", text: "予測から #{amount}"
      end
      get finance_root_path, params: { trial_kind: "income", trial_amount: "10000", trial_frequency: "once" }
      assert_select ".trial-results p", text: "予測から ＋10,000円", count: 3
    end
    assert_equal 1000000, @user.asset_accounts.first.balance
    get finance_root_path, params: { trial_amount: "-1" }
    assert_select ".finance-notice.alert"
    assert_select ".trial-results", count: 0
    get new_finance_entry_path(kind: "支出")
    assert_select "select[name='cash_entry[kind]'] option[selected]", text: "支出"
  end

  test "invalid entries preserve input and show errors" do
    sign_in @user
    assert_no_difference "CashEntry.count" do
      post finance_entries_path, params: { cash_entry: { kind: "支出", status: "完了", description: "入力不備", amount: -1 } }
    end
    assert_response :unprocessable_content
    assert_select "[role=alert]"
    assert_difference "CashEntry.count", 1 do
      post finance_entries_path, params: { cash_entry: { kind: "収入", status: "未確定", description: "予定" } }
    end
    get finance_entries_path, params: { month: "invalid" }
    assert_response :success
  end
end
