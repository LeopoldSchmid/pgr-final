require "test_helper"

class TripContextTest < ActiveSupport::TestCase
  fixtures :users, :trips

  class TestController < ApplicationController
    attr_accessor :session

    def initialize
      super
      @session = {}
    end
  end

  def setup
    @user = users(:owner)
    @member = users(:member)
    @other_user = users(:other_user)
    @trip = trips(:planning)
    @active_trip = trips(:active)
    @controller = TestController.new
  end

  test "set_current_trip stores trip id in session" do
    @controller.send(:set_current_trip, @trip)
    assert_equal @trip.id, @controller.session[:current_trip_id]
  end

  test "set_current_trip handles nil trip" do
    @controller.send(:set_current_trip, nil)
    assert_nil @controller.session[:current_trip_id]
  end

  test "current_trip retrieves trip from session with valid owner access" do
    @controller.session[:current_trip_id] = @trip.id
    sign_in_as(@user)

    trip = @controller.send(:current_trip)

    assert_equal @trip.id, trip.id
    assert_equal @trip.name, trip.name
  end

  test "current_trip returns nil when no trip in session" do
    sign_in_as(@user)

    trip = @controller.send(:current_trip)

    assert_nil trip
  end

  test "current_trip returns nil when user doesn't have access to trip" do
    @controller.session[:current_trip_id] = @trip.id
    sign_in_as(@other_user)

    trip = @controller.send(:current_trip)

    assert_nil trip
    # Session should be cleared
    assert_nil @controller.session[:current_trip_id]
  end

  test "current_trip works for trip member" do
    # Create a trip member relationship
    TripMember.create!(trip: @trip, user: @member, role: "member")

    @controller.session[:current_trip_id] = @trip.id
    sign_in_as(@member)

    trip = @controller.send(:current_trip)

    assert_equal @trip.id, trip.id
  end

  test "current_trip_or_next returns current trip when set" do
    @controller.session[:current_trip_id] = @trip.id
    sign_in_as(@user)

    trip = @controller.send(:current_trip_or_next)

    assert_equal @trip.id, trip.id
  end

  test "current_trip_or_next returns active trip when no current trip" do
    sign_in_as(@user)

    trip = @controller.send(:current_trip_or_next)

    # Should return the active trip
    assert_equal @active_trip.id, trip.id
  end

  test "current_trip_or_next returns next scheduled trip when no active trip" do
    # Make active trip completed by setting end date in the past
    @active_trip.update!(start_date: 1.month.ago, end_date: 3.weeks.ago)

    sign_in_as(@user)

    trip = @controller.send(:current_trip_or_next)

    # Should return the planning trip (future trip)
    assert_equal @trip.id, trip.id
  end

  test "current_trip_or_next returns nil when user has no trips" do
    sign_in_as(@other_user)

    trip = @controller.send(:current_trip_or_next)

    assert_nil trip
  end

  test "clear_trip_context removes trip from session" do
    @controller.session[:current_trip_id] = @trip.id

    @controller.send(:clear_trip_context)

    assert_nil @controller.session[:current_trip_id]
  end

  test "clear_trip_context clears memoized current_trip" do
    @controller.session[:current_trip_id] = @trip.id
    sign_in_as(@user)

    # Load the trip
    @controller.send(:current_trip)

    # Clear context
    @controller.send(:clear_trip_context)

    # Verify memoized variable is cleared
    assert_nil @controller.instance_variable_get(:@current_trip)
  end
end
