require "test_helper"

class Api::RetroactiveExpenseInclusionsControllerTest < ActionDispatch::IntegrationTest
  fixtures :users, :trips

  setup do
    @user = users(:owner)
    @trip = Trip.create!(user: @user, name: "Retro API Trip")
    @owner = @trip.trip_person_for(@user)
    @member = @trip.trip_person_for(users(:member))
    @late = @trip.trip_people.create!(display_name: "Late", status: "placeholder")
    @expense = @trip.expenses.create!(
      amount: 90,
      description: "Dinner",
      category: "food",
      currency: "EUR",
      payer: @user,
      payer_trip_person: @owner
    )
    @expense.apply_split!(Expenses::SplitCalculator.equal(amount: 90, trip_people: [ @owner, @member ]))
    post session_url, params: { email_address: @user.email_address, password: "password" }
  end

  test "previews retroactive include" do
    post preview_api_trip_retroactive_expense_inclusion_url(@trip), params: {
      retroactive_expense_inclusion: {
        trip_person_id: @late.id,
        expense_ids: [ @expense.id ]
      }
    }

    assert_response :success
    body = JSON.parse(response.body)
    assert_equal 1, body.fetch("changes").length
    assert_equal 2, body.fetch("changes").first.fetch("before").length
    assert_equal 3, body.fetch("changes").first.fetch("after").length
  end

  test "applies retroactive include" do
    post apply_api_trip_retroactive_expense_inclusion_url(@trip), params: {
      retroactive_expense_inclusion: {
        trip_person_id: @late.id,
        expense_ids: [ @expense.id ]
      }
    }

    assert_response :success
    assert_equal 3, @expense.expense_splits.reload.count
  end
end
