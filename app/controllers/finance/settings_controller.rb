module Finance
  class SettingsController < BaseController
    def edit
      @user = current_user
    end

    def update
      @user = current_user
      if @user.update(params.require(:user).permit(:monthly_card_budget, :monthly_living_budget))
        redirect_to finance_root_path, notice: "予測設定を保存しました。", status: :see_other
      else
        render :edit, status: :unprocessable_content
      end
    end
  end
end
