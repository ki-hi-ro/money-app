module Finance
  class RecordsController < BaseController
    before_action :configure
    before_action :set_record, only: [:edit, :update, :destroy]

    def index
      @records = collection.order(:id).to_a
      render "finance/records/index"
    end

    def new
      @record = collection.new
      render "finance/records/form"
    end

    def edit
      render "finance/records/form"
    end

    def create
      @record = collection.new(record_params)
      save_record
    end

    def update
      @record.assign_attributes(record_params)
      save_record
    end

    def destroy
      @record.destroy!
      redirect_to collection_path, notice: "削除しました。", status: :see_other
    end

    private

    def configure
      @resource = self.class::RESOURCE
      @title = self.class::TITLE
      @fields = self.class::FIELDS
    end

    def collection
      current_user.public_send(@resource)
    end

    def collection_path
      public_send("finance_#{controller_name}_path")
    end
    helper_method :collection_path

    def set_record
      @record = collection.find(params[:id])
    end

    def record_params
      params.require(collection.klass.model_name.param_key).permit(*@fields.map(&:first))
    end

    def save_record
      if @record.save
        redirect_to collection_path, notice: "保存しました。", status: :see_other
      else
        render "finance/records/form", status: :unprocessable_content
      end
    end
  end
end
