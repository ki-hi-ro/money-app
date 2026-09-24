module FinanceHelper
  def money(value)
    value.nil? ? "—" : number_to_currency(value, unit: "円", format: "%n%u", negative_format: "−%n%u", precision: 0)
  end

  def finance_field_value(record, key, type)
    value = record.public_send(key)
    return value ? "完了" : "未完了" if type == :checkbox
    return value&.strftime("%H:%M") || "—" if type == :time
    return number_with_delimiter(value) if type == :number
    if type.is_a?(Array)
      selected = type.find { |option| (option.is_a?(Array) ? option.last : option).to_s == value.to_s }
      return (selected.is_a?(Array) ? selected.first : selected).presence || "—"
    end
    value.presence || "—"
  end

  def day_label(date)
    date ? "#{date.strftime('%Y/%m/%d')}（#{%w[日 月 火 水 木 金 土][date.wday]}）" : "日付未定"
  end
end
