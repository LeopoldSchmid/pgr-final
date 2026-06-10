class AllowExpensesWithoutLegacyPayer < ActiveRecord::Migration[8.1]
  def change
    change_column_null :expenses, :payer_id, true
  end
end
