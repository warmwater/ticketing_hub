class TicketType < ApplicationRecord
  belongs_to :event
  belongs_to :section, optional: true
  has_many :order_items, dependent: :restrict_with_error
  has_many :tickets, through: :order_items

  validates :name, presence: true
  validates :price, numericality: { greater_than_or_equal_to: 0 }
  validates :quantity, numericality: { greater_than: 0 }
  validates :max_per_order, numericality: { greater_than: 0 }

  scope :on_sale, -> {
    where("(sale_starts_at IS NULL OR sale_starts_at <= ?) AND (sale_ends_at IS NULL OR sale_ends_at >= ?)",
          Time.current, Time.current)
  }

  def available_quantity
    base = quantity - tickets.where(status: [ :active, :used ]).count

    if section.present?
      if section.general_admission?
        [ base, section.available_capacity_for_event(event) ].min
      elsif section.seated?
        [ base, section.available_seats_for_event(event).count ].min
      else
        base
      end
    else
      base
    end
  end

  def available?
    available_quantity > 0
  end

  def on_sale?
    (sale_starts_at.nil? || sale_starts_at <= Time.current) &&
      (sale_ends_at.nil? || sale_ends_at >= Time.current)
  end
end
