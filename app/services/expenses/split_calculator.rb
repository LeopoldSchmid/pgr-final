module Expenses
  class SplitCalculator
    Result = Data.define(:trip_person, :amount_owed, :split_method, :split_value, :split_metadata)

    class InvalidSplit < StandardError; end

    def self.equal(amount:, trip_people:)
      new(amount: amount).equal(trip_people)
    end

    def self.exact(amount:, allocations:)
      new(amount: amount).exact(allocations)
    end

    def self.shares(amount:, weights:)
      new(amount: amount).shares(weights)
    end

    def self.percentages(amount:, percentages:)
      new(amount: amount).percentages(percentages)
    end

    def initialize(amount:)
      @amount_cents = cents(amount)
    end

    def equal(trip_people)
      people = Array(trip_people)
      raise InvalidSplit, "at least one trip person is required" if people.empty?

      allocations = allocate_by_weights(people.index_with { 1.to_d })
      build_results(allocations, "equal") { 1.to_d }
    end

    def exact(allocations)
      normalized = normalize_people_hash(allocations)
      raise InvalidSplit, "at least one exact amount is required" if normalized.empty?

      cents_by_person = normalized.transform_values { |amount| cents(amount) }
      if cents_by_person.values.sum != @amount_cents
        raise InvalidSplit, "exact split amounts must equal the expense amount"
      end

      build_results(cents_by_person, "exact") { |trip_person| cents_by_person.fetch(trip_person) / 100.to_d }
    end

    def shares(weights)
      normalized = normalize_people_hash(weights).select { |_, weight| weight.to_d.positive? }
      raise InvalidSplit, "at least one positive share is required" if normalized.empty?

      allocations = allocate_by_weights(normalized)
      build_results(allocations, "shares") { |trip_person| normalized.fetch(trip_person).to_d }
    end

    def percentages(percentages)
      normalized = normalize_people_hash(percentages).select { |_, percentage| percentage.to_d.positive? }
      raise InvalidSplit, "at least one positive percentage is required" if normalized.empty?

      total_percentage = normalized.values.sum { |percentage| percentage.to_d }
      unless (total_percentage - 100.to_d).abs <= 0.0001.to_d
        raise InvalidSplit, "percentages must total 100"
      end

      allocations = allocate_by_weights(normalized)
      build_results(allocations, "percentage") { |trip_person| normalized.fetch(trip_person).to_d }
    end

    private

    def cents(amount)
      (BigDecimal(amount.to_s) * 100).round(0).to_i
    end

    def money(cents)
      cents / 100.to_d
    end

    def normalize_people_hash(hash)
      hash.to_h.transform_values { |value| BigDecimal(value.to_s) }
    end

    def allocate_by_weights(weights_by_person)
      total_weight = weights_by_person.values.sum(&:to_d)
      raise InvalidSplit, "total weight must be positive" unless total_weight.positive?

      raw = weights_by_person.map do |trip_person, weight|
        exact_cents = @amount_cents * weight.to_d / total_weight
        floor_cents = exact_cents.floor
        [ trip_person, floor_cents, exact_cents - floor_cents ]
      end

      remainder = @amount_cents - raw.sum { |_, floor_cents, _| floor_cents }
      raw
        .sort_by.with_index { |(_, _, fraction), index| [ -fraction, index ] }
        .first(remainder)
        .each { |entry| entry[1] += 1 }

      raw.to_h { |trip_person, cents, _| [ trip_person, cents ] }
    end

    def build_results(cents_by_person, method)
      cents_by_person.map do |trip_person, owed_cents|
        split_value = yield(trip_person)
        Result.new(
          trip_person: trip_person,
          amount_owed: money(owed_cents),
          split_method: method,
          split_value: split_value,
          split_metadata: {}
        )
      end
    end
  end
end
