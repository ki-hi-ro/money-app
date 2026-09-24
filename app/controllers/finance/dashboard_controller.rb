module Finance
  class DashboardController < BaseController
    def index
      @trial_kind = params[:trial_kind] == "income" ? "income" : "expense"
      @trial_frequency = params[:trial_frequency] == "monthly" ? "monthly" : "once"
      if params[:trial_amount].present?
        if params[:trial_amount].match?(/\A\d{1,10}\z/) && params[:trial_amount].to_i <= 1_000_000_000
          @trial_amount = params[:trial_amount].to_i
        else
          flash.now[:alert] = "試算額は0〜1,000,000,000円の整数で入力してください。"
        end
      end
      @accounts = current_user.asset_accounts.order(:position, :id)
      @forecast = Forecast.new(accounts: @accounts, entries: current_user.cash_entries.includes(:payment_card), user: current_user)
      @forecast_rows = @forecast.rows
      current = { "total" => @forecast.total.round.to_i, "base_date" => @forecast.base_date&.iso8601 }
      @forecast_rows.each do |row|
        %i[confirmed expected].each { |kind| current["#{row[:days]}_#{kind}"] = row[kind].round.to_i }
      end
      # Keep the last distinct display so refreshing does not erase a change.
      saved = session[:forecast_comparison]
      if saved && saved["user_id"] == current_user.id
        @previous_forecast = saved["current"] == current ? (saved["previous"] || saved["current"]) : saved["current"]
      end
      session[:forecast_comparison] = { "user_id" => current_user.id, "current" => current, "previous" => @previous_forecast }
      @tasks = current_user.money_tasks.where(completed: false).order(Arel.sql("due_on ASC NULLS LAST"), :id).limit(5)
      @snapshots = current_user.asset_snapshots.order(:month).to_a
    end
  end
end
