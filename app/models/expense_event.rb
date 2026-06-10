class ExpenseEvent < ApplicationRecord
  EVENT_TYPES = %w[
    expense_created
    expense_edited
    expense_voided
    split_changed
    payer_changed
    mutation_synced
    mutation_failed
    trip_person_linked
    trip_person_merged
    retroactive_include_applied
  ].freeze

  belongs_to :trip
  belongs_to :expense, optional: true
  belongs_to :actor, class_name: "User", optional: true

  validates :event_type, inclusion: { in: EVENT_TYPES }
end
