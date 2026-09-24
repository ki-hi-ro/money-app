require "test_helper"

class MultiUserTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  setup do
    @owner, @other = users(:one), users(:two)
  end

  test "all legacy and finance resources require login" do
    [posts_index_path, dialies_path, finance_root_path, finance_accounts_path, finance_entries_path,
     finance_cards_path, finance_snapshots_path, finance_tasks_path, edit_finance_settings_path].each do |path|
      get path
      assert_redirected_to new_user_session_path
    end
  end

  test "owners cannot read change or delete another users records" do
    sign_in @other
    account = @owner.asset_accounts.create!(name: "秘密の口座", balance: 123, balance_on: Date.current)
    card = @owner.payment_cards.create!(name: "秘密のカード")
    entry = @owner.cash_entries.create!(kind: "支出", status: "完了", amount: 1, date: Date.current, description: "秘密の支出")
    task = @owner.money_tasks.create!(title: "秘密の予定")
    snapshot = @owner.asset_snapshots.create!(month: Date.current, balances: { "秘密" => 123 })
    [[finance_account_path(account), :asset_account], [finance_card_path(card), :payment_card],
     [finance_entry_path(entry), :cash_entry], [finance_task_path(task), :money_task],
     [finance_snapshot_path(snapshot), :asset_snapshot], [dialy_path(dialies(:one)), :dialy]].each do |path, key|
      sign_in @other
      assert_raises(ActiveRecord::RecordNotFound) { get "#{path}/edit" }
      sign_in @other
      assert_raises(ActiveRecord::RecordNotFound) { patch path, params: { key => { name: "侵入" } } }
      sign_in @other
      assert_raises(ActiveRecord::RecordNotFound) { delete path }
    end
    sign_in @other
    assert_raises(ActiveRecord::RecordNotFound) { delete "/posts/#{posts(:one).id}" }
    sign_in @other
    [finance_accounts_path, finance_entries_path, finance_cards_path, finance_tasks_path, finance_snapshots_path].each do |path|
      get path
      assert_response :success
      assert_no_match(/秘密/, response.body)
    end
    patch finance_settings_path, params: { user: { id: @owner.id, monthly_card_budget: 1234, confirmed_at: Time.current } }
    assert_equal 0, @owner.reload.monthly_card_budget
    assert_equal 1234, @other.reload.monthly_card_budget
    assert_no_difference "CashEntry.count" do
      post finance_entries_path, params: { cash_entry: { kind: "支出", status: "完了", date: Date.current,
        amount: 100, description: "買い物", payment_type: "card", payment_card_id: card.id, user_id: @owner.id } }
    end
    assert_response :unprocessable_content
  end

  test "registration confirmation and password recovery work end to end" do
    assert_difference "User.count", 1 do
      assert_difference "ActionMailer::Base.deliveries.size", 1 do
        post user_registration_path, params: { user: { email: "new@example.test", password: "new-password-123", password_confirmation: "new-password-123" } }
      end
    end
    user = User.find_by!(email: "new@example.test")
    assert_not user.confirmed?
    assert_equal 0, user.monthly_card_budget
    post user_session_path, params: { user: { email: user.email, password: "new-password-123" } }
    get finance_root_path
    assert_redirected_to new_user_session_path
    token = ActionMailer::Base.deliveries.last.body.decoded[/confirmation_token=([^"&<]+)/, 1]
    assert token.present?
    get user_confirmation_path(confirmation_token: token)
    assert user.reload.confirmed?
    post user_session_path, params: { user: { email: user.email, password: "new-password-123" } }
    get finance_root_path
    assert_response :success
    assert_select "h2", "まずは口座残高を登録"
    delete destroy_user_session_path
    post user_password_path, params: { user: { email: user.email } }
    token = ActionMailer::Base.deliveries.last.body.decoded[/reset_password_token=([^"&<]+)/, 1]
    assert token.present?
    put user_password_path, params: { user: { reset_password_token: token, password: "changed-password-123", password_confirmation: "changed-password-123" } }
    assert user.reload.valid_password?("changed-password-123")
  end

  test "five failed logins temporarily lock account" do
    5.times { post user_session_path, params: { user: { email: @owner.email, password: "wrong-password" } } }
    assert @owner.reload.access_locked?
    post user_session_path, params: { user: { email: @owner.email, password: "password12345" } }
    get finance_root_path
    assert_redirected_to new_user_session_path
  end

  test "card management settings and deletion preserve referenced records" do
    sign_in @owner
    [new_user_registration_path, new_user_password_path, new_user_confirmation_path, edit_user_registration_path,
     edit_finance_settings_path, new_finance_card_path].each do |path|
      get path
      assert response.successful? || response.redirect?
    end
    post finance_cards_path, params: { payment_card: { name: "自分のカード", closing_day: 31, payment_month_offset: 1 } }
    assert_response :redirect
    card = @owner.payment_cards.last
    post finance_entries_path, params: { cash_entry: { kind: "支出", status: "完了", date: Date.current,
      amount: 100, description: "買い物", payment_type: "card", payment_card_id: card.id } }
    assert_response :redirect
    assert_no_difference "PaymentCard.count" do
      delete finance_card_path(card)
    end
    patch finance_settings_path, params: { user: { monthly_card_budget: -1 } }
    assert_response :unprocessable_content
    delete user_registration_path
    assert_not User.exists?(@owner.id)
    assert_not PaymentCard.exists?(card.id)
    assert User.exists?(@other.id)
  end
end
