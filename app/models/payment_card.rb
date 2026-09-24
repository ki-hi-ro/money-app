class PaymentCard < ApplicationRecord
  belongs_to :user
  has_many :cash_entries, dependent: :restrict_with_error
  validates :name, presence: true, uniqueness: { scope: :user_id }
  validates :closing_day, numericality: { only_integer: true, in: 1..31 }
  validates :payment_month_offset, inclusion: { in: 0..2 }

  def period_for(payment_date)
    closing_month = payment_date.beginning_of_month << payment_month_offset
    ending = closing_month.change(day: [closing_day, closing_month.end_of_month.day].min)
    previous = closing_month << 1
    starting = previous.change(day: [closing_day, previous.end_of_month.day].min) + 1
    starting..ending
  end
end
