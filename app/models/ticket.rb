class Ticket < ApplicationRecord
  belongs_to :order_item
  has_one :ticket_type, through: :order_item
  has_one :order, through: :order_item
  has_one :event, through: :ticket_type

  enum :status, { pending: 0, active: 1, used: 2, cancelled: 3 }

  validates :barcode, presence: true, uniqueness: true

  before_validation :generate_barcode, on: :create

  scope :valid_tickets, -> { where(status: [:active]) }

  private

  def generate_barcode
    self.barcode ||= SecureRandom.hex(16).upcase
  end
end
