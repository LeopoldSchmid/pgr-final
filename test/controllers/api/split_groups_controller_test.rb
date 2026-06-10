require "test_helper"

class Api::SplitGroupsControllerTest < ActionDispatch::IntegrationTest
  fixtures :users, :trips

  setup do
    @user = users(:owner)
    @trip = Trip.create!(user: @user, name: "Groups API Trip")
    @owner = @trip.trip_person_for(@user)
    @member = @trip.trip_person_for(users(:member))
    post session_url, params: { email_address: @user.email_address, password: "password" }
  end

  test "creates custom split group with members" do
    assert_difference("SplitGroup.count", 1) do
      post api_trip_split_groups_url(@trip), params: {
        split_group: {
          name: "Drivers",
          kind: "custom",
          trip_person_ids: [ @owner.id, @member.id ]
        }
      }
    end

    assert_response :created
    body = JSON.parse(response.body)
    assert_equal "Drivers", body.fetch("name")
    assert_equal [ @owner.id, @member.id ].sort, body.fetch("trip_person_ids").sort
  end

  test "updates split group members" do
    group = @trip.split_groups.create!(name: "Dinner")
    group.trip_people = [ @owner ]

    patch api_trip_split_group_url(@trip, group), params: {
      split_group: { trip_person_ids: [ @member.id ] }
    }

    assert_response :success
    assert_equal [ @member.id ], group.reload.trip_people.pluck(:id)
  end
end
