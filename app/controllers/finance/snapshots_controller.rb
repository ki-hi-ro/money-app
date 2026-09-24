module Finance
  class SnapshotsController < RecordsController
    RESOURCE = :asset_snapshots
    TITLE = "月次資産推移"
    FIELDS = [[:month, "年月", :month]].freeze

    def index
      @records = collection.order(:month).to_a
      @names = (current_user.asset_accounts.order(:position, :id).pluck(:name) + @records.flat_map { |r| r.balances.keys }).uniq
      render "finance/snapshots/index"
    end

    def new
      @record = collection.new(month: Date.current.beginning_of_month, balances: current_user.asset_accounts.order(:position, :id).pluck(:name, :balance).to_h)
      render "finance/snapshots/form"
    end

    def edit
      render "finance/snapshots/form"
    end

    private

    def record_params
      input = params.require(:asset_snapshot)
      month = input[:month].present? ? "#{input[:month]}-01" : nil
      balances = input.permit(balances: {}).fetch(:balances, {}).to_h.transform_values do |value|
        value.blank? ? nil : (Integer(value, 10) rescue value)
      end
      { month: month, balances: balances }
    end

    def save_record
      if @record.save
        redirect_to collection_path, notice: "月次残高を保存しました。", status: :see_other
      else
        render "finance/snapshots/form", status: :unprocessable_content
      end
    end
  end
end
