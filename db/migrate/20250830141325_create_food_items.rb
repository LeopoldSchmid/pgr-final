class CreateFoodItems < ActiveRecord::Migration[8.0]
  def change
    create_table :food_items do |t|
      t.string :name
      t.string :standard_unit
      t.string :category
      t.string :unit_type

      t.timestamps
    end
  end
end
