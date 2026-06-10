require "test_helper"

module Expenses
  class RetroactiveIncludeTest < ActiveSupport::TestCase
    fixtures :users, :trips

    setup do
      @trip = Trip.create!(user: users(:owner), name: "Retro Trip")
      @actor = users(:owner)
      @owner = @trip.trip_person_for(users(:owner))
      @member = @trip.trip_person_for(users(:member))
      @late = @trip.trip_people.create!(display_name: "Late", status: "placeholder")
      @expense = @trip.expenses.create!(
        amount: 90,
        description: "Dinner",
        category: "food",
        currency: "EUR",
        payer: @actor,
        payer_trip_person: @owner
      )
      @expense.apply_split!(SplitCalculator.equal(amount: 90, trip_people: [ @owner, @member ]))
    end

    test "preview shows balance impact without changing splits" do
      result = RetroactiveInclude.new(
        trip: @trip,
        trip_person: @late,
        expense_ids: [ @expense.id ],
        actor: @actor
      ).preview

      assert_equal 1, result[:changes].length
      assert_equal 2, result[:changes].first[:before].length
      assert_equal 3, result[:changes].first[:after].length
      assert_equal 2, @expense.expense_splits.reload.count
      assert_equal(-30.to_d, result[:after_balances][@late])
    end

    test "apply re-splits selected expense and records event" do
      RetroactiveInclude.new(
        trip: @trip,
        trip_person: @late,
        expense_ids: [ @expense.id ],
        actor: @actor
      ).apply

      assert_equal 3, @expense.expense_splits.reload.count
      assert_equal [ 30.to_d, 30.to_d, 30.to_d ], @expense.expense_splits.order(:trip_person_id).map(&:amount_owed)
      assert @trip.expense_events.exists?(event_type: "retroactive_include_applied", expense: @expense)
    end
  end
end
