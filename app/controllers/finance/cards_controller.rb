module Finance
  class CardsController < RecordsController
    RESOURCE = :payment_cards
    TITLE = "カード管理"
    FIELDS = [[:name, "カード名", :text], [:closing_day, "締め日（31は月末）", :number], [:payment_month_offset, "支払月（締め月から）", [["当月", 0], ["翌月", 1], ["翌々月", 2]]]].freeze

    def destroy
      if @record.destroy
        redirect_to collection_path, notice: "削除しました。", status: :see_other
      else
        redirect_to collection_path, alert: "利用記録のあるカードは削除できません。", status: :see_other
      end
    end
  end
end
