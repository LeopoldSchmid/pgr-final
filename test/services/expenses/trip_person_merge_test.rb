require "test_helper"

module Expenses
  class TripPersonMergeTest < ActiveSupport::TestCase
    fixtures :users, :trips

    setup do
      @trip = Trip.create!(user: users(:owner), name: "Merge Trip")
      @actor = users(:owner)
      @target = @trip.trip_person_for(users(:owner))
      @source = @trip.trip_people.create!(display_name: "Duplicate", status: "placeholder")
      @expense = @trip.expenses.create!(
        amount: 30,
        description: "Shared",
        category: "food",
        currency: "EUR",
        payer: @actor,
        payer_trip_person: @target
      )
      @expense.expense_splits.create!(trip_person: @target, amount_owed: 10, split_method: "exact")
      @expense.expense_splits.create!(trip_person: @source, amount_owed: 20, split_method: "exact")
    end

    test "merges splits and archives source" do
      TripPersonMerge.new(trip: @trip, source: @source, target: @target, actor: @actor).call

      assert_equal "archived", @source.reload.status
      assert_equal 1, @expense.expense_splits.reload.count
      assert_equal 30.to_d, @expense.expense_splits.first.amount_owed
      assert @trip.expense_events.exists?(event_type: "trip_person_merged")
    end
  end
end
