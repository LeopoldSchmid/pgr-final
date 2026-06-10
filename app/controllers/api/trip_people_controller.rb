class Api::TripPeopleController < Api::BaseController
  before_action :set_accessible_trip
  before_action :require_expense_management, except: :index
  before_action :set_trip_person, only: [ :update, :link_user, :merge ]

  def index
    render json: @trip.trip_people.order(:display_name).map { |person| serialize(person) }
  end

  def create
    trip_person = @trip.trip_people.create!(trip_person_params)
    render json: serialize(trip_person), status: :created
  end

  def update
    @trip_person.update!(trip_person_params)
    render json: serialize(@trip_person)
  end

  def link_user
    user = User.find(link_user_params.fetch(:user_id))
    @trip_person.link_user!(user)
    @trip.expense_events.create!(
      actor: Current.user,
      event_type: "trip_person_linked",
      payload: { trip_person_id: @trip_person.id, user_id: user.id }
    )
    render json: serialize(@trip_person)
  end

  def merge
    target = @trip.trip_people.find(merge_params.fetch(:target_trip_person_id))
    Expenses::TripPersonMerge.new(trip: @trip, source: @trip_person, target: target, actor: Current.user).call
    render json: serialize(target)
  end

  private

  def set_trip_person
    @trip_person = @trip.trip_people.find(params[:id])
  end

  def trip_person_params
    params.require(:trip_person).permit(:display_name, :email, :status)
  end

  def link_user_params
    params.require(:trip_person).permit(:user_id)
  end

  def merge_params
    params.require(:trip_person).permit(:target_trip_person_id)
  end

  def serialize(person)
    {
      id: person.id,
      display_name: person.display_name,
      email: person.email,
      status: person.status,
      user_id: person.user_id
    }
  end
end
