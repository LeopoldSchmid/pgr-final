class CreateExpenseLedgerFoundation < ActiveRecord::Migration[8.1]
  def change
    create_table :trip_people do |t|
      t.references :trip, null: false, foreign_key: true
      t.references :user, foreign_key: true
      t.string :display_name, null: false
      t.string :email
      t.string :status, null: false, default: "active"
      t.json :metadata
      t.timestamps

      t.index [ :trip_id, :user_id ], unique: true, where: "user_id IS NOT NULL"
      t.index [ :trip_id, :email ], where: "email IS NOT NULL"
      t.index [ :trip_id, :status ]
    end

    create_table :split_groups do |t|
      t.references :trip, null: false, foreign_key: true
      t.string :name, null: false
      t.string :kind, null: false, default: "custom"
      t.timestamps

      t.index [ :trip_id, :name ], unique: true
      t.index [ :trip_id, :kind ]
    end

    create_table :split_group_memberships do |t|
      t.references :split_group, null: false, foreign_key: true
      t.references :trip_person, null: false, foreign_key: true
      t.timestamps

      t.index [ :split_group_id, :trip_person_id ], unique: true, name: "index_split_group_memberships_uniqueness"
    end

    change_table :expenses do |t|
      t.references :payer_trip_person, foreign_key: { to_table: :trip_people }
      t.string :client_uuid
      t.string :status, null: false, default: "active"
      t.integer :lock_version, null: false, default: 0
    end

    add_index :expenses, [ :trip_id, :client_uuid ], unique: true, where: "client_uuid IS NOT NULL"
    add_index :expenses, :status

    create_table :expense_splits do |t|
      t.references :expense, null: false, foreign_key: true
      t.references :trip_person, null: false, foreign_key: true
      t.decimal :amount_owed, precision: 10, scale: 2, null: false
      t.string :split_method, null: false
      t.decimal :split_value, precision: 12, scale: 4
      t.json :split_metadata
      t.timestamps

      t.index [ :expense_id, :trip_person_id ], unique: true
      t.index :split_method
    end

    create_table :expense_events do |t|
      t.references :trip, null: false, foreign_key: true
      t.references :expense, foreign_key: true
      t.references :actor, foreign_key: { to_table: :users }
      t.string :event_type, null: false
      t.json :payload
      t.timestamps

      t.index [ :trip_id, :event_type ]
      t.index :created_at
    end

    create_table :client_mutations do |t|
      t.references :trip, null: false, foreign_key: true
      t.references :actor, null: false, foreign_key: { to_table: :users }
      t.string :client_uuid, null: false
      t.string :mutation_type, null: false
      t.string :payload_hash, null: false
      t.json :payload
      t.integer :base_revision
      t.string :status, null: false, default: "accepted"
      t.string :result_record_type
      t.integer :result_record_id
      t.json :error_details
      t.timestamps

      t.index [ :trip_id, :client_uuid ], unique: true
      t.index [ :result_record_type, :result_record_id ]
      t.index :status
    end
  end
end
