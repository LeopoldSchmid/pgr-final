module Shopping
  class AssignmentSplitter
    def initialize(requirement:)
      @requirement = requirement
    end

    def assign_to_list!(shopping_list:, quantity:, unit: nil)
      target_unit = unit.presence || requirement.unit
      planned_quantity = normalized_quantity(quantity, target_unit)

      raise ArgumentError, "Assigned quantity must be positive" unless planned_quantity.positive?
      raise ArgumentError, "Assigned quantity exceeds remaining requirement" if planned_quantity > requirement.unassigned_quantity

      assignment = requirement.shopping_list_assignments.find_or_initialize_by(shopping_list: shopping_list, unit: requirement.unit)
      assignment.planned_quantity = assignment.planned_quantity.to_d + planned_quantity
      assignment.unit = requirement.unit
      assignment.save!
      assignment
    end

    private

    attr_reader :requirement

    def normalized_quantity(quantity, target_unit)
      amount = BigDecimal(quantity.to_s)
      return amount if target_unit == requirement.unit
      return FoodItem.convert_quantity(amount, target_unit, requirement.unit).to_d if FoodItem.compatible_units?(target_unit, requirement.unit)

      raise ArgumentError, "Assigned unit is not compatible with the requirement unit"
    end
  end
end
