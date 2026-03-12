class Venue < ApplicationRecord
  belongs_to :created_by, class_name: "User"
  has_many :events, dependent: :restrict_with_error
  has_many :sections, dependent: :destroy
  has_many :seats, through: :sections

  validates :name, presence: true
  validates :address, presence: true
  validates :capacity, numericality: { greater_than: 0 }, allow_nil: true

  scope :ordered, -> { order(:name) }

  def has_seating?
    sections.any?
  end
end
