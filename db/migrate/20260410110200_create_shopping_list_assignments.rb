class CreateShoppingListAssignments < ActiveRecord::Migration[8.1]
  def change
    create_table :shopping_list_assignments do |t|
      t.references :shopping_requirement, null: false, foreign_key: true
      t.references :shopping_list, null: false, foreign_key: true
      t.decimal :planned_quantity, precision: 10, scale: 2, null: false
      t.decimal :purchased_quantity, precision: 10, scale: 2, null: false, default: 0.0
      t.string :unit, null: false
      t.integer :position
      t.text :notes
      t.timestamps
    end

    add_index :shopping_list_assignments, [:shopping_requirement_id, :shopping_list_id], name: "index_shopping_assignments_requirement_and_list"
  end
end
