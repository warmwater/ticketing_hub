class Order < ApplicationRecord
  belongs_to :user
  belongs_to :event
  has_many :order_items, dependent: :destroy
  has_many :tickets, through: :order_items

  enum :status, { pending: 0, confirmed: 1, cancelled: 2 }

  validates :reference_number, presence: true, uniqueness: true

  before_validation :generate_reference_number, on: :create

  accepts_nested_attributes_for :order_items, reject_if: proc { |attrs| attrs["quantity"].to_i <= 0 }

  def calculate_total
    self.total_amount = order_items.sum { |item| item.quantity * item.unit_price }
  end

  def generate_tickets!
    order_items.each do |item|
      item.quantity.times do
        item.tickets.create!(
          barcode: SecureRandom.hex(16).upcase,
          status: :active,
          attendee_name: user.name,
          attendee_email: user.email
        )
      end
    end
  end

  private

  def generate_reference_number
    self.reference_number ||= "ORD-#{SecureRandom.alphanumeric(8).upcase}"
  end
end
