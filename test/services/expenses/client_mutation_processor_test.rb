require "test_helper"

module Expenses
  class ClientMutationProcessorTest < ActiveSupport::TestCase
    fixtures :users, :trips

    setup do
      @trip = Trip.create!(
        user: users(:owner),
        name: "Sync Trip",
        start_date: Date.current,
        end_date: Date.current + 1.day
      )
      @actor = users(:owner)
      @payer = @trip.trip_person_for(@actor)
      @member = @trip.trip_person_for(users(:member))
    end

    test "creates expense mutation idempotently" do
      payload = create_payload(client_uuid: "expense-local-1")

      result = process("mutation-1", "expense_create", payload)
      duplicate = process("mutation-1", "expense_create", payload)

      assert_equal "accepted", result.status
      assert_equal "duplicate", duplicate.status
      assert_equal result.record, duplicate.record
      assert_equal 1, @trip.expenses.where(client_uuid: "expense-local-1").count
      assert_equal 2, result.record.expense_splits.count
      assert @trip.expense_events.exists?(event_type: "expense_created", expense: result.record)
      assert @trip.expense_events.exists?(event_type: "mutation_synced", expense: result.record)
    end

    test "rejects reused client uuid with different payload" do
      process("mutation-1", "expense_create", create_payload(client_uuid: "expense-local-1"))

      result = process("mutation-1", "expense_create", create_payload(client_uuid: "expense-local-2"))

      assert_equal "rejected", result.status
      assert_equal "client_uuid already used with different payload", result.error["message"]
    end

    test "updates expense when base revision matches" do
      expense = process("mutation-1", "expense_create", create_payload(client_uuid: "expense-local-1")).record
      base_revision = expense.lock_version

      result = process("mutation-2", "expense_update", {
        expense_id: expense.id,
        base_revision: base_revision,
        expense: {
          description: "Updated dinner",
          amount: "80.00",
          category: "food",
          currency: "EUR",
          expense_date: Date.current.to_s
        },
        splits: [
          { trip_person_id: @payer.id, amount_owed: "40.00", split_method: "exact", split_value: "40.00" },
          { trip_person_id: @member.id, amount_owed: "40.00", split_method: "exact", split_value: "40.00" }
        ]
      })

      assert_equal "accepted", result.status
      assert_equal "Updated dinner", expense.reload.description
      assert_operator expense.lock_version, :>, base_revision
      assert @trip.expense_events.exists?(event_type: "expense_edited", expense: expense)
    end

    test "returns conflict when update base revision is stale" do
      expense = process("mutation-1", "expense_create", create_payload(client_uuid: "expense-local-1")).record
      stale_revision = expense.lock_version
      expense.update!(description: "Server edit")

      result = process("mutation-2", "expense_update", {
        expense_id: expense.id,
        base_revision: stale_revision,
        expense: { description: "Offline edit" }
      })

      assert_equal "conflict", result.status
      assert result.conflict
      assert_equal expense.reload.lock_version, result.error["server_revision"]
      assert_equal "Server edit", expense.description
    end

    test "voids expense when base revision matches" do
      expense = process("mutation-1", "expense_create", create_payload(client_uuid: "expense-local-1")).record

      result = process("mutation-2", "expense_void", {
        expense_id: expense.id,
        base_revision: expense.lock_version
      })

      assert_equal "accepted", result.status
      assert_equal "voided", expense.reload.status
      assert @trip.expense_events.exists?(event_type: "expense_voided", expense: expense)
    end

    private

    def process(client_uuid, mutation_type, payload)
      ClientMutationProcessor.new(
        trip: @trip,
        actor: @actor,
        client_uuid: client_uuid,
        mutation_type: mutation_type,
        payload: payload
      ).call
    end

    def create_payload(client_uuid:)
      {
        expense: {
          client_uuid: client_uuid,
          amount: "60.00",
          description: "Dinner",
          category: "food",
          currency: "EUR",
          expense_date: Date.current.to_s,
          payer_trip_person_id: @payer.id
        },
        splits: [
          { trip_person_id: @payer.id, amount_owed: "30.00", split_method: "exact", split_value: "30.00" },
          { trip_person_id: @member.id, amount_owed: "30.00", split_method: "exact", split_value: "30.00" }
        ]
      }
    end
  end
end
