require "test_helper"

module Expenses
  class LedgerTest < ActiveSupport::TestCase
    fixtures :users, :trips

    setup do
      @trip = Trip.create!(
        user: users(:owner),
        name: "Ledger Trip",
        start_date: Date.current,
        end_date: Date.current + 2.days
      )
      @owner = @trip.trip_person_for(users(:owner))
      @member = @trip.trip_person_for(users(:member))
      @placeholder = @trip.trip_people.create!(display_name: "Pending Pat", status: "placeholder")
    end

    test "balances and settlements use trip people including placeholders" do
      expense = @trip.expenses.create!(
        amount: 90,
        description: "Dinner",
        category: "food",
        currency: "EUR",
        payer: users(:owner),
        payer_trip_person: @owner
      )
      expense.apply_split!(SplitCalculator.equal(amount: 90, trip_people: [ @owner, @member, @placeholder ]))

      ledger = Ledger.new(@trip)

      assert_equal 60.to_d, ledger.balance_for(@owner)
      assert_equal(-30.to_d, ledger.balance_for(@member))
      assert_equal(-30.to_d, ledger.balance_for(@placeholder))

      suggestions = ledger.settlement_suggestions
      assert_equal 2, suggestions.length
      assert_equal @member, suggestions.first[:from]
      assert_equal @owner, suggestions.first[:to]
      assert_equal 30.to_d, suggestions.first[:amount]
    end

    test "draft and needs_split expenses are excluded from totals and settlement" do
      @trip.expenses.create!(
        amount: 120,
        description: "Unfinished",
        category: "food",
        currency: "EUR",
        payer: users(:owner),
        payer_trip_person: @owner,
        status: "needs_split"
      )

      ledger = Ledger.new(@trip)

      assert_equal 0.to_d, ledger.total_expenses
      assert_empty ledger.settlement_suggestions
    end
  end
end
