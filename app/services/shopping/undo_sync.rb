module Shopping
  class UndoSync
    def initialize(sync_run)
      @sync_run = sync_run
    end

    def call
      payload = sync_run.snapshot_payload || {}

      restore_requirements!(payload.fetch("requirements", payload[:requirements] || {}))
      restore_assignments!(payload.fetch("assignments", payload[:assignments] || {}))
    end

    private

    attr_reader :sync_run

    def restore_requirements!(requirements_payload)
      requirements_payload.each_value do |attributes|
        requirement = ShoppingRequirement.find_or_initialize_by(id: attributes["id"] || attributes[:id])
        requirement.assign_attributes(normalize_attributes(attributes))
        requirement.save!(validate: false)
      end
    end

    def restore_assignments!(assignments_payload)
      assignments_payload.each_value do |attributes|
        assignment = ShoppingListAssignment.find_or_initialize_by(id: attributes["id"] || attributes[:id])
        assignment.assign_attributes(normalize_attributes(attributes))
        assignment.save!(validate: false)
      end
    end

    def normalize_attributes(attributes)
      attributes.transform_keys(&:to_sym).except(:id)
    end
  end
end
