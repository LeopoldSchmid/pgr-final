class CreateRecipes < ActiveRecord::Migration[8.0]
  def change
    create_table :recipes do |t|
      t.references :trip, null: false, foreign_key: true
      t.string :name
      t.integer :servings
      t.text :description

      t.timestamps
    end
  end
end
