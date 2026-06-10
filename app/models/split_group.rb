class SplitGroup < ApplicationRecord
  KINDS = %w[everyone custom].freeze

  belongs_to :trip
  has_many :split_group_memberships, dependent: :destroy
  has_many :trip_people, through: :split_group_memberships

  validates :name, presence: true, length: { maximum: 100 }, uniqueness: { scope: :trip_id }
  validates :kind, inclusion: { in: KINDS }

  def self.everyone_for!(trip)
    find_or_create_by!(trip: trip, kind: "everyone", name: "Everyone")
  end

  def dynamic_trip_people
    return trip.trip_people.active_ledger_people if kind == "everyone"

    trip_people
  end
end
