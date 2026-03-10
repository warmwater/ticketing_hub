class User < ApplicationRecord
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable

  enum :role, { attendant: 0, organizer: 1, admin: 2 }

  has_many :organized_events, class_name: "Event", foreign_key: :organizer_id, dependent: :destroy
  has_many :orders, dependent: :destroy
  has_many :tickets, through: :orders
  has_many :waiting_room_entries, dependent: :destroy
  has_many :created_venues, class_name: "Venue", foreign_key: :created_by_id, dependent: :nullify

  validates :name, presence: true
  validates :role, presence: true

  def admin?
    role == "admin"
  end

  def organizer?
    role == "organizer"
  end

  def attendant?
    role == "attendant"
  end
end
