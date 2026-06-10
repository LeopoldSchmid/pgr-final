require "test_helper"

class ExpenseSplitTest < ActiveSupport::TestCase
  fixtures :users, :trips

  setup do
    @trip = trips(:planning)
    @payer = @trip.trip_person_for(users(:owner))
    @member = @trip.trip_person_for(users(:member))
    @expense = @trip.expenses.create!(
      amount: 10.00,
      description: "Dinner",
      category: "food",
      currency: "EUR",
      payer: users(:owner),
      payer_trip_person: @payer
    )
  end

  test "validates trip person belongs to expense trip" do
    other_trip = trips(:active)
    other_person = other_trip.trip_person_for(users(:owner))

    split = @expense.expense_splits.build(
      trip_person: other_person,
      amount_owed: 10,
      split_method: "exact"
    )

    assert_not split.valid?
    assert_includes split.errors[:trip_person], "must belong to the expense trip"
  end

  test "requires supported split method" do
    split = @expense.expense_splits.build(
      trip_person: @member,
      amount_owed: 10,
      split_method: "made_up"
    )

    assert_not split.valid?
    assert_includes split.errors[:split_method], "is not included in the list"
  end
end
