require "digest"

class MealPlan < ApplicationRecord
  MEAL_TYPES = %w[breakfast lunch dinner snack miscellaneous drinks].freeze
  MEAL_TYPE_LABELS = {
    "breakfast" => "Breakfast",
    "lunch" => "Lunch",
    "dinner" => "Dinner",
    "snack" => "Snack",
    "miscellaneous" => "Miscellaneous",
    "drinks" => "Drinks"
  }.freeze
  MEAL_TYPE_ICONS = {
    "breakfast" => "🥐",
    "lunch" => "🍝",
    "dinner" => "🍕",
    "snack" => "🍟",
    "miscellaneous" => "🧩",
    "drinks" => "🍺"
  }.freeze
  DRIFT_STATUSES = %w[in_sync drifted resolved].freeze
  MEAL_TYPE_ORDER = {
    "breakfast" => 0,
    "lunch" => 1,
    "dinner" => 2,
    "snack" => 3,
    "miscellaneous" => 4,
    "drinks" => 5
  }.freeze

  belongs_to :trip
  belongs_to :recipe
  has_many :meal_plan_assignees, dependent: :destroy
  has_many :assignees, through: :meal_plan_assignees, source: :user
  has_many :shopping_requirements, dependent: :nullify

  validates :date, presence: true
  validates :meal_type, presence: true, inclusion: { in: MEAL_TYPES }
  validates :servings, presence: true, numericality: { greater_than: 0 }
  validates :drift_status, presence: true, inclusion: { in: DRIFT_STATUSES }

  before_validation :set_default_servings
  before_validation :set_default_drift_status
  before_validation :capture_recipe_snapshot_signature

  scope :ordered, -> {
    order(date: :asc)
      .order(
        Arel.sql(
          "CASE meal_type " \
          "WHEN 'breakfast' THEN 0 " \
          "WHEN 'lunch' THEN 1 " \
          "WHEN 'dinner' THEN 2 " \
          "WHEN 'snack' THEN 3 " \
          "WHEN 'miscellaneous' THEN 4 " \
          "WHEN 'drinks' THEN 5 " \
          "ELSE 99 END"
        )
      )
      .order(created_at: :asc)
  }
  scope :for_date, ->(date) { where(date: date) }

  def current_recipe_signature
    payload = current_recipe_payload
    return nil if payload.nil?

    Digest::SHA256.hexdigest(payload.to_json)
  end

  def current_recipe_payload
    return nil unless recipe

    {
      recipe_id: recipe.id,
      recipe_name: recipe.name,
      recipe_updated_at: recipe.updated_at,
      servings: servings.to_d,
      ingredients: recipe.ingredients.order(:id).pluck(:id, :name, :quantity, :unit, :updated_at)
    }
  end

  def drifted?
    return false if recipe_snapshot_signature.blank?

    current_recipe_signature != recipe_snapshot_signature
  end

  def refresh_drift_status!
    target_status = drifted? ? "drifted" : "in_sync"
    update!(drift_status: target_status) if drift_status != target_status
  end

  def drift_preview
    baseline = recipe_snapshot_payload.presence || {}
    baseline_ingredients = Array(baseline["ingredients"] || baseline[:ingredients])
    current_ingredients = Array(current_recipe_payload&.dig(:ingredients))

    baseline_map = baseline_ingredients.to_h { |row| [ row_key(row), row ] }
    current_map = current_ingredients.to_h { |row| [ row_key(row), row ] }

    added = current_map.keys - baseline_map.keys
    removed = baseline_map.keys - current_map.keys
    changed = (baseline_map.keys & current_map.keys).select { |key| baseline_map[key] != current_map[key] }

    {
      drifted: drifted?,
      added: added.map { |key| row_hash(current_map[key]) },
      removed: removed.map { |key| row_hash(baseline_map[key]) },
      changed: changed.map do |key|
        { before: row_hash(baseline_map[key]), after: row_hash(current_map[key]) }
      end
    }
  end

  def resolve_drift!(strategy:)
    update!(
      recipe_snapshot_payload: current_recipe_payload,
      recipe_snapshot_signature: current_recipe_signature,
      drift_status: "resolved"
    )

    shopping_requirements.where(source_type: "meal_plan").update_all(sync_status: "outdated") if strategy == "accept_new_recipe"
  end

  def ingredient_rows
    recipe&.ingredients&.order(:id) || []
  end

  def ingredients_missing?
    ingredient_rows.empty?
  end

  def meal_type_label
    self.class.meal_type_label_for(meal_type)
  end

  def self.meal_type_label_for(type)
    MEAL_TYPE_LABELS[type.to_s] || type.to_s.humanize
  end

  def self.meal_type_icon_for(type)
    MEAL_TYPE_ICONS[type.to_s] || "•"
  end

  private

  def set_default_servings
    return if servings.present?

    base_servings = recipe&.servings.to_d
    self.servings = base_servings.positive? ? base_servings : 1
  end

  def set_default_drift_status
    self.drift_status ||= "in_sync"
  end

  def capture_recipe_snapshot_signature
    return unless recipe_snapshot_signature.blank? || will_save_change_to_recipe_id?

    self.recipe_snapshot_payload = current_recipe_payload
    self.recipe_snapshot_signature = current_recipe_signature
  end

  def row_key(row)
    id, name, = row
    id.presence || name.to_s.downcase
  end

  def row_hash(row)
    {
      ingredient_id: row[0],
      name: row[1],
      quantity: row[2],
      unit: row[3]
    }
  end
end
