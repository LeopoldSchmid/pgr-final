class CreateIngredients < ActiveRecord::Migration[8.0]
  def change
    create_table :ingredients do |t|
      t.references :recipe, null: false, foreign_key: true
      t.string :name
      t.decimal :quantity
      t.string :unit
      t.string :category

      t.timestamps
    end
  end
end
