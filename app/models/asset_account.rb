class AssetAccount < ApplicationRecord
  belongs_to :user
  validates :name, :balance_on, presence: true
  validates :name, uniqueness: { scope: :user_id }
  validates :balance, numericality: { only_integer: true }
  validates :unit, inclusion: { in: %w[円 pt] }
end
