require "digest"

module Expenses
  class ClientMutationProcessor
    Result = Data.define(:status, :mutation, :record, :error, :conflict)

    def self.payload_hash(payload)
      Digest::SHA256.hexdigest(JSON.generate(deep_sort(payload.deep_stringify_keys)))
    end

    def self.deep_sort(value)
      case value
      when Hash
        value.keys.sort.to_h { |key| [ key, deep_sort(value[key]) ] }
      when Array
        value.map { |entry| deep_sort(entry) }
      else
        value
      end
    end

    def initialize(trip:, actor:, client_uuid:, mutation_type:, payload:, payload_hash: nil)
      @trip = trip
      @actor = actor
      @client_uuid = client_uuid
      @mutation_type = mutation_type
      @payload = payload.deep_stringify_keys
      @payload_hash = payload_hash.presence || self.class.payload_hash(@payload)
    end

    def call
      existing = @trip.client_mutations.find_by(client_uuid: @client_uuid)
      return existing_result(existing) if existing

      ActiveRecord::Base.transaction do
        record = nil
        status = "accepted"
        error_details = nil

        begin
          record = process_mutation!
        rescue StaleRevision => error
          status = "conflict"
          error_details = error.details.deep_stringify_keys
        rescue InvalidPayload => error
          status = "rejected"
          error_details = { "message" => error.message }
        end

        mutation = @trip.client_mutations.create!(
          actor: @actor,
          client_uuid: @client_uuid,
          mutation_type: @mutation_type,
          payload_hash: @payload_hash,
          payload: @payload,
          base_revision: @payload["base_revision"],
          status: status,
          result_record_type: record&.class&.name,
          result_record_id: record&.id,
          error_details: error_details
        )

        Result.new(status: status, mutation: mutation, record: record, error: error_details, conflict: status == "conflict")
      end
    end

    private

    class InvalidPayload < StandardError; end

    class StaleRevision < StandardError
      attr_reader :details

      def initialize(details)
        @details = details
        super("stale base revision")
      end
    end

    def existing_result(existing)
      if existing.duplicate_of_payload?(@payload_hash)
        Result.new(
          status: "duplicate",
          mutation: existing,
          record: existing.result_record,
          error: existing.error_details,
          conflict: existing.status == "conflict"
        )
      else
        Result.new(
          status: "rejected",
          mutation: existing,
          record: existing.result_record,
          error: { "message" => "client_uuid already used with different payload" },
          conflict: false
        )
      end
    end

    def process_mutation!
      case @mutation_type
      when "expense_create"
        create_expense!
      when "expense_update"
        update_expense!
      when "expense_void"
        void_expense!
      else
        raise InvalidPayload, "unsupported mutation type"
      end
    end

    def create_expense!
      expense_attributes = expense_payload
      payer_trip_person = trip_person!(expense_attributes.fetch("payer_trip_person_id"))

      expense = @trip.expenses.create!(
        amount: expense_attributes.fetch("amount"),
        description: expense_attributes.fetch("description"),
        category: expense_attributes.fetch("category", "other"),
        currency: expense_attributes.fetch("currency", "EUR"),
        expense_date: expense_attributes.fetch("expense_date", Date.current),
        payer: payer_trip_person.user,
        payer_trip_person: payer_trip_person,
        status: expense_attributes.fetch("status", "active"),
        client_uuid: expense_attributes["client_uuid"] || @client_uuid
      )

      apply_splits!(expense)
      record_event!("expense_created", expense)
      record_event!("mutation_synced", expense)
      expense
    end

    def update_expense!
      expense = expense!
      assert_current_revision!(expense)
      expense_attributes = expense_payload

      if expense_attributes["payer_trip_person_id"].present?
        payer_trip_person = trip_person!(expense_attributes["payer_trip_person_id"])
        expense.payer_trip_person = payer_trip_person
        expense.payer = payer_trip_person.user
      end

      expense.assign_attributes(expense_attributes.slice(
        "amount", "description", "category", "currency", "expense_date", "status"
      ))
      expense.save!
      apply_splits!(expense) if @payload.key?("splits")
      record_event!("expense_edited", expense)
      record_event!("mutation_synced", expense)
      expense
    end

    def void_expense!
      expense = expense!
      assert_current_revision!(expense)
      expense.update!(status: "voided")
      record_event!("expense_voided", expense)
      record_event!("mutation_synced", expense)
      expense
    end

    def expense_payload
      @payload.fetch("expense") { raise InvalidPayload, "expense payload is required" }
    end

    def expense!
      @trip.expenses.find(@payload.fetch("expense_id"))
    rescue KeyError
      raise InvalidPayload, "expense_id is required"
    end

    def trip_person!(id)
      @trip.trip_people.find(id)
    rescue ActiveRecord::RecordNotFound
      raise InvalidPayload, "trip person not found"
    end

    def assert_current_revision!(expense)
      base_revision = @payload.fetch("base_revision") { raise InvalidPayload, "base_revision is required" }.to_i
      return if expense.lock_version == base_revision

      raise StaleRevision, {
        message: "expense changed on server",
        server_revision: expense.lock_version,
        base_revision: base_revision,
        server_expense: serialize_expense(expense)
      }
    end

    def apply_splits!(expense)
      splits = Array(@payload["splits"])
      return if splits.empty?

      results = splits.map do |split|
        trip_person = trip_person!(split.fetch("trip_person_id"))
        SplitCalculator::Result.new(
          trip_person: trip_person,
          amount_owed: BigDecimal(split.fetch("amount_owed").to_s),
          split_method: split.fetch("split_method"),
          split_value: split["split_value"].present? ? BigDecimal(split["split_value"].to_s) : nil,
          split_metadata: split["split_metadata"] || {}
        )
      end

      expense.apply_split!(results)
      record_event!("split_changed", expense)
    end

    def record_event!(event_type, expense)
      @trip.expense_events.create!(
        expense: expense,
        actor: @actor,
        event_type: event_type,
        payload: {
          client_uuid: @client_uuid,
          mutation_type: @mutation_type,
          expense_id: expense.id,
          revision: expense.lock_version
        }
      )
    end

    def serialize_expense(expense)
      {
        id: expense.id,
        amount: expense.amount.to_s,
        description: expense.description,
        category: expense.category,
        currency: expense.currency,
        expense_date: expense.expense_date.to_s,
        status: expense.status,
        lock_version: expense.lock_version
      }
    end
  end
end
