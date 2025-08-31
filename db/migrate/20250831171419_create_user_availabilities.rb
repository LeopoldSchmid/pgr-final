class CreateUserAvailabilities < ActiveRecord::Migration[8.0]
  def change
    create_table :user_availabilities do |t|
      t.references :user, null: false, foreign_key: true
      t.date :start_date
      t.date :end_date
      t.string :availability_type
      t.string :title
      t.text :description
      t.boolean :recurring

      t.timestamps
    end
  end
end
