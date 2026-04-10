class CreateShoppingRequirements < ActiveRecord::Migration[8.1]
  def change
    create_table :shopping_requirements do |t|
      t.references :trip, null: false, foreign_key: true
      t.references :food_item, null: true, foreign_key: true
      t.references :meal_plan, null: true, foreign_key: true
      t.references :recipe, null: true, foreign_key: true
      t.string :name, null: false
      t.decimal :quantity, precision: 10, scale: 2, null: false
      t.string :unit, null: false
      t.string :category, null: false
      t.string :source_type, null: false
      t.string :sync_status, null: false
      t.string :source_label
      t.string :source_signature
      t.string :last_synced_signature
      t.datetime :synced_at
      t.text :notes
      t.timestamps
    end

    add_index :shopping_requirements, :source_type
    add_index :shopping_requirements, :sync_status
    add_index :shopping_requirements, [:trip_id, :meal_plan_id]
  end
end
