class IncreaseCoordinatePrecision < ActiveRecord::Migration[8.0]
  def change
    # Increase precision from (10,6) to (12,8) for ~1cm GPS accuracy
    change_column :journal_entries, :latitude, :decimal, precision: 12, scale: 8
    change_column :journal_entries, :longitude, :decimal, precision: 12, scale: 8
  end
end
