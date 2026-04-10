class AddPurchasedQuantityToShoppingItems < ActiveRecord::Migration[8.1]
  def up
    add_column :shopping_items, :purchased_quantity, :decimal, precision: 10, scale: 2, default: 0.0, null: false

    execute <<~SQL.squish
      UPDATE shopping_items
      SET purchased_quantity = CASE
        WHEN purchased = TRUE AND quantity IS NOT NULL THEN quantity
        ELSE 0
      END
    SQL
  end

  def down
    remove_column :shopping_items, :purchased_quantity
  end
end
