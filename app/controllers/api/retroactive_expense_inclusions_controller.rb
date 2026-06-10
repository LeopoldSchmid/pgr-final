class Api::RetroactiveExpenseInclusionsController < Api::BaseController
  before_action :set_accessible_trip
  before_action :require_expense_management

  def preview
    render json: serialize(service.preview)
  end

  def apply
    render json: serialize(service.apply)
  end

  private

  def service
    @service ||= Expenses::RetroactiveInclude.new(
      trip: @trip,
      trip_person: @trip.trip_people.find(inclusion_params.fetch(:trip_person_id)),
      expense_ids: inclusion_params.fetch(:expense_ids),
      actor: Current.user
    )
  end

  def inclusion_params
    params.require(:retroactive_expense_inclusion).permit(:trip_person_id, expense_ids: [])
  end

  def serialize(result)
    {
      before_balances: serialize_balances(result.fetch(:before_balances)),
      after_balances: serialize_balances(result.fetch(:after_balances)),
      changes: result.fetch(:changes).map { |change|
        {
          expense_id: change.fetch(:expense).id,
          before: serialize_split_pairs(change.fetch(:before)),
          after: serialize_split_pairs(change.fetch(:after))
        }
      }
    }
  end

  def serialize_balances(balances)
    balances.map { |trip_person, amount| { trip_person_id: trip_person.id, amount: amount.to_s } }
  end

  def serialize_split_pairs(pairs)
    pairs.map { |trip_person, amount| { trip_person_id: trip_person.id, amount_owed: amount.to_s } }
  end
end
