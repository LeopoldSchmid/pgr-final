class ClientMutation < ApplicationRecord
  STATUSES = %w[accepted duplicate rejected conflict].freeze
  MUTATION_TYPES = %w[expense_create expense_update expense_void].freeze

  belongs_to :trip
  belongs_to :actor, class_name: "User"
  belongs_to :result_record, polymorphic: true, optional: true

  validates :client_uuid, presence: true, uniqueness: { scope: :trip_id }
  validates :mutation_type, inclusion: { in: MUTATION_TYPES }
  validates :payload_hash, presence: true
  validates :status, inclusion: { in: STATUSES }

  def duplicate_of_payload?(candidate_hash)
    payload_hash == candidate_hash
  end

  def result_record
    return nil if result_record_type.blank? || result_record_id.blank?

    result_record_type.constantize.find_by(id: result_record_id)
  end
end
