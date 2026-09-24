class CashEntry < ApplicationRecord
  KINDS = %w[収入 支出 口座引き落とし 振替].freeze
  STATUSES = %w[完了 確定 未確定].freeze

  belongs_to :user
  belongs_to :payment_card, optional: true
  validates :kind, inclusion: { in: KINDS }
  validates :status, inclusion: { in: STATUSES }
  validates :payment_type, inclusion: { in: %w[other card] }
  validates :description, presence: true
  validates :date, :amount, presence: true, unless: -> { status == "未確定" }
  validates :amount, :card_confirmed_amount, numericality: { only_integer: true, greater_than_or_equal_to: 0 }, allow_nil: true
  validate :owned_payment_card
  validate :statement_period
  validate :reconciliation_requires_card_debit

  def card_payment?
    payment_type == "card"
  end

  def card_debit?
    kind == "口座引き落とし" && card_payment?
  end

  private

  def owned_payment_card
    errors.add(:payment_card, "を自分のカードから選択してください") if card_payment? && (payment_card.nil? || payment_card.user_id != user_id)
    errors.add(:payment_card, "はカード払いの場合だけ指定できます") if !card_payment? && payment_card_id.present?
  end

  def statement_period
    if statement_start_on.nil? && statement_end_on.nil?
      if card_debit? && payment_card && date && payment_card.period_for(date).end > date
        errors.add(:payment_card, "の締め日が支払日より後です。支払月か明細期間を確認してください")
      end
      return
    end
    unless card_debit? && statement_start_on && statement_end_on && statement_start_on <= statement_end_on && date && statement_end_on <= date
      errors.add(:statement_start_on, "と終了日は、カード引き落としの支払日以前の正しい期間を指定してください")
    end
  end

  def reconciliation_requires_card_debit
    return if card_confirmed_amount.nil?
    errors.add(:card_confirmed_amount, "は日付のあるクレジットカード引き落としだけに指定できます") unless card_debit? && date
  end
end
