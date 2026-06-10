module Expenses
  class Ledger
    def initialize(trip)
      @trip = trip
    end

    def total_expenses
      active_expenses.sum(:amount)
    end

    def expenses_by_category
      active_expenses.group(:category).sum(:amount)
    end

    def balance_for(trip_person)
      return 0.to_d unless trip_person&.trip_id == @trip.id

      paid = active_expenses.where(payer_trip_person: trip_person).sum(:amount)
      owed = ExpenseSplit.joins(:expense)
        .where(expenses: { trip_id: @trip.id, status: "active" }, trip_person: trip_person)
        .sum(:amount_owed)

      paid - owed
    end

    def balances
      @trip.trip_people.active_ledger_people.index_with { |trip_person| balance_for(trip_person) }
    end

    def settlement_suggestions
      creditors = balances.select { |_, balance| balance.positive? }.map { |person, balance| [ person, balance.to_d ] }
      debtors = balances.select { |_, balance| balance.negative? }.map { |person, balance| [ person, balance.abs.to_d ] }

      suggestions = []
      debtor_index = 0
      creditor_index = 0

      while debtor_index < debtors.length && creditor_index < creditors.length
        debtor, debt_amount = debtors[debtor_index]
        creditor, credit_amount = creditors[creditor_index]
        amount = [ debt_amount, credit_amount ].min

        suggestions << {
          from: debtor,
          to: creditor,
          amount: amount.round(2),
          currency: "EUR"
        }

        debtors[debtor_index][1] -= amount
        creditors[creditor_index][1] -= amount
        debtor_index += 1 if debtors[debtor_index][1].zero?
        creditor_index += 1 if creditors[creditor_index][1].zero?
      end

      suggestions
    end

    private

    def active_expenses
      @trip.expenses.where(status: "active")
    end
  end
end
