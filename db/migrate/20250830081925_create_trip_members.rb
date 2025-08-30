class CreateTripMembers < ActiveRecord::Migration[8.0]
  def change
    create_table :trip_members do |t|
      t.references :trip, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true
      t.string :role, null: false, default: 'member'
      t.datetime :joined_at, null: false

      t.timestamps
    end
    
    add_index :trip_members, [:trip_id, :user_id], unique: true
    add_index :trip_members, :role
  end
end
