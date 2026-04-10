class ShoppingRequirement < ApplicationRecord
  CATEGORIES = %w[produce dairy meat seafood pantry spices frozen other].freeze
  SOURCE_TYPES = %w[meal_plan manual template carry_over].freeze
  SYNC_STATUSES = %w[manual in_sync outdated manually_adjusted detached].freeze

  belongs_to :trip
  belongs_to :food_item, optional: true
  belongs_to :meal_plan, optional: true
  belongs_to :recipe, optional: true

  has_many :shopping_list_assignments, dependent: :destroy
  has_many :shopping_lists, through: :shopping_list_assignments

  validates :name, presence: true, length: { maximum: 100 }
  validates :quantity, presence: true, numericality: { greater_than: 0 }
  validates :unit, presence: true, length: { maximum: 20 }
  validates :category, presence: true, inclusion: { in: CATEGORIES }
  validates :source_type, presence: true, inclusion: { in: SOURCE_TYPES }
  validates :sync_status, presence: true, inclusion: { in: SYNC_STATUSES }

  before_validation :apply_default_sync_status

  scope :manual_only, -> { where(source_type: "manual") }
  scope :meal_plan_based, -> { where(source_type: "meal_plan") }
  scope :outdated, -> { where(sync_status: "outdated") }
  scope :ordered, -> { order(category: :asc, name: :asc, created_at: :asc) }

  def assigned_quantity
    shopping_list_assignments.sum(:planned_quantity).to_d
  end

  def purchased_quantity
    shopping_list_assignments.sum(:purchased_quantity).to_d
  end

  def unassigned_quantity
    remaining = quantity.to_d - assigned_quantity
    remaining.positive? ? remaining : 0.to_d
  end

  def over_assigned_quantity
    overflow = assigned_quantity - quantity.to_d
    overflow.positive? ? overflow : 0.to_d
  end

  def fully_assigned?
    unassigned_quantity.zero?
  end

  def in_sync?
    sync_status == "in_sync"
  end

  def outdated?
    sync_status == "outdated"
  end

  def manually_adjusted?
    sync_status == "manually_adjusted"
  end

  def detached?
    sync_status == "detached"
  end

  def manual?
    source_type == "manual"
  end

  def meal_plan_based?
    source_type == "meal_plan"
  end

  def mark_manually_adjusted!
    update!(sync_status: "manually_adjusted") unless manual?
  end

  private

  def apply_default_sync_status
    self.sync_status ||= source_type == "manual" ? "manual" : "in_sync"
  end
end
