class ConvertTripAttachmentsToMultipleFiles < ActiveRecord::Migration[8.0]
  def up
    # Convert existing single file attachments to multiple files format
    ActiveStorage::Attachment.where(name: 'file', record_type: 'TripAttachment').find_each do |attachment|
      # Create a new attachment with 'files' name using the same blob
      ActiveStorage::Attachment.create!(
        name: 'files',
        record_type: attachment.record_type,
        record_id: attachment.record_id,
        blob_id: attachment.blob_id,
        created_at: attachment.created_at
      )
      
      # Remove the old 'file' attachment
      attachment.destroy
    end
  end

  def down
    # Convert back to single file format (for rollback)
    ActiveStorage::Attachment.where(name: 'files', record_type: 'TripAttachment').find_each do |attachment|
      # Only convert the first file back to single file format
      if ActiveStorage::Attachment.where(name: 'files', record_type: attachment.record_type, record_id: attachment.record_id).count == 1 ||
         ActiveStorage::Attachment.where(name: 'files', record_type: attachment.record_type, record_id: attachment.record_id).first == attachment
        
        ActiveStorage::Attachment.create!(
          name: 'file',
          record_type: attachment.record_type,
          record_id: attachment.record_id,
          blob_id: attachment.blob_id,
          created_at: attachment.created_at
        )
      end
      
      # Remove the 'files' attachment
      attachment.destroy
    end
  end
end
