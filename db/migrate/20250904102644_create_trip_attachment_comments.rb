class CreateTripAttachmentComments < ActiveRecord::Migration[8.0]
  def change
    create_table :trip_attachment_comments do |t|
      t.references :user, null: false, foreign_key: true
      t.references :trip_attachment, null: false, foreign_key: true
      t.text :content

      t.timestamps
    end
  end
end
