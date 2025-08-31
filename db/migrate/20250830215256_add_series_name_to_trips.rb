class AddSeriesNameToTrips < ActiveRecord::Migration[8.0]
  def change
    add_column :trips, :series_name, :string
  end
end
