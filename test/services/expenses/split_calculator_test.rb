require "test_helper"

module Expenses
  class SplitCalculatorTest < ActiveSupport::TestCase
    fixtures :users, :trips

    setup do
      @trip = trips(:planning)
      @owner = @trip.trip_person_for(users(:owner))
      @member = @trip.trip_person_for(users(:member))
      @guest = @trip.trip_people.create!(display_name: "Guest", status: "placeholder")
    end

    test "equal split distributes rounding remainder deterministically" do
      splits = SplitCalculator.equal(amount: 10.01, trip_people: [ @owner, @member ])

      assert_equal [ 5.01.to_d, 5.00.to_d ], splits.map(&:amount_owed)
      assert_equal 10.01.to_d, splits.sum(&:amount_owed)
      assert_equal %w[equal equal], splits.map(&:split_method)
    end

    test "exact split must equal expense amount" do
      error = assert_raises(SplitCalculator::InvalidSplit) do
        SplitCalculator.exact(amount: 10, allocations: { @owner => 6, @member => 3 })
      end

      assert_equal "exact split amounts must equal the expense amount", error.message
    end

    test "shares split supports weighted participants" do
      splits = SplitCalculator.shares(amount: 100, weights: { @owner => 1, @member => 1, @guest => 0.5 })

      assert_equal 100.to_d, splits.sum(&:amount_owed)
      assert_equal [ 40.to_d, 40.to_d, 20.to_d ], splits.map(&:amount_owed)
      assert_equal [ 1.to_d, 1.to_d, 0.5.to_d ], splits.map(&:split_value)
    end

    test "percentage split requires 100 percent" do
      splits = SplitCalculator.percentages(amount: 99.99, percentages: { @owner => 33.33, @member => 66.67 })

      assert_equal 99.99.to_d, splits.sum(&:amount_owed)
      assert_equal [ 33.33.to_d, 66.66.to_d ], splits.map(&:amount_owed)
    end
  end
end
