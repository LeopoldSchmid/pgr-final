module Expenses
  class TripPersonMerge
    def initialize(trip:, source:, target:, actor:)
      @trip = trip
      @source = source
      @target = target
      @actor = actor
    end

    def call
      raise ArgumentError, "source and target must be different" if @source == @target
      raise ArgumentError, "source must belong to trip" unless @source.trip_id == @trip.id
      raise ArgumentError, "target must belong to trip" unless @target.trip_id == @trip.id

      TripPerson.transaction do
        @source.paid_expenses.update_all(payer_trip_person_id: @target.id)
        merge_splits!
        merge_group_memberships!
        @source.update!(status: "archived")
        record_event!
      end

      @target
    end

    private

    def merge_splits!
      @source.expense_splits.find_each do |source_split|
        target_split = source_split.expense.expense_splits.find_by(trip_person: @target)

        if target_split
          target_split.update!(amount_owed: target_split.amount_owed + source_split.amount_owed)
          source_split.destroy!
        else
          source_split.update!(trip_person: @target)
        end
      end
    end

    def merge_group_memberships!
      @source.split_group_memberships.find_each do |membership|
        if membership.split_group.split_group_memberships.exists?(trip_person: @target)
          membership.destroy!
        else
          membership.update!(trip_person: @target)
        end
      end
    end

    def record_event!
      @trip.expense_events.create!(
        actor: @actor,
        event_type: "trip_person_merged",
        payload: {
          source_trip_person_id: @source.id,
          target_trip_person_id: @target.id
        }
      )
    end
  end
end
