module Shopping
  class RequirementSynchronizer
    Result = Struct.new(:sync_run, :created, :updated, :removed, :unchanged, :outdated, keyword_init: true)

    def initialize(trip:, user:)
      @trip = trip
      @user = user
      @builder = RequirementBuilder.new(trip)
    end

    def preview
      compare_sets
    end

    def mark_outdated!
      comparison = compare_sets
      comparison[:changed].each { |pair| pair[:existing].update!(sync_status: "outdated") }
      comparison[:removed].each { |requirement| requirement.update!(sync_status: "outdated") }
      comparison
    end

    def sync!
      comparison = compare_sets
      sync_run = ShoppingSyncRun.create!(
        trip: trip,
        user: user,
        started_at: Time.current,
        snapshot_payload: snapshot_payload(comparison),
        change_summary: change_summary(comparison)
      )

      created = comparison[:new].map { |entry| ShoppingRequirement.create!(entry.attributes.merge(synced_at: Time.current)) }
      updated = comparison[:changed].map { |pair| apply_update(pair[:existing], pair[:entry]) }
      removed = comparison[:removed].map { |requirement| apply_removal(requirement) }
      unchanged = comparison[:unchanged].map do |pair|
        pair[:existing].tap do |requirement|
          requirement.update!(sync_status: "in_sync", synced_at: Time.current)
        end
      end

      sync_run.update!(finished_at: Time.current)

      Result.new(
        sync_run: sync_run,
        created: created,
        updated: updated,
        removed: removed,
        unchanged: unchanged,
        outdated: []
      )
    end

    private

    attr_reader :trip, :user, :builder

    def compare_sets
      expected_entries = builder.call
      existing_requirements = trip.shopping_requirements.meal_plan_based.includes(:shopping_list_assignments)

      expected_by_key = expected_entries.index_by(&:matching_key)
      existing_by_key = existing_requirements.index_by { |requirement| matching_key_for_requirement(requirement) }

      unchanged = []
      changed = []
      new_entries = []
      removed = []

      expected_by_key.each do |key, entry|
        existing = existing_by_key[key]
        if existing.nil?
          new_entries << entry
        elsif existing.last_synced_signature == entry.attributes[:source_signature]
          unchanged << { existing: existing, entry: entry }
        else
          changed << { existing: existing, entry: entry }
        end
      end

      existing_by_key.each do |key, requirement|
        removed << requirement unless expected_by_key.key?(key)
      end

      {
        new: new_entries,
        changed: changed,
        removed: removed,
        unchanged: unchanged
      }
    end

    def matching_key_for_requirement(requirement)
      if requirement.food_item_id.present?
        [ requirement.meal_plan_id, "food_item", requirement.food_item_id, requirement.unit ].join(":")
      else
        [ requirement.meal_plan_id, "name", requirement.name.to_s.downcase, requirement.unit.to_s.downcase ].join(":")
      end
    end

    def apply_update(requirement, entry)
      requirement.update!(entry.attributes.merge(sync_status: "in_sync", synced_at: Time.current))
      requirement
    end

    def apply_removal(requirement)
      if requirement.shopping_list_assignments.exists? || requirement.purchased_quantity.positive?
        requirement.update!(sync_status: "detached")
        requirement
      else
        requirement.destroy!
      end
    end

    def snapshot_payload(comparison)
      relevant_requirements = comparison[:changed].map { |pair| pair[:existing] } + comparison[:removed] + comparison[:unchanged].map { |pair| pair[:existing] }
      relevant_requirements.uniq!

      {
        requirements: relevant_requirements.index_with do |requirement|
          requirement.attributes.slice(*snapshot_requirement_attributes)
        end,
        assignments: relevant_requirements.flat_map(&:shopping_list_assignments).index_with do |assignment|
          assignment.attributes.slice(*snapshot_assignment_attributes)
        end
      }
    end

    def snapshot_requirement_attributes
      %w[
        id trip_id food_item_id meal_plan_id recipe_id name quantity unit category
        source_type sync_status source_label source_signature last_synced_signature synced_at notes
        created_at updated_at
      ]
    end

    def snapshot_assignment_attributes
      %w[
        id shopping_requirement_id shopping_list_id planned_quantity purchased_quantity unit
        position notes created_at updated_at
      ]
    end

    def change_summary(comparison)
      [
        "created=#{comparison[:new].size}",
        "changed=#{comparison[:changed].size}",
        "removed=#{comparison[:removed].size}",
        "unchanged=#{comparison[:unchanged].size}"
      ].join(", ")
    end
  end
end
