require "test_helper"

class Api::ExpenseSnapshotsControllerTest < ActionDispatch::IntegrationTest
  fixtures :users, :trips

  setup do
    @user = users(:owner)
    @trip = Trip.create!(
      user: @user,
      name: "Snapshot Trip",
      start_date: Date.current,
      end_date: Date.current + 1.day
    )
    @payer = @trip.trip_person_for(@user)
    @member = @trip.trip_person_for(users(:member))
    @expense = @trip.expenses.create!(
      amount: 20,
      description: "Coffee",
      category: "food",
      currency: "EUR",
      payer: @user,
      payer_trip_person: @payer
    )
    @expense.apply_split!(Expenses::SplitCalculator.equal(amount: 20, trip_people: [ @payer, @member ]))

    post session_url, params: { email_address: @user.email_address, password: "password" }
  end

  test "shows expense snapshot for accessible trip" do
    get api_trip_expense_snapshot_url(@trip)

    assert_response :success
    body = JSON.parse(response.body)

    assert_equal @trip.id, body.dig("trip", "id")
    assert_equal 2, body.fetch("trip_people").length
    assert_equal 1, body.fetch("expenses").length
    assert_equal @expense.id, body.fetch("expenses").first.fetch("id")
    assert_equal "10.0", body.fetch("balances").find { |balance| balance["trip_person_id"] == @member.id }.fetch("amount").delete_prefix("-")
    assert_not_empty body.fetch("settlement_suggestions")
  end

  test "does not expose inaccessible trip" do
    other_user = User.create!(email_address: "outsider@example.com", password: "password")
    post session_url, params: { email_address: other_user.email_address, password: "password" }

    get api_trip_expense_snapshot_url(@trip)

    assert_response :not_found
  end
end
