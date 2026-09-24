module Finance
  class TasksController < RecordsController
    RESOURCE = :money_tasks
    TITLE = "やること"
    FIELDS = [[:title, "項目", :text], [:due_on, "期限", :date], [:due_time, "時間", :time], [:completed, "完了", :checkbox]].freeze
  end
end
