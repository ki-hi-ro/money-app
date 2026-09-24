class User < ApplicationRecord
  has_many :asset_accounts, dependent: :destroy
  has_many :cash_entries, dependent: :destroy
  has_many :money_tasks, dependent: :destroy
  has_many :asset_snapshots, dependent: :destroy

  has_many :payment_cards, dependent: :destroy
  has_many :posts, dependent: :destroy
  has_many :dialies, dependent: :destroy
  validates :monthly_card_budget, numericality: { greater_than_or_equal_to: 0, less_than_or_equal_to: 1_000_000_000 }
  validates :monthly_living_budget, numericality: { only_integer: true, greater_than_or_equal_to: 0, less_than_or_equal_to: 1_000_000_000 }, allow_nil: true

  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable, :confirmable, :lockable, :timeoutable
end
