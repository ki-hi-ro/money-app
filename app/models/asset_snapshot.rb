class AssetSnapshot < ApplicationRecord
  belongs_to :user
  before_validation { self.month = month.beginning_of_month if month }
  validates :month, presence: true, uniqueness: { scope: :user_id }
  validate :valid_balances

  def total
    balances.values.compact.sum
  end

  private

  def valid_balances
    unless balances.is_a?(Hash) && balances.present? && balances.all? { |name, value| name.present? && (value.nil? || value.is_a?(Integer)) }
      errors.add(:balances, "には資産名と整数の残高を入力してください")
    end
  end
end
