class SplitGroupMembership < ApplicationRecord
  belongs_to :split_group
  belongs_to :trip_person

  validates :trip_person_id, uniqueness: { scope: :split_group_id }
  validate :trip_person_belongs_to_group_trip

  private

  def trip_person_belongs_to_group_trip
    return if split_group.blank? || trip_person.blank?

    if split_group.trip_id != trip_person.trip_id
      errors.add(:trip_person, "must belong to the split group trip")
    end
  end
end
