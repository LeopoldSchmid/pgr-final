module Expenses
  class RetroactiveInclude
    def initialize(trip:, trip_person:, expense_ids:, actor:)
      @trip = trip
      @trip_person = trip_person
      @expense_ids = Array(expense_ids)
      @actor = actor
    end

    def preview
      ensure_trip_person!

      before_balances = ledger.balances
      after_balances = before_balances.transform_values(&:to_d)
      changes = expenses.map do |expense|
        current_people = expense.expense_splits.map(&:trip_person)
        next if current_people.include?(@trip_person)
        next if current_people.empty?

        new_people = current_people + [ @trip_person ]
        new_splits = SplitCalculator.equal(amount: expense.amount, trip_people: new_people)

        expense.expense_splits.each do |split|
          after_balances[split.trip_person] += split.amount_owed
        end

        new_splits.each do |split|
          after_balances[split.trip_person] ||= 0.to_d
          after_balances[split.trip_person] -= split.amount_owed
        end

        {
          expense: expense,
          before: expense.expense_splits.map { |split| [ split.trip_person, split.amount_owed ] },
          after: new_splits.map { |split| [ split.trip_person, split.amount_owed ] }
        }
      end.compact

      {
        before_balances: before_balances,
        after_balances: after_balances,
        changes: changes
      }
    end

    def apply
      result = preview

      Expense.transaction do
        result[:changes].each do |change|
          expense = change.fetch(:expense)
          new_results = change.fetch(:after).map do |trip_person, amount|
            SplitCalculator::Result.new(
              trip_person: trip_person,
              amount_owed: amount,
              split_method: "equal",
              split_value: 1.to_d,
              split_metadata: { retroactive_include: true }
            )
          end

          expense.apply_split!(new_results)
          @trip.expense_events.create!(
            expense: expense,
            actor: @actor,
            event_type: "retroactive_include_applied",
            payload: {
              added_trip_person_id: @trip_person.id,
              expense_id: expense.id
            }
          )
        end
      end

      result
    end

    private

    def ledger
      @ledger ||= Ledger.new(@trip)
    end

    def expenses
      @expenses ||= @trip.expenses.where(id: @expense_ids, status: "active").includes(:expense_splits)
    end

    def ensure_trip_person!
      raise ArgumentError, "trip person must belong to trip" unless @trip_person.trip_id == @trip.id
    end
  end
end
