class Api::SplitGroupsController < Api::BaseController
  before_action :set_accessible_trip
  before_action :require_expense_management, except: :index
  before_action :set_split_group, only: [ :update, :destroy ]

  def index
    render json: @trip.split_groups.order(:name).map { |group| serialize(group) }
  end

  def create
    group = @trip.split_groups.create!(split_group_params.except(:trip_person_ids))
    sync_memberships(group, split_group_params[:trip_person_ids])
    render json: serialize(group), status: :created
  end

  def update
    @split_group.update!(split_group_params.except(:trip_person_ids))
    sync_memberships(@split_group, split_group_params[:trip_person_ids]) if split_group_params.key?(:trip_person_ids)
    render json: serialize(@split_group)
  end

  def destroy
    @split_group.destroy!
    head :no_content
  end

  private

  def set_split_group
    @split_group = @trip.split_groups.find(params[:id])
  end

  def split_group_params
    params.require(:split_group).permit(:name, :kind, trip_person_ids: [])
  end

  def sync_memberships(group, trip_person_ids)
    return if group.kind == "everyone"

    ids = Array(trip_person_ids).reject(&:blank?).map(&:to_i)
    people = @trip.trip_people.where(id: ids)
    group.trip_people = people
  end

  def serialize(group)
    {
      id: group.id,
      name: group.name,
      kind: group.kind,
      trip_person_ids: group.dynamic_trip_people.map(&:id)
    }
  end
end
