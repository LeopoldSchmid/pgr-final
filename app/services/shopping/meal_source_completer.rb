module Shopping
  class MealSourceCompleter
    Result = Struct.new(:completed_assignments, :created_assignments, keyword_init: true)

    def initialize(trip:, meal_plan:)
      @trip = trip
      @meal_plan = meal_plan
    end

    def call
      created_assignments = []
      completed_assignments = []

      meal_requirements.find_each do |requirement|
        if requirement.unassigned_quantity.positive?
          assignment = AssignmentSplitter.new(requirement: requirement).assign_to_list!(
            shopping_list: default_shopping_list,
            quantity: requirement.unassigned_quantity,
            unit: requirement.unit
          )
          created_assignments << assignment
        end

        requirement.shopping_list_assignments.each do |assignment|
          next if assignment.remaining_quantity.zero? && assignment.completion_source == "brought_by_meal_source"

          assignment.mark_complete!(source: "brought_by_meal_source")
          completed_assignments << assignment
        end
      end

      Result.new(completed_assignments: completed_assignments, created_assignments: created_assignments)
    end

    private

    attr_reader :trip, :meal_plan

    def meal_requirements
      trip.shopping_requirements.where(meal_plan_id: meal_plan.id)
    end

    def default_shopping_list
      @default_shopping_list ||= trip.shopping_lists.where(archived_at: nil).order(:position, :created_at).first ||
        trip.shopping_lists.create!(name: "Trip Shopping List", status: "draft")
    end
  end
end
