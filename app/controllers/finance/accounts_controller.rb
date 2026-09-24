module Finance
  class AccountsController < RecordsController
    RESOURCE = :asset_accounts
    TITLE = "資産残高"
    FIELDS = [[:name, "資産名", :text], [:balance, "残高", :number], [:balance_on, "更新日", :date], [:unit, "単位", ["円", "pt"]]].freeze
  end
end
