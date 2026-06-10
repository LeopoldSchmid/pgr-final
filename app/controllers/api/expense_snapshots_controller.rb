class Api::ExpenseSnapshotsController < Api::BaseController
  before_action :set_accessible_trip

  def show
    ledger = @trip.expense_ledger

    render json: {
      trip: {
        id: @trip.id,
        name: @trip.name
      },
      trip_people: @trip.trip_people.order(:display_name).map { |person| serialize_trip_person(person) },
      split_groups: @trip.split_groups.includes(:trip_people).order(:name).map { |group| serialize_split_group(group) },
      expenses: @trip.expenses.includes(:payer_trip_person, :expense_splits).order(expense_date: :desc, created_at: :desc).map { |expense| serialize_expense(expense) },
      balances: ledger.balances.map { |person, amount| { trip_person_id: person.id, amount: amount.to_s } },
      settlement_suggestions: ledger.settlement_suggestions.map { |suggestion|
        {
          from_trip_person_id: suggestion[:from].id,
          to_trip_person_id: suggestion[:to].id,
          amount: suggestion[:amount].to_s,
          currency: suggestion[:currency]
        }
      }
    }
  end

  private

  def serialize_trip_person(person)
    {
      id: person.id,
      display_name: person.display_name,
      email: person.email,
      status: person.status,
      user_id: person.user_id
    }
  end

  def serialize_split_group(group)
    {
      id: group.id,
      name: group.name,
      kind: group.kind,
      trip_person_ids: group.dynamic_trip_people.map(&:id)
    }
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
      lock_version: expense.lock_version,
      payer_trip_person_id: expense.payer_trip_person_id,
      splits: expense.expense_splits.map { |split|
        {
          trip_person_id: split.trip_person_id,
          amount_owed: split.amount_owed.to_s,
          split_method: split.split_method,
          split_value: split.split_value&.to_s,
          split_metadata: split.split_metadata || {}
        }
      }
    }
  end
end
