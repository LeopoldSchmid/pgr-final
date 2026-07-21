require "test_helper"

class Api::ExpenseClientMutationsControllerTest < ActionDispatch::IntegrationTest
  fixtures :users, :trips

  setup do
    @user = users(:owner)
    @trip = Trip.create!(
      user: @user,
      name: "Mutation API Trip",
      start_date: Date.current,
      end_date: Date.current + 1.day
    )
    @payer = @trip.trip_person_for(@user)
    @member = @trip.trip_person_for(users(:member))

    post session_url, params: { email_address: @user.email_address, password: "password" }
  end

  test "creates expense through client mutation API" do
    assert_difference("Expense.count", 1) do
      post api_trip_expense_client_mutations_url(@trip), params: {
        client_mutation: {
          client_uuid: "mutation-api-1",
          mutation_type: "expense_create",
          payload: create_payload
        }
      }
    end

    assert_response :success
    body = JSON.parse(response.body)
    assert_equal "accepted", body.fetch("status")
    assert_equal "Expense", body.dig("record", "type")
  end

  test "duplicate retry does not create another expense" do
    params = {
      client_mutation: {
        client_uuid: "mutation-api-1",
        mutation_type: "expense_create",
        payload: create_payload
      }
    }

    post api_trip_expense_client_mutations_url(@trip), params: params

    assert_no_difference("Expense.count") do
      post api_trip_expense_client_mutations_url(@trip), params: params
    end

    assert_response :success
    assert_equal "duplicate", JSON.parse(response.body).fetch("status")
  end

  test "stale edit returns conflict" do
    expense = @trip.expenses.create!(
      amount: 10,
      description: "Server value",
      category: "food",
      currency: "EUR",
      payer: @user,
      payer_trip_person: @payer
    )
    stale_revision = expense.lock_version
    expense.update!(description: "Changed already")

    post api_trip_expense_client_mutations_url(@trip), params: {
      client_mutation: {
        client_uuid: "mutation-api-2",
        mutation_type: "expense_update",
        payload: {
          expense_id: expense.id,
          base_revision: stale_revision,
          expense: { description: "Offline value" }
        }
      }
    }

    assert_response :conflict
    body = JSON.parse(response.body)
    assert_equal "conflict", body.fetch("status")
    assert body.fetch("conflict")
  end

  test "stale edit logs sync issue for developers" do
    expense = @trip.expenses.create!(
      amount: 10,
      description: "Server value",
      category: "food",
      currency: "EUR",
      payer: @user,
      payer_trip_person: @payer
    )
    stale_revision = expense.lock_version
    expense.update!(description: "Changed already")

    logs = capture_rails_logs do
      post api_trip_expense_client_mutations_url(@trip), params: {
        client_mutation: {
          client_uuid: "mutation-api-log-conflict",
          mutation_type: "expense_update",
          payload: {
            expense_id: expense.id,
            base_revision: stale_revision,
            expense: { description: "Offline value" }
          }
        }
      }
    end

    assert_response :conflict
    assert_includes logs, "expense_client_mutation_sync_issue"
    assert_includes logs, "client_uuid=mutation-api-log-conflict"
    assert_includes logs, "status=conflict"
  end

  test "rejected mutation logs sync issue for developers" do
    logs = capture_rails_logs do
      post api_trip_expense_client_mutations_url(@trip), params: {
        client_mutation: {
          client_uuid: "mutation-api-log-rejected",
          mutation_type: "expense_update",
          payload: { base_revision: 0, expense: { description: "Missing expense id" } }
        }
      }
    end

    assert_response :unprocessable_entity
    body = JSON.parse(response.body)
    assert_equal "rejected", body.fetch("status")
    assert_includes logs, "expense_client_mutation_sync_issue"
    assert_includes logs, "client_uuid=mutation-api-log-rejected"
    assert_includes logs, "status=rejected"
  end

  test "does not allow non-member mutation" do
    other_user = User.create!(email_address: "mutation-outsider@example.com", password: "password")
    post session_url, params: { email_address: other_user.email_address, password: "password" }

    assert_no_difference("Expense.count") do
      post api_trip_expense_client_mutations_url(@trip), params: {
        client_mutation: {
          client_uuid: "mutation-api-outsider",
          mutation_type: "expense_create",
          payload: create_payload
        }
      }
    end

    assert_response :not_found
  end

  private

  def create_payload
    {
      expense: {
        client_uuid: "expense-api-1",
        amount: "50.00",
        description: "API dinner",
        category: "food",
        currency: "EUR",
        expense_date: Date.current.to_s,
        payer_trip_person_id: @payer.id
      },
      splits: [
        { trip_person_id: @payer.id, amount_owed: "25.00", split_method: "exact", split_value: "25.00" },
        { trip_person_id: @member.id, amount_owed: "25.00", split_method: "exact", split_value: "25.00" }
      ]
    }
  end

  def capture_rails_logs
    output = StringIO.new
    previous_logger = Rails.logger
    Rails.logger = ActiveSupport::Logger.new(output)
    yield
    output.string
  ensure
    Rails.logger = previous_logger
  end
end
