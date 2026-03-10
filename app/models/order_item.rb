class OrderItem < ApplicationRecord
  belongs_to :order
  belongs_to :ticket_type
  has_many :tickets, dependent: :destroy

  validates :quantity, numericality: { greater_than: 0 }
  validates :unit_price, numericality: { greater_than_or_equal_to: 0 }

  before_validation :set_unit_price, on: :create

  def total_price
    quantity * unit_price
  end

  private

  def set_unit_price
    self.unit_price ||= ticket_type&.price || 0
  end
end
