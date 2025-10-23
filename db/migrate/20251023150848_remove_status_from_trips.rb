class RemoveStatusFromTrips < ActiveRecord::Migration[8.1]
  def change
    remove_column :trips, :status, :string
  end
end
