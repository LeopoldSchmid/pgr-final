class FoodItem < ApplicationRecord
  has_many :ingredients
  has_many :shopping_requirements

  validates :name, presence: true, uniqueness: { case_sensitive: false }
  validates :standard_unit, presence: true
  validates :category, inclusion: { in: %w[produce dairy meat seafood pantry spices frozen other] }
  validates :unit_type, inclusion: { in: %w[weight volume count] }

  scope :by_category, ->(category) { where(category: category) }
  scope :by_unit_type, ->(type) { where(unit_type: type) }
  scope :search, lambda { |term|
    normalized = normalize_search_term(term)
    return none if normalized.blank?

    patterns = [ normalized, singularize_search_term(normalized) ].compact.uniq.flat_map do |value|
      [ "%#{value}%", "#{value}%" ]
    end.uniq

    where(
      patterns.map { "LOWER(name) LIKE ?" }.join(" OR "),
      *patterns
    ).order(Arel.sql("LENGTH(name) ASC"), :name)
  }

  def category_emoji
    case category
    when "produce" then "🥕"
    when "dairy" then "🥛"
    when "meat" then "🥩"
    when "seafood" then "🐟"
    when "pantry" then "🏪"
    when "spices" then "🧄"
    when "frozen" then "🧊"
    else "📦"
    end
  end

  def unit_suggestions
    case unit_type
    when "weight"
      [ "g", "kg" ]
    when "volume"
      [ "ml", "l" ]
    when "count"
      [ "pieces", "pcs", "items" ]
    else
      [ standard_unit ]
    end
  end

  def self.convert_quantity(from_quantity, from_unit, to_unit)
    return from_quantity if from_unit == to_unit

    # Weight conversions
    if from_unit == "kg" && to_unit == "g"
      return from_quantity * 1000
    elsif from_unit == "g" && to_unit == "kg"
      return from_quantity / 1000.0
    end

    # Volume conversions
    if from_unit == "l" && to_unit == "ml"
      return from_quantity * 1000
    elsif from_unit == "ml" && to_unit == "l"
      return from_quantity / 1000.0
    end

    # Count conversions (normalize different count units)
    count_units = [ "pieces", "pcs", "items", "count" ]
    if count_units.include?(from_unit) && count_units.include?(to_unit)
      return from_quantity
    end

    # No conversion possible
    from_quantity
  end

  def self.compatible_units?(unit1, unit2)
    weight_units = [ "g", "kg" ]
    volume_units = [ "ml", "l" ]
    count_units = [ "pieces", "pcs", "items", "count" ]

    (weight_units.include?(unit1) && weight_units.include?(unit2)) ||
    (volume_units.include?(unit1) && volume_units.include?(unit2)) ||
    (count_units.include?(unit1) && count_units.include?(unit2))
  end

  def self.normalize_search_term(term)
    term.to_s.strip.downcase
  end

  def self.singularize_search_term(term)
    return nil if term.blank? || !term.end_with?("s")

    term.delete_suffix("s")
  end
end
