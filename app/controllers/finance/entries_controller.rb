module Finance
  class EntriesController < RecordsController
    RESOURCE = :cash_entries
    TITLE = "入出金"
    FIELDS = [[:date, "日付", :date], [:kind, "区分", CashEntry::KINDS], [:amount, "金額（円）", :number], [:category, "カテゴリ", :text], [:description, "内容", :text], [:payment_type, "支払い区分", [["現金・振込など", "other"], ["クレジットカード", "card"]]], [:payment_card_id, "カード", :card], [:payment_method, "支払い元の補足", :text], [:status, "状態", CashEntry::STATUSES], [:notes, "備考", :textarea], [:card_confirmed_amount, "カード確認額（照合する場合のみ）", :number], [:statement_start_on, "カード明細の開始日（任意）", :date], [:statement_end_on, "カード明細の終了日（任意）", :date]].freeze

    private

    def configure
      super
      @fields = @fields.map { |key, label, type| [key, label, type == :card ? [["選択なし", ""]] + current_user.payment_cards.order(:name).pluck(:name, :id) : type] }
    end

    public

    def new
      @record = collection.new(kind: params[:kind] == "収入" ? "収入" : "支出", status: "完了", date: Date.current)
      render "finance/records/form"
    end

    def index
      @ledger = Ledger.new(collection.includes(:payment_card))
      @date_order = params[:date_order] == "asc" ? "asc" : "desc"
      ordering = @date_order == "asc" ? "date ASC NULLS LAST, id ASC" : "date DESC NULLS LAST, id DESC"
      scope = collection.order(Arel.sql(ordering))
      scope = scope.where(kind: params[:kind]) if CashEntry::KINDS.include?(params[:kind])
      scope = scope.where(status: params[:status]) if CashEntry::STATUSES.include?(params[:status])
      if params[:month].present?
        begin
          month = Date.strptime(params[:month], "%Y-%m")
          scope = scope.where(date: month.beginning_of_month..month.end_of_month)
        rescue Date::Error
          flash.now[:alert] = "年月は YYYY-MM で指定してください。"
        end
      end
      @page = [params[:page].to_i, 1].max
      @count = scope.count
      @records = scope.offset((@page - 1) * 50).limit(50)
      render "finance/entries/index"
    end
  end
end
