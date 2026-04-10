module Shopping
  class AssignmentAggregator
    AggregatedItem = Struct.new(
      :key,
      :name,
      :category,
      :unit,
      :planned_quantity,
      :purchased_quantity,
      :remaining_quantity,
      :source_labels,
      :assignments,
      :has_comments,
      keyword_init: true
    )

    def initialize(shopping_list)
      @shopping_list = shopping_list
    end

    def call
      grouped.values.sort_by { |item| [ item.category.to_s, item.name.to_s ] }
    end

    private

    attr_reader :shopping_list

    def grouped
      shopping_list.shopping_list_assignments.includes(:shopping_requirement, :shopping_item_comments).each_with_object({}) do |assignment, memo|
        key = aggregate_key_for(assignment)
        memo[key] ||= build_aggregate_item(key, assignment)
        merge_assignment!(memo[key], assignment)
      end
    end

    def aggregate_key_for(assignment)
      requirement = assignment.shopping_requirement
      if requirement.food_item_id.present?
        [ requirement.food_item_id, canonical_unit_for(assignment) ].join(":")
      else
        [ requirement.name.to_s.downcase, canonical_unit_for(assignment) ].join(":")
      end
    end

    def canonical_unit_for(assignment)
      requirement = assignment.shopping_requirement
      requirement.food_item&.standard_unit.presence || assignment.unit
    end

    def build_aggregate_item(key, assignment)
      requirement = assignment.shopping_requirement
      AggregatedItem.new(
        key: key,
        name: requirement.name,
        category: requirement.category,
        unit: canonical_unit_for(assignment),
        planned_quantity: 0.to_d,
        purchased_quantity: 0.to_d,
        remaining_quantity: 0.to_d,
        source_labels: [],
        assignments: [],
        has_comments: false
      )
    end

    def merge_assignment!(aggregate_item, assignment)
      quantity = normalize_assignment_quantity(assignment, aggregate_item.unit)
      purchased = normalize_assignment_purchased_quantity(assignment, aggregate_item.unit)

      aggregate_item.planned_quantity += quantity
      aggregate_item.purchased_quantity += purchased
      aggregate_item.remaining_quantity = aggregate_item.planned_quantity - aggregate_item.purchased_quantity
      aggregate_item.source_labels |= [ assignment.shopping_requirement.source_label ].compact
      aggregate_item.assignments << assignment
      aggregate_item.has_comments ||= assignment.shopping_item_comments.any?
    end

    def normalize_assignment_quantity(assignment, target_unit)
      return assignment.planned_quantity.to_d if assignment.unit == target_unit

      FoodItem.convert_quantity(assignment.planned_quantity.to_d, assignment.unit, target_unit).to_d
    end

    def normalize_assignment_purchased_quantity(assignment, target_unit)
      return assignment.purchased_quantity.to_d if assignment.unit == target_unit

      FoodItem.convert_quantity(assignment.purchased_quantity.to_d, assignment.unit, target_unit).to_d
    end
  end
end
