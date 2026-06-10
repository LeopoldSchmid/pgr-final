class Api::ExpenseClientMutationsController < Api::BaseController
  before_action :set_accessible_trip

  def create
    result = Expenses::ClientMutationProcessor.new(
      trip: @trip,
      actor: Current.user,
      client_uuid: mutation_params.fetch(:client_uuid),
      mutation_type: mutation_params.fetch(:mutation_type),
      payload: mutation_params.fetch(:payload).to_unsafe_h,
      payload_hash: mutation_params[:payload_hash]
    ).call

    render json: serialize_result(result), status: response_status(result.status)
  rescue ActionController::ParameterMissing => error
    render json: { error: error.message }, status: :unprocessable_entity
  end

  private

  def mutation_params
    params.require(:client_mutation).permit(:client_uuid, :mutation_type, :payload_hash, payload: {})
  end

  def serialize_result(result)
    {
      status: result.status,
      mutation: {
        id: result.mutation.id,
        client_uuid: result.mutation.client_uuid,
        mutation_type: result.mutation.mutation_type,
        status: result.mutation.status,
        result_record_type: result.mutation.result_record_type,
        result_record_id: result.mutation.result_record_id,
        error_details: result.mutation.error_details
      },
      record: result.record && {
        id: result.record.id,
        type: result.record.class.name,
        lock_version: result.record.respond_to?(:lock_version) ? result.record.lock_version : nil
      },
      error: result.error,
      conflict: result.conflict
    }
  end

  def response_status(status)
    case status
    when "accepted", "duplicate"
      :ok
    when "conflict"
      :conflict
    else
      :unprocessable_entity
    end
  end
end
