require "test_helper"

class SplitGroupTest < ActiveSupport::TestCase
  fixtures :users, :trips

  setup do
    @trip = trips(:planning)
    @owner_person = @trip.trip_person_for(users(:owner))
    @member_person = @trip.trip_person_for(users(:member))
  end

  test "everyone group is dynamic over active ledger people" do
    group = SplitGroup.everyone_for!(@trip)

    assert_equal "everyone", group.kind
    assert_includes group.dynamic_trip_people, @owner_person
    assert_includes group.dynamic_trip_people, @member_person
  end

  test "custom group memberships must belong to same trip" do
    group = @trip.split_groups.create!(name: "Drivers")
    other_person = trips(:active).trip_person_for(users(:owner))

    membership = group.split_group_memberships.build(trip_person: other_person)

    assert_not membership.valid?
    assert_includes membership.errors[:trip_person], "must belong to the split group trip"
  end
end
