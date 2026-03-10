class Venue < ApplicationRecord
  belongs_to :created_by, class_name: "User"
  has_many :events, dependent: :restrict_with_error

  validates :name, presence: true
  validates :address, presence: true
  validates :capacity, numericality: { greater_than: 0 }, allow_nil: true

  scope :ordered, -> { order(:name) }
end
